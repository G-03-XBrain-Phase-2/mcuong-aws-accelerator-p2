# Chuyên đề 3: Thiết kế Module & Quản lý Workspace trong Terraform

Tài liệu này tổng hợp toàn bộ kiến thức cốt lõi về **Terraform Modules** (Section 6 trong khóa học Terraform Associate) và **Terraform Workspaces** (quản lý đa môi trường).

---

## 1. Root Module vs Child Module

Trong Terraform, bất kỳ cấu hình nào chạy trong thư mục chứa các file `.tf` đều liên quan đến các module.

```
[ Root Module ] (Nơi chạy terraform apply)
       ||
       ||===> Gọi [ Child Module A ] (ví dụ: ./modules/ec2)
       ||
       ||===> Gọi [ Child Module B ] (ví dụ: terraform-aws-modules/vpc/aws)
```

- **Root Module (Module Gốc):** Là thư mục làm việc hiện tại của bạn, nơi bạn trực tiếp thực thi các câu lệnh như `terraform init`, `terraform plan`, và `terraform apply`.
- **Child Module (Module Con):** Là các module được gọi từ bên trong Root Module (hoặc từ các module con khác) thông qua block `module` để tái sử dụng tài nguyên hạ tầng.
- **Luồng dữ liệu giữa các Module:**
  - **Input Variables:** Dùng để truyền dữ liệu từ Root Module vào Child Module (như các tham số đầu vào).
  - **Outputs:** Dùng để xuất dữ liệu từ Child Module ngược trở ra Root Module (ví dụ: lấy IP của EC2 vừa tạo để truyền vào một tài nguyên khác ở Root Module).

---

## 2. Cấu Trúc Thư Mục Module Chuẩn (Standard Module Structure)

HashiCorp khuyến nghị cấu trúc thư mục tối thiểu cho một module như sau:

```text
terraform-aws-custom-ec2/  # Tên thư mục chứa module (hoặc repo Git)
├── README.md              # Tài liệu hướng dẫn sử dụng module (inputs, outputs)
├── main.tf                # Khai báo các tài nguyên chính của module
├── variables.tf           # Định nghĩa các biến đầu vào (Inputs)
├── outputs.tf             # Định nghĩa các giá trị xuất ra (Outputs)
├── providers.tf           # Định nghĩa các yêu cầu về provider (required_providers)
└── LICENSE                # Giấy phép bản quyền (nếu công khai)
```

> [!NOTE] 💡
> Cấu trúc này giúp cô lập logic của module, làm cho mã nguồn dễ đọc và dễ bảo trì hơn khi chia sẻ trong nội bộ hoặc đẩy lên registry.

---

## 3. Cách Gọi Module & Nguồn Module (Module Sources)

Để gọi một module, bạn sử dụng block `module` ở Root Module. Tham số bắt buộc duy nhất là `source`.

### Các nguồn Module (Module Sources) phổ biến:

#### A. Đường dẫn cục bộ (Local Paths)

Thích hợp cho các module nội bộ nằm chung trong một dự án. Đường dẫn bắt đầu bằng `./` hoặc `../`.

```hcl
module "my_ec2" {
  source     = "./modules/aws-ec2"
  instance_type = "t3.micro"
}
```

#### B. Terraform Registry

Các module được cộng đồng hoặc AWS phát triển sẵn và công khai trên Registry của HashiCorp. Cú pháp ngắn gọn: `<NAMESPACE>/<NAME>/<PROVIDER>`.

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0" # Nên cố định phiên bản để tránh lỗi bất ngờ khi module nâng cấp
}
```

#### C. GitHub / Git Repositories

Tải code trực tiếp từ các kho lưu trữ Git qua giao thức HTTPS hoặc SSH.

- **HTTPS:** `github.com/hashicorp/example`
- **SSH:** `git@github.com:hashicorp/example.git`
- **Chọn nhánh/tag cụ thể (Cực kỳ quan trọng):** Sử dụng tham số `ref` ở cuối đường dẫn.

  ```hcl
  module "app_server" {
    source = "git::https://github.com/example/terraform-modules.git//modules/ec2?ref=v1.2.0"
  }
  ```

  *(Lưu ý: Ký tự* `//` *dùng để trỏ vào thư mục con bên trong kho lưu trữ Git).*

#### D. S3 Buckets hoặc HTTP URLs

Tải các file nén (`.zip`, `.tar.gz`) chứa module từ S3 hoặc một URL cụ thể.

```hcl
module "s3_archive" {
  source = "s3::https://s3-ap-southeast-1.amazonaws.com/my-terraform-modules/ec2.zip"
}
```

---

## 4. Thiết Kế & Cải Tiến Custom Module

Khi xây dựng một Custom Module (ví dụ cho máy chủ EC2), bạn nên tuân thủ quy trình cải tiến mã nguồn để đảm bảo tính linh hoạt:

### Bước 1: Tránh viết cứng giá trị (Hardcoded Values)

Mọi thông số có khả năng thay đổi tùy theo môi trường (như `instance_type`, `ami`, `subnet_id`) phải được khai báo thành biến (`variable`) trong Child Module.

```hcl
# modules/custom-ec2/variables.tf
variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "Kích thước của máy chủ EC2"
}
```

### Bước 2: Tạo Output để truyền giá trị liên kết

Child module cần xuất ra các thông tin quan trọng để Root Module có thể sử dụng (ví dụ: ID của Security Group, Public IP của EC2).

```hcl
# modules/custom-ec2/outputs.tf
output "instance_public_ip" {
  value       = aws_instance.this.public_ip
  description = "Địa chỉ IP public của máy chủ vừa tạo"
}
```

Ở Root Module, bạn gọi giá trị này bằng cú pháp: `module.<MODULE_NAME>.<OUTPUT_NAME>`

```hcl
resource "aws_route53_record" "www" {
  zone_id = var.zone_id
  name    = "www.example.com"
  type    = "A"
  ttl     = 300
  records = [module.my_ec2.instance_public_ip] # Lấy output từ module
}
```

---

## 5. Cấu Hình Provider Trong Module (Provider Configuration)

### 5.1. Cơ chế kế thừa Provider mặc định (Implicit Inheritance)

Theo mặc định, Child Module sẽ tự động kế thừa cấu hình provider mặc định (default provider) từ Root Module. Nếu ở Root Module bạn khai báo:

```hcl
provider "aws" {
  region = "ap-southeast-1"
}
```

Thì tất cả tài nguyên trong Child Module cũng sẽ tự động được tạo ở region `ap-southeast-1` mà không cần cấu hình thêm.

### 5.2. Cấu hình đa Provider (Multiple Provider Configuration)

Trong trường hợp bạn cần tạo tài nguyên ở nhiều vùng/tài khoản AWS khác nhau từ cùng một module (ví dụ: EC2 ở cả Singapore và Mỹ), bạn cần sử dụng **Provider Alias** và truyền tường minh vào module:

- **Tại Root Module:** Khai báo các provider với `alias`:

  ```hcl
  provider "aws" {
    region = "ap-southeast-1" # Default provider
  }
  
  provider "aws" {
    alias  = "us_east"
    region = "us-east-1"      # Provider cho vùng US
  }
  ```
- **Khi gọi Module từ Root Module:** Truyền provider mong muốn qua tham số `providers`:

  ```hcl
  module "ec2_singapore" {
    source = "./modules/custom-ec2"
    # Kế thừa ngầm định default provider (Singapore)
  }
  
  module "ec2_us" {
    source = "./modules/custom-ec2"
    providers = {
      aws = aws.us_east # Gán provider alias vào provider mặc định bên trong module
    }
  }
  ```

---

## 6. Điều Kiện Để Publish Module Lên Terraform Registry

Để công khai một module lên Terraform Registry phục vụ cho cộng đồng sử dụng, module của bạn phải đáp ứng các tiêu chí nghiêm ngặt sau:

1. **GitHub Repository Công Khai (Public):** Module phải được lưu trữ trên một repo GitHub công khai.
2. **Quy tắc đặt tên kho lưu trữ (Naming Convention):** Tên repo Git phải có định dạng chính xác: `terraform-<PROVIDER>-<NAME>`*(Ví dụ:* `terraform-aws-custom-ec2`*)*.
3. **Cấu trúc thư mục chuẩn:** Phải có đầy đủ `main.tf`, `variables.tf`, `outputs.tf` và file hướng dẫn `README.md`.
4. **Gắn Tag phiên bản (Semantic Versioning):** Phải tạo release tag trên Git theo chuẩn `vX.Y.Z` (ví dụ: `v1.0.0`, `v1.1.0`). Terraform Registry dựa hoàn toàn vào các tag này để quản lý phiên bản module.

---

## 7. Tổng Quan Về Terraform Workspaces

### 7.1. Khái niệm Workspace là gì?

Mặc định, Terraform khởi tạo một workspace có tên là `default`. Một workspace đại diện cho một trạng thái hạ tầng tách biệt (một file `terraform.tfstate` riêng). Sử dụng Workspace giúp bạn chạy **cùng một bộ code Terraform** nhưng tạo ra các môi trường khác nhau (ví dụ: `dev`, `staging`, `prod`) mà không lo bị ghi đè hay xung đột file state.

```
[ Dự án Terraform của bạn ]
       ||
       ||===> Workspace: default ===> (Lưu trong terraform.tfstate gốc)
       ||
       ||===> Workspace: dev     ===> (Lưu trong .terraform.tfstate.d/dev/terraform.tfstate)
       ||
       ||===> Workspace: prod    ===> (Lưu trong .terraform.tfstate.d/prod/terraform.tfstate)
```

### 7.2. Các câu lệnh Workspace quan trọng

- `terraform workspace list`: Liệt kê tất cả các workspace hiện có. Dấu `*` hiển thị workspace hiện tại.
- `terraform workspace new <name>`: Tạo một workspace mới và tự động chuyển sang workspace đó.
- `terraform workspace select <name>`: Chuyển đổi môi trường sang workspace khác.
- `terraform workspace show`: Hiển thị tên workspace hiện hành.
- `terraform workspace delete <name>`: Xóa một workspace (chỉ xóa được khi không đứng ở workspace đó và workspace phải trống tài nguyên).

### 7.3. Sử dụng biến `${terraform.workspace}` động trong Code

Bạn có thể lập trình cấu hình động dựa trên tên workspace hiện tại:

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0543dbdaf4e114be7"
  # Nếu là workspace "prod" thì dùng t3.medium, ngược lại dùng t3.micro cho dev
  instance_type = terraform.workspace == "prod" ? "t3.medium" : "t3.micro"

  tags = {
    Name = "web-server-${terraform.workspace}"
  }
}
```

> [!CAUTION] 🛑
> Hạn chế của Workspaces trong môi trường Production thực tế: Thiếu cô lập tuyệt đối: Các workspace dùng chung một backend cấu hình. Nếu cấu hình sai quyền, người dùng ở môi trường dev có thể vô tình thao tác nhầm sang môi trường prod. Rủi ro dọn dẹp (Cleanup): Lệnh terraform destroy sẽ xóa sạch tài nguyên của workspace hiện tại. Nếu bạn quên chưa chuyển sang workspace dev mà chạy destroy khi đang ở prod, toàn bộ hạ tầng production sẽ biến mất. * Thực tế doanh nghiệp: Hầu hết các doanh nghiệp lớn thường phân chia môi trường bằng cấu trúc thư mục vật lý (file-based isolation) kết hợp với các tài khoản AWS riêng biệt thay vì lạm dụng Workspace để đảm bảo an toàn tối đa.

