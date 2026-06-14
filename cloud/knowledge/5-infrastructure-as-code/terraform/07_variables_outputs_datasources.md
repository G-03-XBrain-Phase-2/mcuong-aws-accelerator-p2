# Chuyên đề 7: Input Variables, Output Values và Data Sources trong Terraform

Tài liệu này cung cấp hướng dẫn chi tiết kèm ví dụ thực tế về ba thành phần cốt lõi giúp tham số hóa, xuất dữ liệu và truy vấn tài nguyên trong Terraform: **Input Variables (Biến đầu vào)**, **Output Values (Giá trị đầu ra)**, và **Data Sources (Nguồn dữ liệu)**.

---

## 1. Input Variables (Biến đầu vào)

### 1.1. Khái niệm & Vai trò
**Input Variables** đóng vai trò giống như các tham số truyền vào một hàm số (parameter). Thay vì hardcode các giá trị cụ thể (như kích thước ổ đĩa, loại máy chủ, IP range), bạn khai báo biến để làm cho code Terraform linh hoạt, có thể tái sử dụng trên nhiều môi trường khác nhau (Dev, Staging, Prod).

### 1.2. Cấu trúc khai báo (HCL Syntax)
Một block variable bao gồm các thuộc tính sau:
*   `type`: Định nghĩa kiểu dữ liệu của biến (`string`, `number`, `bool`, `list`, `map`, `object`, `tuple`).
*   `default`: Giá trị mặc định nếu người dùng không truyền giá trị vào.
*   `description`: Mô tả ý nghĩa của biến (giúp tự động tạo tài liệu).
*   `sensitive`: Đặt thành `true` để ẩn giá trị biến khỏi log terminal khi chạy `plan`/`apply`.
*   `validation`: Ràng buộc điều kiện hợp lệ cho giá trị nhập vào.

#### Ví dụ khai báo biến:
```hcl
variable "aws_region" {
  type        = string
  default     = "ap-southeast-1"
  description = "Region triển khai tài nguyên AWS"
}

variable "db_password" {
  type        = string
  description = "Mật khẩu cho cơ sở dữ liệu RDS"
  sensitive   = true # Không hiển thị trên console log
}

variable "instance_config" {
  type = object({
    ami_id        = string
    instance_type = string
    disk_size_gb  = number
  })
  description = "Cấu hình chi tiết cho EC2 Instance"
  
  # Ví dụ Validation Block
  validation {
    condition     = startswith(var.instance_config.ami_id, "ami-")
    error_message = "AMI ID phải bắt đầu bằng tiền tố 'ami-'."
  }
}
```

### 1.3. Cách truyền giá trị cho Input Variables
Terraform tìm kiếm giá trị của biến theo thứ tự ưu tiên sau (từ cao xuống thấp):

1.  **Lệnh Command Line:** `-var="db_password=super-secret"`
2.  **File định nghĩa biến:** 
    *   Tự động load nếu trùng tên: `terraform.tfvars` hoặc `terraform.tfvars.json`
    *   Tự động load theo pattern: `*.auto.tfvars` hoặc `*.auto.tfvars.json`
    *   Chỉ định thủ công qua terminal: `-var-file="prod.tfvars"`
3.  **Biến môi trường hệ thống:** Sử dụng tiền tố `TF_VAR_` (ví dụ: `export TF_VAR_db_password="123"`).
4.  **Giá trị `default`:** Nếu không cung cấp bằng các cách trên, Terraform sẽ lấy giá trị mặc định được định nghĩa trong code.

#### Ví dụ file `terraform.tfvars`:
```hcl
aws_region  = "ap-southeast-1"
db_password = "MySecurePassword123!"
instance_config = {
  ami_id        = "ami-0543dbdaf4e114be7"
  instance_type = "t3.micro"
  disk_size_gb  = 20
}
```

---

## 2. Output Values (Giá trị đầu ra)

### 2.1. Khái niệm & Vai trò
**Output Values** tương tự như giá trị trả về (return value) của một hàm số. Chúng được sử dụng để:
*   **Hiển thị thông tin** quan trọng lên màn hình terminal sau khi chạy `terraform apply` thành công (như Public IP, DNS Endpoint).
*   **Truyền dữ liệu** từ một module con (child module) lên module cha (root module).
*   **Chia sẻ dữ liệu** giữa các dự án Terraform độc lập thông qua tính năng `terraform_remote_state`.

### 2.2. Cấu trúc khai báo (HCL Syntax)
Mỗi block output nhận diện một tên biến xuất và bắt buộc phải có thuộc tính `value`.

#### Ví dụ khai báo output:
```hcl
# Xuất địa chỉ IP công cộng của server
output "ec2_public_ip" {
  value       = aws_instance.my_server.public_ip
  description = "Địa chỉ IPv4 công cộng của EC2 Instance"
}

# Xuất kết quả nhạy cảm (ẩn khỏi terminal nhưng vẫn lưu trong State)
output "database_connection_string" {
  value       = "postgresql://${aws_db_instance.db.username}:${var.db_password}@${aws_db_instance.db.endpoint}"
  description = "Chuỗi kết nối database RDS"
  sensitive   = true # Ẩn giá trị khỏi terminal để bảo mật
}
```

> [!WARNING]
> Đánh dấu `sensitive = true` chỉ ẩn giá trị của output trên terminal. Giá trị này **vẫn được lưu dưới dạng plain text** trong file `terraform.tfstate`. Do đó, bạn cần quản lý file state một cách an toàn.

---

## 3. Data Sources (Nguồn dữ liệu)

### 3.1. Khái niệm & Vai trò
**Data Sources** cho phép Terraform truy cập và truy vấn thông tin từ các tài nguyên đã tồn tại sẵn bên ngoài Terraform (có thể do quản trị viên tạo bằng tay trên Console, hoặc do một hệ thống/project IaC khác tạo ra).

*   **Tính chất:** Chỉ đọc (**Read-only**). Data source không tạo mới, không chỉnh sửa hoặc xóa bất cứ tài nguyên nào.
*   **Phân biệt với Resource:** 
    *   `resource`: Khai báo tài nguyên Terraform cần **quản lý vòng đời** (Tạo/Sửa/Xóa).
    *   `data`: Truy vấn thông tin của tài nguyên **đang có sẵn** để lấy dữ liệu truyền vào resource khác.

### 3.2. Cấu trúc khai báo (HCL Syntax)
Cú pháp có dạng `data "<provider_type>" "<local_name>"`.

#### Ví dụ 1: Truy vấn AMI ID mới nhất của Ubuntu
Thay vì hardcode AMI ID (vốn thay đổi liên tục theo từng khu vực và thời gian), ta dùng data source để tự động tìm:
```hcl
data "aws_ami" "ubuntu_latest" {
  most_recent = true
  owners      = ["099720109477"] # ID của Canonical (chủ sở hữu Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Sử dụng dữ liệu truy vấn được trong resource:
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu_latest.id # Lấy ID từ data source trên
  instance_type = "t3.micro"
}
```

#### Ví dụ 2: Truy vấn thông tin về VPC có sẵn
Tìm một VPC có sẵn trên AWS thông qua Tag:
```hcl
data "aws_vpc" "existing_vpc" {
  filter {
    name   = "tag:Name"
    values = ["Production-VPC"]
  }
}

# Lấy ID của VPC này để tạo một Subnet mới
resource "aws_subnet" "new_subnet" {
  vpc_id            = data.aws_vpc.existing_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-southeast-1a"
}
```

---

## 4. Ví dụ tổng hợp (Full Integration Example)

Dưới đây là một kịch bản hoàn chỉnh sử dụng đồng thời **Input Variables**, **Data Source**, và **Output Values**:
1.  Nhận vùng triển khai từ `variable`.
2.  Dùng `data source` để tìm AMI Ubuntu mới nhất của vùng đó và tìm VPC mặc định.
3.  Tạo một EC2 Instance (`resource`) trong VPC đó.
4.  Xuất địa chỉ IP công cộng của EC2 và ARN của nó ra màn hình qua `output`.

```hcl
# ---- 1. PROVIDER ----
provider "aws" {
  region = var.target_region
}

# ---- 2. INPUT VARIABLES ----
variable "target_region" {
  type        = string
  default     = "ap-southeast-1"
  description = "Region để triển khai EC2 Instance"
}

variable "instance_size" {
  type        = string
  default     = "t3.micro"
  description = "Kích thước EC2 Instance"
}

# ---- 3. DATA SOURCES ----
# Lấy AMI Ubuntu 22.04 mới nhất
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Lấy thông tin VPC mặc định của AWS account ở region đó
data "aws_vpc" "default" {
  default = true
}

# ---- 4. RESOURCES ----
resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_size

  tags = {
    Name = "HelloWorld-AppServer"
  }
}

# ---- 5. OUTPUT VALUES ----
output "server_public_ip" {
  value       = aws_instance.app_server.public_ip
  description = "Địa chỉ IPv4 Public của máy chủ vừa tạo"
}

output "server_arn" {
  value       = aws_instance.app_server.arn
  description = "Amazon Resource Name (ARN) của máy chủ"
}
```
