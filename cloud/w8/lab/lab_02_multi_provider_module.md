# Lab 2: Cấu Hình Multi-Provider Cho Module (Triển Khai Hạ Tầng Đa Region)

## 1. Mục Tiêu Của Bài Lab
* Biết cách khai báo các **Provider Alias** khác nhau tại Root Module.
* Hiểu cách truyền rõ ràng cấu hình provider sang Child Module thông qua đối số `providers`.
* Thực hành tạo tài nguyên trên **2 Region khác nhau** (`ap-southeast-1` - Singapore và `us-east-1` - N. Virginia) từ cùng một code module duy nhất.

---

## 2. Kiến Thức Lý Thuyết Quan Trọng
Mặc định, module con sẽ tự động kế thừa provider mặc định (default provider) của Root Module.
Tuy nhiên, nếu bạn muốn ghi đè hoặc chỉ định cụ thể một Child Module chạy trên một Provider Alias nào đó, bạn sử dụng cú pháp:
```hcl
module "my_module" {
  source = "./modules/simple-ec2"
  
  providers = {
    aws = aws.my_alias_name # Gán alias ở Root vào provider mặc định trong Child Module
  }
}
```

---

## 3. Cấu Trúc Thư Mục Dự Án

```
[ Root Module (lab-06-multi-provider-module) ]
    ├── variables.tf   (Khai báo region, AMI và Subnet của 2 Region)
    ├── main.tf        (Khai báo 2 AWS provider và gọi module 2 lần)
    ├── outputs.tf     (In ra Public IP & AZ của 2 EC2 instance)
    └── [ modules/simple-ec2 ]
            ├── variables.tf  (Định nghĩa input: ami, instance_type, subnet_id)
            ├── main.tf       (Chỉ chứa cấu hình tạo EC2 đơn giản)
            └── outputs.tf    (Xuất ra ID, IP & Availability Zone)
```

---

## 4. Các Bước Thực Hiện Step-by-Step

### Bước 1: Tạo thư mục thực hành
```bash
cd /Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/terraform
mkdir -p lab-06-multi-provider-module/modules/simple-ec2
```

### Bước 2: Thiết lập Child Module đơn giản (modules/simple-ec2)

#### 1. File resource: [main.tf](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/terraform/lab-06-multi-provider-module/modules/simple-ec2/main.tf)
Module này chỉ thực hiện tạo một EC2 đơn giản, không chứa cấu hình Security Group để tránh xung đột lookup subnets:
```hcl
resource "aws_instance" "this" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  tags = {
    Name = var.instance_name
  }
}
```

#### 2. File inputs: [variables.tf](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/terraform/lab-06-multi-provider-module/modules/simple-ec2/variables.tf)
```hcl
variable "ami" {
  type        = string
  description = "AMI ID của EC2"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "Kích thước EC2"
}

variable "instance_name" {
  type        = string
  default     = "multi-region-ec2"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID cụ thể"
}
```

#### 3. File outputs: [outputs.tf](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/terraform/lab-06-multi-provider-module/modules/simple-ec2/outputs.tf)
Xuất thông tin IP và vùng Availability Zone (ví dụ: `ap-southeast-1a` hoặc `us-east-1a`) để kiểm tra tính chính xác:
```hcl
output "instance_id" {
  value       = aws_instance.this.id
}

output "public_ip" {
  value       = aws_instance.this.public_ip
}

output "availability_zone" {
  value       = aws_instance.this.availability_zone
}
```

---

### Bước 3: Thiết lập Root Module (lab-06-multi-provider-module)

#### 1. Định nghĩa Variables ở Root: [variables.tf](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/terraform/lab-06-multi-provider-module/variables.tf)
Khai báo đầy đủ các biến cho 2 khu vực khác nhau:
```hcl
variable "aws_region_sg" {
  type    = string
  default = "ap-southeast-1"
}

variable "aws_region_us" {
  type    = string
  default = "us-east-1"
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

variable "ami_sg" {
  type    = string
  default = "ami-0543dbdaf4e114be7" # Amazon Linux 2023 tại Singapore
}

variable "ami_us" {
  type    = string
  default = "ami-00c39f71452c08778" # Amazon Linux 2023 tại US East (N. Virginia)
}

variable "subnet_id_sg" {
  type        = string
  description = "Subnet ID tại Singapore"
}

variable "subnet_id_us" {
  type        = string
  description = "Subnet ID tại US East"
}
```

#### 2. Cấu hình Providers & Gọi Module: [main.tf](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/terraform/lab-06-multi-provider-module/main.tf)
Chúng ta khai báo 2 block `provider "aws"`, một cái mặc định và một cái có `alias = "us_east"`. Sau đó khi gọi `module.ec2_us_east` ta truyền provider này vào:
```hcl
# Default AWS Provider (Singapore)
provider "aws" {
  region     = var.aws_region_sg
  access_key = var.access_key
  secret_key = var.secret_key
  token      = var.session_token
}

# Alias AWS Provider (US East)
provider "aws" {
  alias      = "us_east"
  region     = var.aws_region_us
  access_key = var.access_key
  secret_key = var.secret_key
  token      = var.session_token
}

# Deploy EC2 ở Singapore (kế thừa ngầm định provider mặc định)
module "ec2_singapore" {
  source        = "./modules/simple-ec2"
  ami           = var.ami_sg
  instance_type = "t3.micro"
  instance_name = "cuong-sg-instance"
  subnet_id     = var.subnet_id_sg
}

# Deploy EC2 ở Mỹ (chỉ định rõ sử dụng provider alias us_east)
module "ec2_us_east" {
  source        = "./modules/simple-ec2"
  ami           = var.ami_us
  instance_type = "t2.micro"
  instance_name = "cuong-us-instance"
  subnet_id     = var.subnet_id_us

  providers = {
    aws = aws.us_east
  }
}
```

#### 3. In kết quả hiển thị: [outputs.tf](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/terraform/lab-06-multi-provider-module/outputs.tf)
```hcl
output "singapore_instance_ip" {
  value       = module.ec2_singapore.public_ip
}

output "singapore_instance_az" {
  value       = module.ec2_singapore.availability_zone
}

output "us_east_instance_ip" {
  value       = module.ec2_us_east.public_ip
}

output "us_east_instance_az" {
  value       = module.ec2_us_east.availability_zone
}
```

---

## 5. Thực Thi & Kiểm Tra Kết Quả

1. **Tạo file `terraform.tfvars` ở Root:**
   Điền đầy đủ ID của các Subnet tương ứng với cả 2 region trong tài khoản AWS của bạn:
   ```hcl
   subnet_id_sg = "subnet-xxxxxxxxxxxxxxxxx" # Subnet ID Singapore
   subnet_id_us = "subnet-yyyyyyyyyyyyyyyyy" # Subnet ID US East (N. Virginia)
   ```
2. **Khởi tạo và tải module:**
   ```bash
   terraform init
   ```
3. **Thực thi tạo hạ tầng:**
   ```bash
   terraform apply -var-file="../secrets.tfvars" -auto-approve
   ```
4. **Kiểm tra output:**
   Bạn sẽ thấy output in ra địa chỉ IP công cộng và đặc biệt là Availability Zone:
   * Một instance sẽ nằm ở `ap-southeast-1x` (Singapore).
   * Instance còn lại sẽ nằm ở `us-east-1x` (Mỹ).
   Điều này chứng minh module đã hoạt động đa vùng thành công thông qua cấu hình provider alias!
5. **Hủy tài nguyên:**
   ```bash
   terraform destroy -var-file="../secrets.tfvars" -auto-approve
   ```
