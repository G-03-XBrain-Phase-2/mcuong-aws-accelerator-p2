# Hướng dẫn học & Tài liệu Terraform (Index)

Chào mừng bạn đến với thư viện kiến thức chuyên sâu về Terraform. Để việc tra cứu và học tập đạt hiệu quả cao nhất, kiến thức được phân chia thành **5 chuyên đề chính** tương ứng với tiến trình phát triển từ Cơ bản đến Chuyên gia (Production-ready).

---

## 📂 Bản đồ Kiến thức (Table of Contents)

### [Chuyên đề 1: Cơ bản & Cú pháp HCL (Basics & HCL)](./01_basics_syntax.md)
*Hiểu về cách hoạt động của Terraform, khai báo tài nguyên và cú pháp ngôn ngữ HCL.*
* **Nội dung chính:** Providers, Resources, Data Sources, Variables (Input/Output/Local), HCL Syntax.

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
* **Nội dung chính:** Cấu trúc thư mục lớn, Quản lý Secrets, Security Linting (tfsec, tflint), CI/CD Automation cho IaC, Khái niệm ADR (Architectural Decision Record).

---

## 🎯 Cách sử dụng thư mục này hiệu quả:
1. **Đọc theo thứ tự:** Nếu bạn mới bắt đầu, hãy đi từ chuyên đề 1 đến chuyên đề 5.
2. **Liên kết thực hành:** Trong mỗi file lý thuyết, hãy chèn link dẫn tới file code thực hành tương ứng của bạn trong thư mục `practice/terraform/` để dễ đối chiếu.
3. **Tìm kiếm nhanh:** Bạn có thể nhấn `Cmd + Shift + F` trên VS Code để tìm kiếm bất kỳ từ khóa nào trong thư mục này.
