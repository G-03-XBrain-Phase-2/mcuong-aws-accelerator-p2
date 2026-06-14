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
* Tái cấu trúc lại toàn bộ thư mục thực hành thành các lab độc lập (`lab-01-first-ec2`, `lab-02-github-repo`, `lab-03-remote-locking-state`) để tránh xung đột tài nguyên.
* Cấu hình và chạy thành công việc tự động **tạo Repository mới trên GitHub** (`cuong_repo`) sử dụng GitHub Provider thông qua Personal Access Token kết hợp nạp biến từ file dùng chung `secrets.tfvars` ở thư mục cha.
* Cấu hình file `.gitignore` đệ quy thông minh bảo vệ toàn bộ các file state và key nhạy cảm của các lab con.
* **Cấu hình & triển khai thành công Lab 03:** Thiết lập S3 Bucket (bật Versioning) và DynamoDB Table dùng làm **Remote State Backend & State Locking** dùng chung cho các dự án sau này.
* **Di chuyển thành công Lab 01 (EC2 AWS) sang sử dụng Remote Backend:** Tích hợp S3 (`mcuong-terraform-state`) và DynamoDB (`StateLocking`) làm backend lưu trữ từ xa. Thực thi khởi chạy thành công EC2 Instance với state được tự động đồng bộ lên đám mây AWS.
* **Đường dẫn thực hành:** 
  * [lab-01-first-ec2/first-ec2.tf](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/terraform/lab-01-first-ec2/first-ec2.tf)
  * [lab-02-github-repo/github-repo.tf](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/terraform/lab-02-github-repo/github-repo.tf)
  * [lab-03-remote-locking-state/remote.tf](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/terraform/lab-03-remote-locking-state/remote.tf)
  * [secrets.tfvars](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/terraform/secrets.tfvars)

## 3. Khó khăn gặp phải & Cách giải quyết
* **Lỗi chính tả Provider Source:** Viết sai thành `intergrations/github` dẫn đến lỗi tải plugin khi `init`.
  * *Cách giải quyết:* Sửa lại đúng chính tả là `integrations/github`.
* **Lỗi chính tả thuộc tính khởi tạo Repo:** Khai báo sai tên thuộc tính thành `auto_int = true` thay vì `auto_init = true` dẫn đến lỗi biên dịch.
  * *Cách giải quyết:* Sửa lại chính xác thành `auto_init = true`.
* **Lỗi khai báo thuộc tính DynamoDB khi dùng Pay-Per-Request:** Khai báo `billing_mode = "PAY_PER_REQUEST"` nhưng quên chưa xóa bỏ `read_capacity` và `write_capacity` dẫn đến lỗi `Invalid Attribute Combination`.
  * *Cách giải quyết:* Đã chủ động phát hiện nguyên nhân lỗi và loại bỏ hoàn toàn 2 thuộc tính dung lượng cố định đó để đưa DynamoDB về chế độ On-Demand chuẩn xác.
* **Lỗi xác thực S3 Backend khi `init` (đa tài khoản):** S3 backend không hỗ trợ HCL variables, đồng thời AWS CLI bị cấu hình lỗi vùng mặc định (dán nhầm token), dẫn đến lỗi `403 Forbidden` khi init.
  * *Cách giải quyết:* Viết file credentials riêng biệt `backend.hcl` và khởi động lại với cờ nạp động `-backend-config="../backend.hcl"` kết hợp cờ `-reconfigure` để bỏ qua toàn bộ cache lỗi cũ, khởi chạy thành công 100%.
* **GitHub Push Protection chặn đẩy file `backend.hcl` chứa secrets:** Hệ thống quét phát hiện nguy cơ rò rỉ AWS credentials lên Git.
  * *Cách giải quyết:* Đã thực hiện rollback nhanh commit, bổ sung các mẫu chặn `**/backend.hcl`, `**/secrets.hcl`, `**/*.auth.hcl` vào file cấu hình gốc `.gitignore` để đảm bảo an toàn tuyệt đối.

## 4. Tiến trình hiện tại
- [ ] Chưa bắt đầu
- [ ] Đang tiến hành
- [x] Đã hoàn thành