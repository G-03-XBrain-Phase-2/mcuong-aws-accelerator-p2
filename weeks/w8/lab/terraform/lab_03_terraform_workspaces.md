# Lab 3: Quản Lý Đa Môi Trường Bằng Terraform Workspaces

## 1. Mục Tiêu Của Bài Lab
* Hiểu cơ chế hoạt động của **Terraform Workspaces** để phân tách file state của các môi trường (`dev`, `prod`) trong cùng một thư mục dự án.
* Sử dụng biến nội tại `${terraform.workspace}` để thay đổi động các tham số cấu hình hạ tầng tùy theo môi trường (ví dụ: instance type, Name tag).
* Thực hành thuần thục các câu lệnh quản lý workspace trong CLI.

---

## 2. Mô Hình Hoạt Động Của Lab

```
                        [ lab-07-workspaces ]
                                 │
         ┌───────────────────────┼───────────────────────┐
         ▼                       ▼                       ▼
   Workspace: default       Workspace: dev          Workspace: prod
   (Lưu state cục bộ)      (State lưu trong:       (State lưu trong:
   terraform.tfstate       .terraform.tfstate.d/   .terraform.tfstate.d/
                            dev/terraform.tfstate)  prod/terraform.tfstate)
         │                       │                       │
         ▼                       ▼                       ▼
   EC2: t3.micro           EC2: t3.micro           EC2: t3.medium
   Name: cuong-server-     Name: cuong-server-dev  Name: cuong-server-prod
         default
```

---

## 3. Các Bước Thực Hiện Step-by-Step

### Bước 1: Khởi tạo thư mục thực hành
```bash
cd /Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/terraform
mkdir -p lab-07-workspaces
```

### Bước 2: Tạo các file HCL cho bài Lab

#### 1. Định nghĩa Variables: [variables.tf](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/terraform/lab-07-workspaces/variables.tf)
Chúng ta chỉ cần khai báo Region, AMI, Subnet ID và các biến xác thực AWS:
```hcl
variable "aws_region" {
  type    = string
  default = "ap-southeast-1"
}

variable "access_key" {
  type      = string
  sensitive = true
}

variable "secret_key" {
  type      = string
  sensitive = true
}

variable "session_token" {
  type      = string
  sensitive = true
  default   = null
}

variable "ami" {
  type        = string
  default     = "ami-0543dbdaf4e114be7" # Amazon Linux 2023 tại Singapore
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID cụ thể từ tài khoản AWS của bạn"
}
```

#### 2. Viết Code logic chính: [main.tf](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/terraform/lab-07-workspaces/main.tf)
Sử dụng biểu thức điều kiện kết hợp với biến `${terraform.workspace}` để thay đổi kích thước máy chủ (`t3.medium` cho `prod`, `t3.micro` cho các môi trường khác) và thay đổi Tag của tài nguyên:
```hcl
provider "aws" {
  region     = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key
  token      = var.session_token
}

locals {
  # Nếu ở workspace "prod" -> Dùng size t3.medium, ngược lại dùng t3.micro để tiết kiệm chi phí
  instance_type = terraform.workspace == "prod" ? "t3.medium" : "t3.micro"
  
  # Đặt tên Tag động theo môi trường hiện tại
  instance_name = "cuong-server-${terraform.workspace}"
}

resource "aws_instance" "my_server" {
  ami           = var.ami
  instance_type = local.instance_type
  subnet_id     = var.subnet_id

  tags = {
    Name        = local.instance_name
    Environment = terraform.workspace
  }
}
```

#### 3. Cấu hình Outputs: [outputs.tf](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/terraform/lab-07-workspaces/outputs.tf)
In ra tên workspace hiện tại, IP máy chủ, Tag Name và Instance Type đã chọn để xác minh:
```hcl
output "current_workspace" {
  value       = terraform.workspace
  description = "Workspace hiện hành"
}

output "instance_ip" {
  value       = aws_instance.my_server.public_ip
}

output "instance_name_tag" {
  value       = aws_instance.my_server.tags.Name
}

output "instance_type" {
  value       = aws_instance.my_server.instance_type
}
```

---

## 4. Thực Hành Quản Lý Workspace Trên CLI

### Bước 1: Khởi tạo thư mục và xem workspace mặc định
1. Tạo file `terraform.tfvars` ở thư mục `lab-07-workspaces` và điền Subnet ID của bạn:
   ```hcl
   subnet_id = "subnet-xxxxxxxxxxxxxxxxx"
   ```
2. Khởi tạo dự án:
   ```bash
   terraform init
   ```
3. Xem danh sách workspace mặc định:
   ```bash
   terraform workspace list
   ```
   *Màn hình sẽ hiển thị:*
   ```text
   * default
   ```
   Dấu `*` báo hiệu bạn đang đứng ở workspace mặc định (`default`).

### Bước 2: Tạo và Triển khai trên Workspace "dev"
1. Tạo workspace mới có tên `dev`:
   ```bash
   terraform workspace new dev
   ```
   *Lệnh này sẽ tạo workspace `dev` và tự động switch sang nó.*
2. Chạy `plan` để kiểm tra thông số:
   ```bash
   terraform plan -var-file="../secrets.tfvars"
   ```
   > [!NOTE]
   > Bạn hãy chú ý trong output plan:
   > * `instance_type` sẽ là `"t3.micro"`.
   > * Tag `Name` sẽ là `"cuong-server-dev"`.
3. Thực thi triển khai môi trường Dev:
   ```bash
   terraform apply -var-file="../secrets.tfvars" -auto-approve
   ```
   *Lưu ý: File state lúc này được lưu riêng biệt tại `.terraform.tfstate.d/dev/terraform.tfstate`*.

### Bước 3: Tạo và Triển khai trên Workspace "prod"
1. Tạo workspace mới có tên `prod`:
   ```bash
   terraform workspace new prod
   ```
2. Chạy `plan` để kiểm tra thông số:
   ```bash
   terraform plan -var-file="../secrets.tfvars"
   ```
   > [!IMPORTANT]
   > Bạn hãy chú ý sự thay đổi động:
   > * `instance_type` tự động đổi thành `"t3.medium"` (do logic block local của chúng ta).
   > * Tag `Name` đổi thành `"cuong-server-prod"`.
3. Thực thi triển khai môi trường Prod:
   ```bash
   terraform apply -var-file="../secrets.tfvars" -auto-approve
   ```
   *File state của môi trường Prod được lưu cách ly tại `.terraform.tfstate.d/prod/terraform.tfstate`*.

### Bước 4: Kiểm tra và Chuyển đổi giữa các Workspace
1. Liệt kê lại các workspace:
   ```bash
   terraform workspace list
   ```
   *Kết quả:*
   ```text
     default
     dev
   * prod
   ```
2. Chuyển đổi lại về môi trường `dev`:
   ```bash
   terraform workspace select dev
   ```
3. Xem cấu hình hiện tại ở dev (sẽ không bị ảnh hưởng bởi prod):
   ```bash
   terraform show
   ```

---

## 5. Dọn Dẹp Hạ Tầng

Để tránh phát sinh chi phí trên AWS, hãy nhớ dọn dẹp hạ tầng ở cả hai môi trường:

1. Khi đang ở workspace `dev`:
   ```bash
   terraform destroy -var-file="../secrets.tfvars" -auto-approve
   ```
2. Chuyển sang workspace `prod`:
   ```bash
   terraform workspace select prod
   ```
3. Chạy lệnh xóa môi trường Prod:
   ```bash
   terraform destroy -var-file="../secrets.tfvars" -auto-approve
   ```
4. Xóa các workspace phụ khi không còn dùng:
   ```bash
   terraform workspace select default
   terraform workspace delete dev
   terraform workspace delete prod
   ```
