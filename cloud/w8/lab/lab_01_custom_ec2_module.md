# Lab 1: Tự Thiết Kế Custom Module Cho Máy Chủ EC2 & Security Group

## 1. Mục Tiêu Của Bài Lab
* Biết cách tự đóng gói tài nguyên AWS (ở đây là **EC2 Instance** và **Security Group**) thành một **Child Module** riêng biệt để tái sử dụng.
* Hiểu cách giao tiếp dữ liệu giữa Root Module và Child Module thông qua **Input Variables** và **Outputs**.
* Gọi module cục bộ thông qua đường dẫn cục bộ (Local Path).

---

## 2. Mô Hình Thiết Kế (Architecture)

```
[ Root Module (lab-05-custom-module) ]
    ├── variables.tf   (Khai báo input cho Root)
    ├── main.tf        (Gọi module "custom-ec2" và truyền tham số)
    ├── outputs.tf     (In ra Public IP nhận được từ Child Module)
    └── [ modules/custom-ec2 ]
            ├── variables.tf  (Định nghĩa các tham số đầu vào của Module)
            ├── main.tf       (Tạo SG cho phép Port 80, 22 & Tạo EC2 sử dụng SG này)
            └── outputs.tf    (Xuất ra Public IP, SG ID & Instance ID)
```

---

## 3. Các Bước Thực Hiện Step-by-Step

### Bước 1: Khởi tạo cấu trúc thư mục
Truy cập vào terminal và tạo cấu trúc thư mục cho bài Lab này:
```bash
cd /Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/terraform
mkdir -p lab-05-custom-module/modules/custom-ec2
```

### Bước 2: Thiết lập Child Module (modules/custom-ec2)

Trong thư mục `modules/custom-ec2`, tạo 3 file:

#### 1. Định nghĩa các tham số đầu vào: [variables.tf](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/terraform/lab-05-custom-module/modules/custom-ec2/variables.tf)
Chúng ta sẽ biến các giá trị cứng (như Subnet, VPC, AMI, Instance Type) thành biến đầu vào để Root Module truyền xuống:
```hcl
variable "ami" {
  type        = string
  description = "AMI ID của EC2"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "Kích thước của EC2 Instance"
}

variable "instance_name" {
  type        = string
  default     = "custom-ec2-instance"
  description = "Tên tag Name của instance"
}

variable "subnet_id" {
  type        = string
  description = "ID của Subnet sẽ đặt EC2"
}

variable "vpc_id" {
  type        = string
  description = "ID của VPC để tạo Security Group đi kèm"
}
```

#### 2. Khai báo tài nguyên chính: [main.tf](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/terraform/lab-05-custom-module/modules/custom-ec2/main.tf)
Module này sẽ tạo ra 1 Security Group mở cổng 80 (HTTP), 22 (SSH) và 1 EC2 Instance gắn với SG này:
```hcl
resource "aws_security_group" "web_sg" {
  name        = "${var.instance_name}-sg"
  description = "Security Group created by custom-ec2 module"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.instance_name}-sg"
  }
}

resource "aws_instance" "this" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name = var.instance_name
  }
}
```

#### 3. Xuất kết quả ra ngoài: [outputs.tf](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/terraform/lab-05-custom-module/modules/custom-ec2/outputs.tf)
Sau khi tạo xong, Module cần trả ngược lại các thông số để Root Module có thể sử dụng cho các việc khác:
```hcl
output "instance_id" {
  value       = aws_instance.this.id
  description = "ID của EC2 instance"
}

output "public_ip" {
  value       = aws_instance.this.public_ip
  description = "Địa chỉ IP public của EC2"
}

output "security_group_id" {
  value       = aws_security_group.web_sg.id
  description = "ID của Security Group vừa tạo"
}
```

---

### Bước 3: Thiết lập Root Module (lab-05-custom-module)

Di chuyển lên thư mục `lab-05-custom-module` và cấu hình gọi module:

#### 1. Định nghĩa Variables cho Root Module: [variables.tf](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/terraform/lab-05-custom-module/variables.tf)
Khai báo các biến xác thực AWS (nhằm hỗ trợ AWS Academy/Learner Lab nếu cần) và các biến đầu vào của bài thực hành:
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
  default     = "ami-0543dbdaf4e114be7" # Amazon Linux 2023 ở Singapore
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "instance_name" {
  type    = string
  default = "cuong-lab05-web"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID cụ thể để tránh lỗi multiple subnets"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID của subnet"
}
```

#### 2. Gọi Module: [main.tf](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/terraform/lab-05-custom-module/main.tf)
Chúng ta truyền các biến từ Root Module xuống Child Module:
```hcl
provider "aws" {
  region     = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key
  token      = var.session_token
}

module "my_web_server" {
  source        = "./modules/custom-ec2"
  ami           = var.ami
  instance_type = var.instance_type
  instance_name = var.instance_name
  subnet_id     = var.subnet_id
  vpc_id        = var.vpc_id
}
```

#### 3. Cấu hình Output tại Root: [outputs.tf](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/terraform/lab-05-custom-module/outputs.tf)
Chúng ta đón nhận các output của module `my_web_server` và hiển thị ra màn hình khi `terraform apply` kết thúc:
```hcl
output "web_server_ip" {
  value       = module.my_web_server.public_ip
  description = "Public IP in ra từ Module"
}

output "web_server_sg_id" {
  value       = module.my_web_server.security_group_id
  description = "Security Group ID in ra từ Module"
}
```

---

## 4. Thực Thi & Kiểm Tra Kết Quả

1. **Chuẩn bị file biến thực tế:**
   Tạo file `terraform.tfvars` ở Root (`lab-05-custom-module/terraform.tfvars`) để truyền các giá trị cụ thể phù hợp với tài khoản AWS của bạn:
   ```hcl
   subnet_id = "subnet-xxxxxxxxxxxxxxxxx" # Lấy ID Subnet từ AWS của bạn
   vpc_id    = "vpc-xxxxxxxxxxxxxxxxx"    # Lấy ID VPC chứa subnet đó
   ```
2. **Khởi tạo và Tải module:**
   ```bash
   terraform init
   ```
   > [!NOTE]
   > Hãy chú ý đầu ra của lệnh `init`. Terraform sẽ hiển thị:
   > `- my_web_server in modules/custom-ec2`
   > Lệnh này sẽ copy và liên kết code của module cục bộ vào thư mục ẩn `.terraform`.
3. **Kiểm tra và thực thi:**
   * Kiểm tra cú pháp: `terraform validate`
   * Xem trước kế hoạch: `terraform plan -var-file="../secrets.tfvars"` (nếu bạn để credentials trong file secrets chung)
   * Tạo tài nguyên: `terraform apply -var-file="../secrets.tfvars" -auto-approve`
4. **Xác minh đầu ra:**
   * Xem giá trị in ra màn hình từ Output của module.
   * Chạy lệnh `curl <PUBLIC_IP_IN_RA>` để kiểm tra kết nối (nếu máy chủ đã cài đặt nginx/web server).
5. **Dọn dẹp tài nguyên:**
   ```bash
   terraform destroy -var-file="../secrets.tfvars" -auto-approve
   ```
