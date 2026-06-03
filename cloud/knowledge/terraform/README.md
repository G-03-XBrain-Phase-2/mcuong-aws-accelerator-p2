# Hướng Dẫn Học & Tài Liệu Terraform (Index)

Chào mừng bạn đến với thư viện kiến thức chuyên sâu về Terraform. Để việc tra cứu và học tập đạt hiệu quả cao nhất, kiến thức được phân chia thành **5 chuyên đề chính** tương ứng với tiến trình phát triển của bạn kết hợp với **lộ trình ưu tiên rút gọn** để nhanh chóng hoàn thành dự án thực tế trên AWS.

---

## 📂 Bản đồ Kiến thức (Table of Contents)

### [Chuyên đề 1: Cơ bản & Cú pháp HCL (Basics & HCL)](./01_basics_syntax.md)
*Hiểu về cách hoạt động của Terraform, khai báo tài nguyên và cú pháp ngôn ngữ HCL.*
* **Nội dung chính:** Providers, Resources, Data Sources, Variables (Input/Output/Local), HCL Syntax, AWS/GitHub Authentication.

### [Chuyên đề 2: Quản lý State & Khóa (State Management)](./02_state_management.md)
*Linh hồn của Terraform. Cách làm việc nhóm an toàn và quản lý trạng thái hạ tầng.*
* **Nội dung chính:** Local State vs Remote State, S3 Backend, State Locking với DynamoDB, các lệnh `terraform state`, `import` tài nguyên có sẵn.

### [Chuyên đề 3: Thiết kế Module (Reusable Modules)](./03_modules.md)
*Học cách viết code Terraform sạch, khô (DRY - Don't Repeat Yourself) và có thể tái sử dụng.*
* **Nội dung chính:** Root module vs Child module, cách truyền biến qua lại, sử dụng local modules & registry modules.

### [Chuyên đề 4: Các Tính năng Nâng cao (Advanced Features)](./04_advanced_features.md)
*Các kỹ thuật xử lý logic phức tạp khi hạ tầng phình to.*
* **Nội dung chính:** Meta-arguments (`depends_on`, `lifecycle`, `provider`), các biểu thức logic (`count`, `for_each`, dynamic blocks, conditionals).

### [Chuyên đề 5: Thực tế Dự án & Thực hành Tốt (Production Best Practices)](./05_production_best_practices.md)
*Cách áp dụng Terraform vào dự án thực tế quy mô lớn, an toàn và bảo mật.*
* **Nội dung chính:** Cấu trúc thư mục lớn, Quản lý Secrets, Security Linting (tfsec, tflint), CI/CD Automation cho IaC.

### [Chuyên đề Đặc Biệt: Ôn Thi Cấp Tốc - Lý Thuyết & Thực Hành Tự Luận](./06_exam_cheat_sheet.md)
*Tóm tắt cô đọng toàn bộ kiến thức cốt lõi (IaC, Types, Variables, Meta-arguments, Lifecycle, Modules) phục vụ cho bài kiểm tra tự luận 60 phút.*

---

## 🎯 LỘ TRÌNH HỌC ƯU TIÊN (RÚT GỌN) ĐỂ HOÀN THÀNH AWS WEB APP PROJECT

Nếu bạn muốn đẩy nhanh tiến độ, không muốn tốn quá nhiều thời gian xem hết các video lý thuyết mà muốn **tập trung thực hành sớm nhất**, hãy ưu tiên học các Section trên Udemy theo thứ tự chiến lược sau:

```
[ ƯU TIÊN 1: Section 6 ] ──> [ ƯU TIÊN 2: Section 4 ] ──> [ ƯU TIÊN 3: Section 7 ]
  (Thiết kế Modules)          (Cấu hình nâng cao HCL)        (Quản lý State từ xa)
```

### 🥇 1. ƯU TIÊN 1: Section 6 — Terraform Modules & Workspaces (2h 17m)
* **Mục tiêu:** Giải quyết trực tiếp **Step 1: Create VPC Module** của Final Project.
* **Nội dung cần nắm:** Cách chia thư mục cha/con, truyền nhận biến đầu vào/đầu ra giữa các file `main.tf`, `variables.tf`, và `outputs.tf` (Slide 28-30).
* **Tài liệu đối chiếu local:** **[Chuyên đề 3: Thiết kế Module](./03_modules.md)**

### 🥈 2. ƯU TIÊN 2: Section 4 — Read, Generate, Modify Configurations (10h 9m)
* **Mục tiêu:** Cung cấp toàn bộ "vũ khí" cú pháp HCL để viết code cho VPC, EC2, RDS, và Security Groups (Step 2, 3, 5).
* **Nội dung cần nắm:** 
  * Cách dùng **Data Sources** (Module 66-70) để tự động tìm kiếm AMI ID mà không bị lỗi Region.
  * Cách dùng **Implicit/Explicit Dependencies (`depends_on`)** (Module 95-96) để sắp xếp thứ tự tạo RDS sau VPC.
  * Cách dùng **`for_each`** và **`Dynamic Blocks`** (Module 77, 98) để tối ưu hóa khai báo luật tường lửa.
* **Tài liệu đối chiếu local:** **[Chuyên đề 1: Cơ bản](./01_basics_syntax.md)** & **[Chuyên đề 4: Tính năng nâng cao](./04_advanced_features.md)**

### 🥉 3. ƯU TIÊN 3: Section 7 — Remote State Management (2h 4m)
* **Mục tiêu:** Quản lý và bảo vệ file state dùng chung trên S3 + DynamoDB Locking.
* **Nội dung cần nắm:** Cách import tài nguyên có sẵn (`terraform import`), cách dọn dẹp và di chuyển state (`terraform state` commands).
* **Tài liệu đối chiếu local:** **[Chuyên đề 2: Quản lý State](./02_state_management.md)**

---

## 📅 Các Section học bổ trợ (Có thể học sau):
* **Section 5 (Provisioners - 56m):** Học cách chạy script trên EC2 (Dự án thực tế hiện nay ít dùng, có thể lướt nhanh).
* **Section 8 (Security) & Section 9 (Terraform Cloud & Enterprise):** Học sau khi đã triển khai thành công dự án ở Local AWS để nâng cấp hệ thống lên mức doanh nghiệp bảo mật.
* **Section 10 & 11 (Challenges & Exam Prep):** Để dành làm cuối cùng trước khi thi chứng chỉ chính thức.
