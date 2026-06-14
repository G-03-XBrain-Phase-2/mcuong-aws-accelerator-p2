# Chiến Lược Rollback Trong GitOps: Git Revert vs Kubectl Rollout Undo

Trong vận hành hệ thống, lỗi deploy là điều không thể tránh khỏi. Khi xảy ra sự cố trên môi trường Product, phản ứng đầu tiên của chúng ta là **Rollback** (quay xe) về phiên bản chạy ổn định gần nhất. Tuy nhiên, trong mô hình GitOps, phương pháp thực hiện rollback có sự khác biệt rất lớn so với cách vận hành truyền thống.

---

## 1. Bản chất của hai phương pháp

### a. `git revert` (Mô hình GitOps - Khuyên dùng)
*   **Cách thức hoạt động:** Tạo ra một commit mới trên Git để đảo ngược (undo) những thay đổi của commit bị lỗi trước đó, sau đó push commit này lên nhánh chính (`main`/`master`).
*   **Quy trình đồng bộ:** GitOps Controller (Argo CD hoặc Flux) phát hiện Git có commit mới, tự động tiến hành reconcile (đồng bộ) và cập nhật Cluster về trạng thái mong muốn cũ (nhưng biểu diễn bằng commit mới).

### b. `kubectl rollout undo` (Mô hình truyền thống - Không khuyên dùng)
*   **Cách thức hoạt động:** Tương tác trực tiếp với Kubernetes API Server (ví dụ qua lệnh `kubectl rollout undo deployment/my-app`), yêu cầu Kubernetes chuyển hướng chạy của Deployment về phiên bản `ReplicaSet` cũ hơn được lưu trong lịch sử cluster.
*   **Quy trình đồng bộ:** Bỏ qua hoàn toàn Git. Cluster thay đổi trạng thái trực tiếp mà Git không hề hay biết.

---

## 2. Tại sao `kubectl rollout undo` là Anti-pattern (lỗi thiết kế) trong GitOps?

Khi bạn áp dụng GitOps, **Git là Nguồn Sự Thật Duy Nhất (Single Source of Truth)**. Việc chạy `kubectl rollout undo` sẽ phá vỡ nguyên lý này và dẫn đến các hệ lụy sau:

### a. Hiện tượng Trôi lệch Cấu hình (Configuration Drift)
*   Sau khi chạy `kubectl`, Cluster đang chạy phiên bản cũ (ví dụ: `v1`), nhưng file cấu hình trên Git vẫn đang khai báo phiên bản lỗi (ví dụ: `v2`).
*   Trạng thái thực tế (Cluster) và trạng thái mong muốn (Git) không còn khớp nhau.

### b. Bị GitOps Controller ghi đè (Auto-healing Override)
*   Nếu GitOps Controller của bạn bật tính năng **Self-healing (Tự phục hồi)** hoặc **Auto-sync (Tự động đồng bộ)** (đây là cấu hình tiêu chuẩn):
    *   Ngay khi bạn vừa rollback bằng `kubectl rollout undo` thành công, Controller sẽ phát hiện: *"Ơ, trên Git bảo chạy v2 mà dưới Cluster lại chạy v1? Có gì đó sai sai!"*
    *   Controller sẽ lập tức ghi đè trạng thái của bạn bằng cách deploy lại phiên bản lỗi `v2` từ Git xuống.
    *   **Hậu quả:** Hệ thống tiếp tục lỗi, hành động rollback của bạn bị vô hiệu hóa trong vài giây/vài phút.

### c. Mất dấu vết kiểm toán (No Audit Trail)
*   Mọi thay đổi hạ tầng trong GitOps nên được ghi nhận: Ai làm? Khi nào? Tại sao? thông qua Git History (Git Log).
*   Chạy lệnh `kubectl` trực tiếp trên terminal sẽ không để lại dấu vết gì trên Git, khiến việc điều tra nguyên nhân gốc rễ (Post-mortem) sau sự cố gặp nhiều khó khăn.

---

## 3. So Sánh Chi Tiết

| Tiêu chí | `git revert` | `kubectl rollout undo` |
| :--- | :--- | :--- |
| **Độ khớp của Source of Truth** | Hoàn hảo (Git = Cluster) | Bị lệch (Git ≠ Cluster) |
| **Tự động đồng bộ (Auto-Sync)** | Hoạt động bình thường, ổn định | Bị ghi đè ngay lập tức |
| **Audit Trail (Lịch sử)** | Có lưu vết (Git commit history, PR approvals) | Không có vết trên Git (chỉ có trong K8s audit log nếu có cấu hình) |
| **Tốc độ thực thi** | Chậm hơn một chút (cần commit, push, chờ sync) | Rất nhanh (tác động trực tiếp lên Cluster) |
| **Độ an toàn** | Rất cao | Thấp (dễ gây bối rối cho hệ thống tự động) |

---

## 4. Các giải pháp Rollback chuẩn chỉnh trong GitOps

Để đảm bảo vừa xử lý sự cố nhanh vừa tuân thủ đúng nguyên lý GitOps, bạn nên áp dụng các chiến lược sau:

### Cách 1: Sử dụng Git Revert (Mức độ cơ bản)
1.  Nhận diện commit gây lỗi (ví dụ: hash `a1b2c3d`).
2.  Chạy lệnh: `git revert a1b2c3d`
3.  Tạo Pull Request và Merge (hoặc push thẳng lên main nếu có quyền khẩn cấp bypass PR policy).
4.  Bấm nút **Sync** thủ công trên Argo CD (nếu tắt auto-sync) để rút ngắn thời gian chờ đợi.

### Cách 2: Tạm thời tắt Auto-Sync (Khi xử lý sự cố khẩn cấp cực hạn)
Nếu hệ thống đang sập nghiêm trọng và bạn cần cứu lỗi ngay lập tức bằng `kubectl` hoặc rollback thủ công trên giao diện Argo CD:
1.  Lên giao diện Argo CD, tạm thời **Tắt tính năng Auto-Sync / Self-Healing** của ứng dụng đó.
2.  Thực hiện rollback trực tiếp trên Cluster để hệ thống sống lại.
3.  Tiến hành thực hiện `git revert` code trên Git.
4.  Khi Git đã cập nhật bản sửa lỗi/rollback thành công, bật lại tính năng **Auto-Sync / Self-Healing** trên Argo CD để hệ thống đồng bộ lại theo đúng chuẩn.

### Cách 3: Sử dụng Công cụ Progressive Delivery (Mức độ nâng cao - Khuyên dùng cho Prod)
Sử dụng các công cụ như **Argo Rollouts** hoặc **Flagger** thay thế cho Deployment mặc định của Kubernetes.
*   Các công cụ này hỗ trợ chiến lược deploy dạng **Canary** hoặc **Blue-Green**.
*   Khi deploy phiên bản mới, chúng sẽ dẫn một phần nhỏ traffic (ví dụ 10%) sang bản mới và liên tục đo lường các chỉ số sức khỏe (Prometheus Metrics như tỉ lệ lỗi HTTP 5xx, độ trễ...).
*   Nếu phát hiện lỗi vượt ngưỡng cấu hình, **Argo Rollouts/Flagger sẽ tự động rollback ngay lập tức** về bản cũ ở tầng mạng và ReplicaSet mà không cần chờ tác động thủ công, đồng thời giữ nguyên trạng thái an toàn để bạn tiến hành `git revert` sau đó.
