# Chuyên đề 3: Thiết kế Module (Reusable Modules)

## 1. Khái niệm Module là gì?
Module là một nhóm các file cấu hình Terraform nằm chung trong một thư mục. 
* **Root Module:** Thư mục chính nơi bạn chạy lệnh `terraform apply`.
* **Child Module:** Các module con được gọi từ Root Module để khởi tạo các cụm tài nguyên lặp đi lặp lại.

## 2. Lợi ích của Module
* **Tái sử dụng (Reusability):** Viết code tạo VPC hoặc EC2 một lần, dùng được cho nhiều môi trường (`dev`, `prod`).
* **Đóng gói (Encapsulation):** Giấu đi sự phức tạp của hạ tầng, chỉ phơi ra các biến đầu vào đơn giản.
* **Tiêu chuẩn hóa (Standardization):** Định hình các tiêu chuẩn bảo mật sẵn trong module.

## 3. Cách tổ chức & Khai báo một Module con

### Cấu trúc file trong một Child Module:
```text
modules/aws-s3-bucket/
├── main.tf      # Khai báo tài nguyên (aws_s3_bucket, aws_s3_bucket_acl...)
├── variables.tf # Các tham số đầu vào (bucket_name, tags...)
└── outputs.tf   # Các giá trị trả ra sau khi tạo xong (bucket_arn, bucket_domain_name...)
```

### Cách gọi Module ở Root Module:
```hcl
module "website_bucket" {
  source      = "./modules/aws-s3-bucket" # Đường dẫn local hoặc git url
  bucket_name = "my-awesome-app-bucket"   # Truyền biến đầu vào
  env         = "dev"
}

# Sử dụng Output trả về từ Module
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = module.website_bucket.bucket_domain_name # Lấy output của module
    origin_id   = "myS3Origin"
  }
  # ... cấu hình khác ...
}
```
