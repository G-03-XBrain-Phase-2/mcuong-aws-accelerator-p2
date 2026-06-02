# Thứ 3 (02/06) - Tổng kết & Tiến trình

## 1. Nội dung đã học hôm nay
* **Quản lý State & Lock File trong Terraform:**
  * Hiểu sâu về cấu trúc file `terraform.tfstate`, `.terraform.lock.hcl` và `.tfstate.backup`.
  * Hiểu cơ chế so sánh đồng bộ: Desired State (code) $\leftrightarrow$ Current State (state file) $\leftrightarrow$ Real Infrastructure (Cloud).
  * Hiểu mức độ nguy hiểm của việc xóa file state (gây trùng lặp tài nguyên, xung đột và hạ tầng mồ côi).
* **Provider Tiers & Non-default Namespaces:**
  * Phân biệt Official, Partner, Community Providers.
  * Hiểu tại sao các provider ngoài namespace `hashicorp` (như GitHub thuộc namespace `integrations`) bắt buộc phải khai báo nguồn trong khối `required_providers`.
* **Quản lý thông tin nhạy cảm (Secrets Management):**
  * Sử dụng file biến bản xứ của Terraform (`.tfvars`) kết hợp khai báo thuộc tính `sensitive = true` để lưu trữ Access Token / Access Key an toàn.

## 2. Bài tập / Hands-on đã hoàn thành
* Tái cấu trúc lại toàn bộ thư mục thực hành thành các lab độc lập (`lab-01-first-ec2`, `lab-02-github-repo`) để tránh xung đột tài nguyên.
* Cấu hình và chạy thành công việc tự động **tạo Repository mới trên GitHub** (`cuong_repo`) sử dụng GitHub Provider thông qua Personal Access Token kết hợp nạp biến từ file dùng chung `secrets.tfvars` ở thư mục cha.
* Cấu hình file `.gitignore` đệ quy thông minh bảo vệ toàn bộ các file state và key nhạy cảm của các lab con.
* **Đường dẫn thực hành:** 
  * [lab-02-github-repo/github-repo.tf](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/terraform/lab-02-github-repo/github-repo.tf)
  * [secrets.tfvars](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/terraform/secrets.tfvars)

## 3. Khó khăn gặp phải & Cách giải quyết
* **Lỗi chính tả Provider Source:** Viết sai thành `intergrations/github` dẫn đến lỗi tải plugin khi `init`.
  * *Cách giải quyết:* Sửa lại đúng chính tả là `integrations/github`.
* **Lỗi chính tả thuộc tính khởi tạo Repo:** Khai báo sai tên thuộc tính thành `auto_int = true` thay vì `auto_init = true` dẫn đến lỗi biên dịch.
  * *Cách giải quyết:* Sửa lại chính xác thành `auto_init = true`.

## 4. Tiến trình hiện tại
- [ ] Chưa bắt đầu
- [ ] Đang tiến hành
- [x] Đã hoàn thành
