# Tại sao cần CI/CD cho hạ tầng (IaC) và So sánh với Chạy Local?

Khi bắt đầu làm việc với các công cụ Infrastructure as Code (IaC) như Terraform, một câu hỏi rất phổ biến là: *"Tại sao phải tốn công setup CI/CD (GitHub Actions, GitLab CI) phức tạp cho hạ tầng, trong khi chúng ta hoàn toàn có thể chạy lệnh `terraform apply` ngay dưới máy local để triển khai hạ tầng lên Cloud?"*

Dưới đây là phân tích chi tiết về vị trí của CI/CD hạ tầng trong hệ thống và lý do tại sao chạy hạ tầng dưới local là một **Anti-pattern** (lỗi thiết kế) trong môi trường thực tế.

---

## 1. Vị trí của CI/CD hạ tầng (IaC) trong luồng tổng thể

Hạ tầng luôn đóng vai trò là **nền tảng (Foundation)** để ứng dụng (Frontend/Backend) chạy lên đó. Vì vậy, CI/CD hạ tầng sẽ được tổ chức độc lập hoặc chạy trước CI/CD của ứng dụng.

### Mô hình 1: Tách biệt Repository (Khuyến nghị cho dự án lớn)
*   **Repo Hạ tầng (`infra-live`):** Chỉ chứa code Terraform/OpenTofu hoặc Kubernetes Manifests. Khi bạn cần tạo thêm Database RDS, đổi size EC2, hay mở cổng Security Group,... bạn sẽ tạo Pull Request (PR) trên repo này. CI/CD hạ tầng chạy và apply để cập nhật tài nguyên Cloud.
*   **Repo Ứng dụng (`app-backend`, `app-frontend`):** Chỉ chứa mã nguồn ứng dụng và Dockerfile. Khi có code mới, CI/CD ứng dụng sẽ build image mới rồi deploy lên cụm hạ tầng đã có sẵn do repo hạ tầng tạo ra trước đó.

### Mô hình 2: Chung Repository (Monorepo cho dự án nhỏ/vừa)
*   Cả code app và infra nằm chung một repo nhưng chia thư mục riêng biệt.
*   Workflow CI/CD sẽ sử dụng tính năng lọc đường dẫn (`paths filter`) để phân tách: sửa code app thì chỉ chạy job deploy app, sửa code folder `terraform/` thì chỉ chạy job Terraform.

---

## 2. So sánh chi tiết: Chạy local vs Chạy qua CI/CD

| Tiêu chí | Chạy dưới máy Local | Chạy qua CI/CD (GitHub Actions / GitLab CI) |
| :--- | :--- | :--- |
| **Bảo mật thông tin xác thực (Secrets)** | Kỹ sư lưu trữ Access Key/Secret Key (có quyền Admin) lâu dài trên máy cá nhân. Rất dễ bị hack hoặc rò rỉ. | Không cần lưu key trên máy cá nhân. Runner kết nối với Cloud qua **OIDC (OpenID Connect)** sử dụng token ngắn hạn rất an toàn. |
| **Kiểm soát & Phê duyệt (Governance)** | Một người tự ý sửa code local rồi chạy `apply` trực tiếp. Có thể vô tình xóa nhầm Database Production mà không ai biết hay ngăn được. | Bắt buộc phải tạo PR. Reviewer xem trước file `terraform plan` trên PR. Sau khi được duyệt (Approve) và Merge thì CI/CD mới được chạy `apply`. |
| **Đồng bộ trạng thái (State & Git)** | Dễ bị lệch state (drift). Người A chạy `apply` ở local nhưng quên push code lên Git, người B sau đó pull code cũ về chạy đè lên gây hỏng hệ thống. | Git là **Nguồn sự thật duy nhất (Single Source of Truth)**. Chỉ những code đã được merge vào nhánh chính (`main`) mới được phép apply. |
| **Môi trường thực thi** | Phụ thuộc vào hệ điều hành (macOS, Windows, Linux) và phiên bản Terraform được cài trên máy của từng người. | Môi trường đồng nhất trên Cloud Runner (ví dụ chạy trên cùng 1 Docker image chạy Ubuntu chứa phiên bản Terraform cố định). |
| **Lịch sử kiểm toán (Audit Trail)** | Khó kiểm tra ai đã gõ lệnh gì dưới local, khi nào và tại sao hạ tầng bị sửa đổi. | Mọi thay đổi đều được ghi vết chi tiết thông qua Git commits, PRs, và Logs chạy của GitHub Actions. |

---

## 3. Kết luận

Chạy `terraform` dưới local chỉ phù hợp cho giai đoạn **thử nghiệm cá nhân (Sandbox/Dev)**. Khi hạ tầng đã phục vụ cho người dùng thật (Production), việc đưa toàn bộ luồng IaC lên CI/CD (hay còn gọi là **GitOps cho hạ tầng**) là bắt buộc để đảm bảo: **An toàn bảo mật**, **Kiểm soát chặt chẽ** và **Khả năng khôi phục nhanh chóng** khi có sự cố xảy ra.
