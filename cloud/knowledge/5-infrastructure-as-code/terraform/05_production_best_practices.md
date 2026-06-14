# Chuyên đề 5: Thực tế Dự án & Thực hành Tốt (Production Best Practices)

Đưa Terraform vào môi trường Production đòi hỏi tính an toàn, ổn định cao và khả năng cộng tác nhóm mượt mà.

## 1. Cấu trúc thư mục cho dự án thực tế
Tránh gom tất cả code vào một file `main.tf` khổng lồ. Hãy chia nhỏ theo chức năng:
```text
my-infrastructure/
├── providers.tf  # Khai báo provider & phiên bản
├── backend.tf    # Khai báo Remote Backend S3 + DynamoDB
├── main.tf       # Khởi tạo các tài nguyên chính hoặc gọi module
├── variables.tf  # Danh sách biến đầu vào
├── outputs.tf    # Danh sách biến đầu ra
└── terraform.tfvars # Giá trị thực tế của các biến (Không push file này lên Git nếu có secret)
```

## 2. Quản lý Secrets an toàn tuyệt đối
* **QUY TẮC VÀNG:** Không bao giờ hardcode API Keys, Passwords, Certificates vào code Terraform và push lên Git.
* **Giải pháp tốt:**
  1. Sử dụng biến môi trường (Ví dụ: `TF_VAR_db_password`).
  2. Tích hợp với **AWS Secrets Manager** hoặc **HashiCorp Vault** để lấy Secret động lúc runtime qua Data Source.
  ```hcl
  data "aws_secretsmanager_secret_version" "db_creds" {
    secret_id = "production-database-credentials"
  }
  
  # Giải nén JSON từ Secrets Manager
  locals {
    db_password = jsondecode(data.aws_secretsmanager_secret_version.db_creds.secret_string)["password"]
  }
  ```

## 3. Các công cụ kiểm thử & Tự động hóa (GitOps cho IaC)
* **`terraform fmt`:** Định dạng code tự động về chuẩn style chung của HashiCorp.
* **`tflint`:** Tìm kiếm các lỗi logic, cảnh báo deprecation hoặc cấu hình sai quy chuẩn Cloud.
* **`tfsec` / `trivy`:** Quét bảo mật, phát hiện sớm các lỗ hổng (Ví dụ: Mở cổng 22 cho cả thế giới `0.0.0.0/0`).
* **CI/CD Integration:** Chạy `terraform plan` tự động khi tạo Pull Request, chỉ cho phép chạy `terraform apply` khi PR được Merge vào nhánh chính (`main`).

## 4. Khái niệm ADR (Architectural Decision Record) trong IaC
Khi bạn thiết kế một kiến trúc hạ tầng (Ví dụ: Chọn SQS thay vì RabbitMQ, hoặc thiết kế VPC kiểu Multi-AZ), hãy viết một file markdown ngắn (gọi là **ADR**) lưu trong thư mục dự án để giải thích:
* **Bối cảnh (Context):** Tại sao cần đưa ra quyết định này?
* **Quyết định (Decision):** Chúng ta chọn phương án nào?
* **Hậu quả/Kết quả (Consequences):** Lợi ích thu được và những đánh đổi (trade-offs) là gì?
Điều này giúp người sau đọc code hiểu được tư duy thiết kế của bạn.
