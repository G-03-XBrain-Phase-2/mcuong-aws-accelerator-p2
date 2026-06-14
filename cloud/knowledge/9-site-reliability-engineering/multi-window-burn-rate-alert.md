# Cảnh Báo Multi-Window Multi-Burn-Rate: Tối Ưu Hóa Hệ Thống Alert Với Prometheus

Trong giám sát hệ thống theo phương pháp luận SLO, việc thiết lập cảnh báo (alerting) đóng vai trò quyết định. Nếu cảnh báo quá nhạy, kỹ sư sẽ bị ngập trong "tiếng ồn cảnh báo" (alert fatigue)[5]. Ngược lại, nếu cảnh báo quá trễ, hệ thống có thể sập hàng giờ mà không ai hay biết. 

Giải pháp tối ưu cho vấn đề này là cơ chế cảnh báo **Multi-window Multi-burn-rate** (Cảnh báo tốc độ tiêu hao ngân sách lỗi trên nhiều khung thời gian) được thiết lập trong Prometheus.

---

## 1. Khái Niệm Burn Rate và Error Budget

*   **Error Budget (Ngân sách lỗi):** Là lượng lỗi tối đa hệ thống được phép gặp trong một chu kỳ (thường là 30 ngày) mà không làm ảnh hưởng đến trải nghiệm chung của người dùng.
*   **Burn Rate (Tốc độ tiêu hao):** Chỉ số đo lường tốc độ hệ thống đang ngốn hết ngân sách lỗi của mình[3][6].
    *   **Burn Rate = 1:** Hệ thống đang tiêu hao ngân sách lỗi với tốc độ đều đặn, vừa khít để hết sạch ngân sách vào ngày thứ 30[3][6]. Đây là tốc độ lý tưởng (chấp nhận được).
    *   **Burn Rate = 2:** Hệ thống tiêu thụ ngân sách nhanh gấp đôi, sẽ hết sạch ngân sách lỗi sau 15 ngày.
    *   **Burn Rate = 14.4:** Chỉ cần duy trì tốc độ lỗi này trong **1 giờ**, bạn sẽ ngốn sạch **2%** toàn bộ ngân sách lỗi của cả tháng.

### Bảng quy đổi thời gian cạn kiệt ngân sách lỗi theo Burn Rate (Mục tiêu SLO 99.9%):

| Burn Rate | Thời gian tiêu hết 100% ngân sách lỗi | Trạng thái ứng phó |
| :--- | :--- | :--- |
| **1x** | 30 ngày (720 giờ) | Bình thường, tạo Ticket xử lý trong giờ hành chính |
| **2x** | 15 ngày (360 giờ) | Cần lưu ý |
| **6x** | 5 ngày (120 giờ) | Cần kiểm tra trong ngày |
| **14.4x** | 50 giờ (2.1 ngày) | **Khẩn cấp (Page)** - Đánh còi báo thức kỹ sư trực |
| **14.4x trong 1h** | Tiêu hết 2% ngân sách | **Khẩn cấp (Page)** - Lỗi cực nặng diện rộng |

---

## 2. Tại Sao Cần Cơ Chế Multi-Window Multi-Burn-Rate?

Trước khi có cơ chế này, các kỹ sư thường dùng 2 cách cảnh báo đơn giản nhưng đều gặp nhược điểm chí mạng:

1.  **Chỉ cảnh báo theo khung thời gian ngắn (ví dụ: lỗi > 2% trong 5 phút):**
    *   *Ưu điểm:* Phát hiện sự cố cực nhanh.
    *   *Nhược điểm:* Quá nhiều báo động giả (false alarm) do các xung đột mạng tạm thời (transient spikes) tự phục hồi sau 1-2 phút. Kỹ sư sẽ bị chai lỳ cảm giác cảnh báo (alert fatigue)[5].
2.  **Chỉ cảnh báo theo khung thời gian dài (ví dụ: lỗi > 0.1% trong 36 giờ):**
    *   *Ưu điểm:* Rất chính xác, chỉ báo động khi lỗi thực sự kéo dài.
    *   *Nhược điểm:* Phản ứng cực kỳ chậm chạp khi hệ thống sập hoàn toàn (phải mất nhiều giờ mới đủ lượng lỗi để kích hoạt alert). Hơn nữa, sau khi lỗi đã được sửa xong xuôi, alert vẫn tiếp tục kêu trong nhiều giờ tiếp theo vì trung bình cộng lỗi của 36 giờ qua vẫn ở mức cao (hiện tượng **Reset Delay**).

### Giải pháp: Multi-window Multi-burn-rate

Cơ chế này giải quyết triệt để hai nhược điểm trên bằng cách yêu cầu **cả 2 điều kiện** sau phải đồng thời xảy ra thì mới kích hoạt alert:
1.  **Short window (Khung thời gian ngắn - ví dụ: 5 phút):** Kiểm tra xem hệ thống *hiện tại* có đang lỗi nặng hay không.
2.  **Long window (Khung thời gian dài - ví dụ: 1 giờ):** Xác nhận xem lỗi này có thực sự là một *xu hướng kéo dài*, hay chỉ là một spike nhỏ thoáng qua.

Khi lỗi được sửa xong, khung thời gian ngắn (5m) lập tức giảm tỷ lệ lỗi xuống 0, khiến điều kiện `AND` bị phá vỡ và **alert lập tức tắt** mà không bị hiện tượng treo còi báo động (no reset delay)[7][3].

---

## 3. Thiết Lập Alert Rules trong Prometheus

Để cấu hình trong Prometheus, ta nên chia làm 2 bước: tạo các **Recording Rules** để tối ưu hóa hiệu năng tính toán tỷ lệ lỗi trước, sau đó viết **Alerting Rules**.

### Bước 1: Tạo Recording Rules (`rules.yml`)
Ta tính trước tỷ lệ lỗi (error ratio) cho các khung thời gian 5 phút, 30 phút, 1 giờ và 6 giờ.

```yaml
groups:
  - name: slo-recording-rules
    rules:
      # Tỷ lệ lỗi trong 5 phút
      - record: job:slo_errors_per_request:ratio_rate5m
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[5m]))
          /
          sum(rate(http_requests_total[5m]))

      # Tỷ lệ lỗi trong 30 phút
      - record: job:slo_errors_per_request:ratio_rate30m
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[30m]))
          /
          sum(rate(http_requests_total[30m]))

      # Tỷ lệ lỗi trong 1 giờ
      - record: job:slo_errors_per_request:ratio_rate1h
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[1h]))
          /
          sum(rate(http_requests_total[1h]))

      # Tỷ lệ lỗi trong 6 giờ
      - record: job:slo_errors_per_request:ratio_rate6h
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[6h]))
          /
          sum(rate(http_requests_total[6h]))
```

### Bước 2: Tạo Alerting Rules (`alerts.yml`)
Giả định mục tiêu **SLO = 99.9%** (tương đương tỷ lệ lỗi tối đa cho phép là `0.001` hay `0.1%`).
*   Ngưỡng cảnh báo Fast Burn (Page - khẩn cấp): Burn rate = **14.4x** (tỷ lệ lỗi tương đương: `14.4 * 0.001 = 0.0144` tức là `1.44%`).
*   Ngưỡng cảnh báo Slow Burn (Ticket - không khẩn cấp): Burn rate = **6x** (tỷ lệ lỗi tương đương: `6 * 0.001 = 0.006` tức là `0.6%`).

```yaml
groups:
  - name: slo-alerts
    rules:
      # 1. Fast Burn Alert (Page khẩn cấp cho kỹ sư trực)
      # Tiêu hao 2% ngân sách lỗi trong 1h (Burn rate 14.4x)
      - alert: SLOPageFastBurn
        expr: |
          (
            job:slo_errors_per_request:ratio_rate1h > (14.4 * 0.001)
            and
            job:slo_errors_per_request:ratio_rate5m > (14.4 * 0.001)
          )
        for: 0m # Kích hoạt ngay lập tức khi cả hai cửa sổ cùng vượt ngưỡng
        labels:
          severity: page
          tier: platform
        annotations:
          summary: "Tốc độ tiêu hao ngân sách lỗi (Burn Rate) cực kỳ cao"
          description: "Tỷ lệ lỗi HTTP vượt quá 1.44% liên tục trong cả khung 1h (hiện tại: {{ $value | humanizePercentage }}) và khung 5m."

      # 2. Slow Burn Alert (Tạo Ticket để kiểm tra, không cần đánh còi lúc nửa đêm)
      # Tiêu hao 5% ngân sách lỗi trong 6h (Burn rate 6x)
      - alert: SLOTicketSlowBurn
        expr: |
          (
            job:slo_errors_per_request:ratio_rate6h > (6 * 0.001)
            and
            job:slo_errors_per_request:ratio_rate30m > (6 * 0.001)
          )
        for: 0m
        labels:
          severity: ticket
          tier: platform
        annotations:
          summary: "Ngân sách lỗi đang bị rò rỉ chậm (Slow Burn Rate)"
          description: "Tỷ lệ lỗi HTTP vượt quá 0.6% liên tục trong cả khung 6h (hiện tại: {{ $value | humanizePercentage }}) và khung 30m."
```

---

## 4. Tóm Tắt Kinh Nghiệm Triển Khai Thực Tế

1.  **Luôn dùng Recording Rules:** Việc tính toán hàm `rate` trên các khoảng thời gian dài (như 6h hoặc 3d) trực tiếp trong câu lệnh Alert của Prometheus rất ngốn CPU và RAM. Đưa chúng vào recording rules chạy nền sẽ giúp Prometheus hoạt động nhẹ nhàng.
2.  **Giải quyết dịch vụ Low-Traffic:** Nếu ứng dụng của bạn có quá ít người truy cập (ví dụ: vài phút mới có 1 request), tỷ lệ lỗi tính theo phần trăm sẽ bị biến động rất mạnh (chỉ cần 1 request lỗi đã kéo tỷ lệ lên 100%). Với trường hợp này, hãy gom nhóm các dịch vụ tương tự lại để tính chung, hoặc tăng kích thước khung thời gian (window size) rộng hơn để làm mượt chỉ số[9].
3.  **Tích hợp với Alertmanager:** Phân luồng nhãn `severity: page` gửi tới PagerDuty/Opsgenie để gọi điện/nhắn tin, còn nhãn `severity: ticket` gửi tới Slack/Jira để xử lý sau.
