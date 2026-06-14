# Phương Pháp Luận SLO: Giám Sát Độ Khả Dụng và Độ Trễ Hệ Thống

Để xây dựng một hệ thống tin cậy, chúng ta không thể dựa vào cảm tính mà phải dùng số liệu định lượng cụ thể. Phương pháp luận **SLI / SLO / SLA** (phổ biến bởi Google SRE) cung cấp một khung tư duy tiêu chuẩn giúp đo lường mức độ tin cậy của dịch vụ và đưa ra các quyết định vận hành chính xác.

---

## 1. Phân biệt SLI, SLO và SLA

Ba khái niệm này thường bị nhầm lẫn nhưng thực chất chúng nằm ở các lớp vai trò hoàn toàn khác nhau:

```
+-------------------------------------------------------------+
|  SLA (Business/Legal Agreement)                             |
|    |                                                        |
|    +--> SLO (Technical Target - e.g., 99.9% success rate)   |
|           |                                                 |
|           +--> SLI (Measurement Metric - e.g., HTTP 2xx/5xx)|
+-------------------------------------------------------------+
```

*   **SLI (Service Level Indicator - Chỉ số):** 
    *   *Định nghĩa:* Là thước đo định lượng cụ thể về hiệu năng của dịch vụ tại một thời điểm.
    *   *Câu hỏi:* *"Hệ thống đang chạy nhanh/ổn định ở mức độ nào?"*
    *   *Ví dụ:* Tỷ lệ request HTTP thành công (không bị lỗi 5xx), tỷ lệ request có phản hồi dưới 200ms.
*   **SLO (Service Level Objective - Mục tiêu):**
    *   *Định nghĩa:* Là cái đích, đích ngắm hiệu năng mà đội ngũ kỹ thuật cam kết đạt được cho SLI trong một khoảng thời gian (ví dụ: 30 ngày).
    *   *Câu hỏi:* *"Hệ thống cần phải tốt ở mức độ nào để người dùng hài lòng?"*
    *   *Ví dụ:* Tỷ lệ thành công phải đạt **99.9%** trong vòng 30 ngày qua.
*   **SLA (Service Level Agreement - Cam kết pháp lý):**
    *   *Định nghĩa:* Là thỏa thuận ràng buộc pháp lý hoặc thương mại giữa nhà cung cấp dịch vụ và khách hàng. Nếu vi phạm SLO dẫn tới vi phạm SLA, nhà cung cấp sẽ phải bồi thường tiền bạc hoặc tài nguyên.
    *   *Câu hỏi:* *"Chuyện gì xảy ra nếu chúng ta không đạt được mục tiêu?"*
    *   *Ví dụ:* Nếu độ khả dụng tháng dưới 99.0%, hoàn trả 10% phí dịch vụ.

---

## 2. Công Thức Tính Toán SLI cho Availability và Latency

Hầu hết mọi chỉ số SLI đều tuân theo công thức tỷ lệ chuẩn:

> **Công thức SLI tổng quát:**
> ```text
> SLI = (Số sự kiện đạt chuẩn (Good Events) / Tổng số sự kiện hợp lệ (Total Valid Events)) * 100%
> ```

### a. Tính Khả Dụng (Availability SLO)
Đo lường xem dịch vụ hoạt động đúng đắn bao nhiêu phần trăm thời gian hoặc số lượng request.
*   **Good Events:** Số requests trả về mã HTTP thành công (không phải 5xx).
*   **Total Valid Events:** Tổng số requests hợp lệ nhận được (thường loại trừ mã lỗi do người dùng như 4xx để tránh làm nhiễu chỉ số của hệ thống).

> **Công thức Availability SLI:**
> ```text
> Availability SLI = ((Tổng request HTTP - Số request lỗi 5xx) / (Tổng request HTTP - Số request lỗi 4xx)) * 100%
> ```

*   **Truy vấn PromQL tương ứng:**
    ```promql
    (
      sum(rate(http_requests_total{status!~"5.."}[5m])) 
      / 
      sum(rate(http_requests_total{status!~"4.."}[5m]))
    ) * 100
    ```

### b. Độ Trễ (Latency SLO)
Đo lường tốc độ phản hồi của hệ thống. Thay vì tính trung bình (average) - vốn bị nhiễu bởi các giá trị quá lớn hoặc quá nhỏ (outliers) - ta nên sử dụng **ngưỡng giới hạn (threshold)** kết hợp với phân vị.
*   **Good Events:** Số lượng requests có thời gian xử lý nhỏ hơn một ngưỡng định sẵn (ví dụ: dưới 500ms).
*   **Total Valid Events:** Tổng số requests được xử lý.

> **Công thức Latency SLI:**
> ```text
> Latency SLI = (Số request có Latency < 500ms / Tổng số request) * 100%
> ```

*   **Truy vấn PromQL tương ứng (sử dụng Prometheus Histogram):**
    ```promql
    (
      sum(rate(http_request_duration_seconds_bucket{le="0.5"}[5m]))
      /
      sum(rate(http_request_duration_seconds_count[5m]))
    ) * 100
    ```

---

## 3. Khái Niệm Ngân Sách Lỗi (Error Budget)

**Error Budget** là phần dung sai cho phép hệ thống gặp lỗi hoặc chạy chậm trong một khoảng thời gian xác định. Nó là cầu nối giải quyết mâu thuẫn muôn thuở giữa Dev (muốn deploy tính năng mới thật nhanh) và Ops/SRE (muốn hệ thống luôn ổn định).

> **Công thức tính Error Budget:**
> ```text
> Error Budget = 100% - SLO
> ```

*Ví dụ:* Nếu bạn đặt SLO Độ khả dụng là **99.9%** trong 30 ngày:
*   Error Budget của bạn là `100% - 99.9% = 0.1%`.
*   Quy đổi ra thời gian chết (downtime) tối đa cho phép:
    *   30 ngày = 43,200 phút.
    *   Downtime cho phép: `43,200 * 0.001 = 43.2 phút/tháng`.

### Cách ứng dụng Error Budget vào vận hành thực tế:
*   **Còn ngân sách (Error Budget > 0):** Đội phát triển (Dev) có quyền tự do thử nghiệm, deploy tính năng mới nhanh chóng, chấp nhận rủi ro lỗi nhỏ.
*   **Cạn ngân sách (Error Budget = 0 hoặc âm):** Hệ thống dừng toàn bộ các đợt deploy tính năng mới (chỉ cho phép hotfix lỗi). Toàn bộ đội ngũ tập trung cải tiến độ tin cậy hệ thống, tối ưu hóa code, nâng cấp hạ tầng cho đến khi ngân sách hồi phục lại.

---

## 4. Quy trình 4 bước áp dụng SLO vào thực tế

1.  **Lựa chọn SLI phù hợp với loại dịch vụ:**
    *   *User-facing (Web/API):* Availability, Latency, Throughput.
    *   *Storage/Database:* Latency, Durability (Độ bền vững dữ liệu).
    *   *Offline processing (Queue/Cronjob):* Freshness (Độ trễ xử lý dữ liệu), Throughput.
2.  **Xác định SLO mục tiêu thực tế:**
    *   Đừng bao giờ đặt mục tiêu 100% (bất khả thi và cực kỳ tốn chi phí hạ tầng).
    *   Bắt đầu từ mức độ hài lòng của người dùng thực tế (ví dụ: 99% hoặc 99.5%), sau đó nâng dần lên dựa trên dữ liệu lịch sử.
3.  **Thiết lập giám sát và cảnh báo (Alerting):**
    *   Vẽ dashboard hiển thị lượng Error Budget còn lại.
    *   Sử dụng cơ chế cảnh báo Burn Rate (tốc độ tiêu hao ngân sách lỗi) thay vì cảnh báo tức thời.
4.  **Họp đánh giá định kỳ (Post-mortem & Review):**
    *   Hàng tháng rà soát xem có bao nhiêu lần vi phạm SLO. Nguyên nhân vi phạm do đâu? Điều chỉnh lại các ngưỡng SLO nếu nó quá nghiêm ngặt hoặc quá lỏng lẻo so với trải nghiệm thực tế của người dùng.
