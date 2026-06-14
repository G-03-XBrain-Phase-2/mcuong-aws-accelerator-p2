# Chuyên đề 1: Cơ bản & Cú pháp HCL (Basics & HCL)

> [!NOTE] 💡
> Tài liệu này được tổng hợp và cập nhật dựa trên lộ trình HashiCorp Certified: Terraform Associate 2026 (Udemy). Tập trung vào các Module 28, 29, 30, 32 và 37.

---

## 1. IaC & Cách hoạt động của Terraform

- **Declarative (Khai báo):** Chúng ta định nghĩa **trạng thái mong muốn (Desired State)** của hệ thống, Terraform sẽ tự động tính toán các bước để đưa hệ thống thực tế về trạng thái đó. (Khác với *Imperative - Mệnh lệnh* - chỉ ra từng bước chạy).
- **Idempotent (Đồng nhất):** Chạy lệnh nhiều lần với cùng một cấu hình sẽ cho ra cùng một kết quả, không tạo ra tài nguyên trùng lặp thừa thãi.

---

## 2. Resource and Providers (Module 28)

Terraform hoạt động dựa trên mô hình Plugin. **Providers** chính là các plugin giúp Terraform giao tiếp với API của các nền tảng Cloud hoặc các dịch vụ SaaS.

```
[ Cấu hình .tf ]  --->  [ Terraform Core ]  --->  [ AWS Provider (Plugin) ]  --->  [ AWS API ]
```

- **Resource Block:** Định nghĩa tài nguyên cụ thể cần được quản lý.
  - Cú pháp: `resource "<resource_type>" "<resource_local_name>"`
  - `resource_type` được định nghĩa bởi Provider (ví dụ: `aws_instance`).
  - `resource_local_name` là tên biến nội bộ chỉ dùng để tham chiếu chéo trong code Terraform.
- **Provider Block:** Khai báo và cấu hình cách kết nối tới nhà cung cấp.

```hcl
# 1. Khai báo Provider
provider "aws" {
  region = "ap-southeast-1"
}

# 2. Khai báo Resource sử dụng Provider phía trên
resource "aws_instance" "web_server" {
  ami           = "ami-0543dbdaf4e114be7"
  instance_type = "t3.micro"
}
```

---

## 3. Provider Tiers - Phân cấp Provider (Module 29)

Trên trang **Terraform Registry**, các Provider được chia làm 3 phân cấp (Tiers) dựa trên nhà phát triển và bảo trì:

| Cấp độ (Tier) | Nhà phát triển & Bảo trì | Ví dụ tiêu biểu |
| --- | --- | --- |
| **Official** | Được phát triển, bảo trì và sở hữu trực tiếp bởi **HashiCorp**. | `aws`, `gcp`, `kubernetes`, `vault`, `local` |
| **Partner** | Được phát triển và duy trì bởi các **công ty đối tác** có sự chứng nhận của HashiCorp. | `datadog`, `cloudflare`, `mongodbatlas`, `gitlab` |
| **Community** | Được phát triển và bảo trì bởi các **cá nhân hoặc cộng đồng** nguồn mở. | `linode`, `proxmox`, `spotify` |

---

## 4. Thực hành: Tạo GitHub Repository qua Terraform (Module 30)

Terraform không chỉ quản lý Cloud (AWS, GCP) mà còn có thể quản lý các dịch vụ khác như GitHub, Docker, Kubernetes. Dưới đây là ví dụ cấu hình tạo Repo GitHub bằng Terraform:

```hcl
# Khai báo yêu cầu sử dụng Provider GitHub
terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

# Cấu hình Token kết nối đến GitHub
provider "github" {
  token = "ghp_xxxxxxxxxxxxxxxxxxxxxx" # Personal Access Token của bạn
}

# Khai báo tạo một Repository mới
resource "github_repository" "my_repo" {
  name        = "my-terraform-practice"
  description = "Repository được tạo tự động bởi Terraform"
  visibility  = "public"
  auto_init   = true
}
```

---

## 5. AWS Provider - Các cơ chế cấu hình Authentication (Module 32)

Để Terraform có quyền tạo tài nguyên trên AWS, bạn cần cung cấp thông tin xác thực. Có 4 cách cấu hình phổ biến:

### Cách 1: Static Credentials (Hardcoded - KHÔNG KHUYÊN DÙNG)

Ghi trực tiếp Access Key và Secret Key vào code.

- **Nguy hiểm:** Rất dễ bị lộ thông tin nhạy cảm khi đẩy code lên Git.

```hcl
provider "aws" {
  region     = "ap-southeast-1"
  access_key = "AKIAXXXXXXXXXXXXXX"
  secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
}
```

### Cách 2: Environment Variables (Biến môi trường - KHUYÊN DÙNG khi chạy Local)

Terraform tự động tìm kiếm các biến môi trường hệ thống. Bạn chỉ cần cấu hình trong Terminal:

```bash
export AWS_ACCESS_KEY_ID="AKIAXXXXXXXXXXXXXX"
export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
export AWS_DEFAULT_REGION="ap-southeast-1"
```

Trong code Terraform chỉ cần viết:

```hcl
provider "aws" {} # Không cần khai báo credentials bên trong
```

### Cách 3: Shared Credentials File (Dùng file cấu hình AWS CLI)

Terraform sẽ tự động đọc cấu hình từ file `~/.aws/credentials` (được sinh ra khi chạy lệnh `aws configure`).

```hcl
provider "aws" {
  shared_config_files      = ["~/.aws/config"]
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "default" # Tên profile trong AWS CLI
}
```

### Cách 4: IAM Role / Instance Profile / OIDC (Dành cho Production/CI-CD)

Nếu chạy Terraform trên một EC2 instance hoặc qua các pipeline như GitHub Actions (OIDC), bạn có thể gắn IAM Role trực tiếp cho môi trường đó mà không cần quản lý bất kỳ Access/Secret Key nào.

---

## 6. Quản lý Phiên Bản Provider - Provider Versioning (Module 37)

Trong dự án thực tế, bạn cần cố định phiên bản của các Provider nhằm tránh việc nhà phát triển cập nhật phiên bản mới làm hỏng cú pháp code cũ.

Chúng ta sử dụng khối `required_providers` bên trong khối cấu trúc `terraform {}`:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Chỉ định phiên bản
    }
  }
}
```

### Ý nghĩa của các toán tử phiên bản (Version Constraints):

- `version = "5.10.0"`: Khóa cứng đúng phiên bản `5.10.0`.
- `version = ">= 5.0"`: Cho phép tải bất kỳ phiên bản nào lớn hơn hoặc bằng `5.0`.
- `version = "~> 5.12.0"` **(Pessimistic Constraint - Hay dùng nhất):** Cho phép các bản vá lỗi (patch releases) từ `5.12.0` đến `< 5.13.0`.
- `version = "~> 5.0"`: Cho phép nâng cấp từ `5.0` đến `< 6.0` (Không nhảy sang major version tiếp theo để tránh breaking changes).

---

## 7. Các khối bổ trợ khác trong HCL

### A. Data Source Block

Truy vấn thông tin từ các tài nguyên đã tồn tại sẵn trên Cloud để sử dụng lại.

```hcl
data "aws_ami" "latest_ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
}
```

### B. Input/Output Variables & Locals

- **Input Variables:** Dùng để tham số hóa cấu hình (đầu vào của hàm).
- **Output Variables:** Xuất thông tin ra màn hình (giá trị trả về).
- **Locals:** Biến cục bộ dùng nội bộ trong file.