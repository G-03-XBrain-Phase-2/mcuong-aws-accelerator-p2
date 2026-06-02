# Hướng Dẫn Quản Lý Đa Tài Khoản AWS & Cấu Hình Backend Động Trong Terraform

Khi học tập và làm việc thực tế với Terraform, bạn sẽ thường xuyên đối mặt với hai thách thức lớn:
1. **Sử dụng song song nhiều tài khoản AWS** trên cùng một máy tính (ví dụ: một tài khoản trả phí của công ty/cá nhân làm mặc định và một tài khoản Free Tier dùng để học tập).
2. **Khối cấu hình `backend "s3"` không hỗ trợ biến HCL** (`var.access_key`, `var.secret_key`), dẫn đến việc không thể xác thực trực tiếp bằng code động.

Dưới đây là hướng dẫn chi tiết về **2 giải pháp chuyên nghiệp** để giải quyết triệt để vấn đề này, giúp bạn có thêm nhiều cách thực hành đa dạng.

---

## 🛠️ GIẢI PHÁP 1: Cấu Hình Backend Động (`-backend-config`)

Vì khối `backend` được biên dịch trước khi nạp các biến, bạn không thể sử dụng cú pháp `var.xxx` bên trong nó. Thay vào đó, chúng ta có thể truyền tham số động từ bên ngoài lúc khởi tạo (`terraform init`).

### Cách A: Truyền trực tiếp qua dòng lệnh (CLI inline)
Khi chạy lệnh khởi tạo, bạn truyền thẳng cặp Key của tài khoản Free Tier vào tham số `-backend-config`:
```bash
terraform init \
  -backend-config="access_key=AKIA_FREE_TIER_KEY" \
  -backend-config="secret_key=SECRET_FREE_TIER_KEY"
```

### Cách B: Sử dụng file cấu hình Backend riêng (`backend.hcl` - Khuyên dùng cho sạch code)
Để tránh việc phải gõ các Key dài dòng trực tiếp trên Terminal (dễ bị lộ log màn hình), bạn có thể lưu thông tin vào một file cấu hình độc lập.

1. **Bước 1:** Tạo một file có tên là `backend.hcl` đặt ở thư mục cha `practice/terraform/backend.hcl`:
   ```hcl
   # File: practice/terraform/backend.hcl
   access_key = "AKIA_TAI_KHOAN_FREE_TIER"
   secret_key = "SECRET_KEY_TAI_KHOAN_FREE_TIER"
   ```
   *(Nhớ đảm bảo file này đã được thêm vào `.gitignore` để tránh bị lộ lên GitHub).*

2. **Bước 2:** Khi đứng ở thư mục lab con (ví dụ `lab-01-first-ec2/`), bạn chỉ cần chạy lệnh nạp file cấu hình này:
   ```bash
   terraform init -backend-config="../backend.hcl" -reconfigure
   ```
   > [!TIP]
   > **Tại sao cần dùng `-reconfigure`?**
   > Khi bạn thay đổi cấu hình Backend hoặc gặp lỗi khởi tạo lửng trước đó, Terraform sẽ lưu lại cache cấu hình cũ trong thư mục ẩn `.terraform/`. 
   > Thêm cờ `-reconfigure` giúp bảo Terraform bỏ qua toàn bộ bản nháp/cache cũ bị lỗi và thiết lập cấu hình mới tinh từ file `backend.hcl` của bạn một cách an toàn.

* **Ưu điểm:** Tách biệt hoàn toàn thông tin xác thực backend ra khỏi file code chính, giúp code sạch sẽ và an toàn.

---

## 🏆 GIẢI PHÁP 2: Sử Dụng AWS Named Profiles (Giải Pháp Chuẩn Doanh Nghiệp)

Đây là giải pháp **đỉnh cao và chuyên nghiệp nhất** khi làm việc đa tài khoản. Thay vì phải truyền key qua dòng lệnh hay tạo file cấu hình phụ, bạn đăng ký trực tiếp tài khoản Free Tier vào danh sách cấu hình hệ thống của AWS CLI.

### Bước 1: Đăng ký Profile mới cho tài khoản Free Tier
Mở Terminal của bạn lên và chạy lệnh cấu hình AWS kèm cờ `--profile`:
```bash
aws configure --profile free-tier
```
Hệ thống sẽ yêu cầu bạn nhập các thông tin xác thực của tài khoản Free Tier:
* **AWS Access Key ID:** Nhập Key Free Tier của bạn.
* **AWS Secret Access Key:** Nhập Secret Key Free Tier của bạn.
* **Default region name:** `ap-southeast-1` (Vùng thực hành của bạn).
* **Default output format:** `json`

*(Lúc này, máy tính của bạn sẽ lưu song song 2 tài khoản: tài khoản mặc định cũ và tài khoản tên là `free-tier` mới).*

### Bước 2: Khai báo sử dụng Profile trong code Terraform
Bây giờ, trong các file code `.tf` của bạn, bạn hoàn toàn **không cần khai báo các biến `access_key` hay `secret_key` nữa**. Bạn chỉ cần trỏ thẳng tên Profile mong muốn:

```hcl
# 1. Cấu hình Backend sử dụng Profile free-tier để xác thực S3
terraform {
  backend "s3" {
    bucket  = "mcuong-terraform-state"
    key     = "w8/terraform.tfstate"
    region  = "ap-southeast-1"
    profile = "free-tier" # <--- SỬ DỤNG PROFILE NÀY
    encrypt = true
  }
}

# 2. Cấu hình Provider sử dụng Profile free-tier để tạo tài nguyên
provider "aws" {
  region  = "ap-southeast-1"
  profile = "free-tier" # <--- SỬ DỤNG PROFILE NÀY
}

# 3. Khai báo tài nguyên bình thường
resource "aws_instance" "myec2" {
  ami           = "ami-0543dbdaf4e114be7"
  instance_type = "t3.micro"
}
```

### Bước 3: Khởi chạy siêu đơn giản
Vì mọi thông tin xác thực đã được AWS CLI và Terraform ngầm hiểu thông qua tên Profile `free-tier`, bạn chỉ cần chạy các lệnh cực kỳ sạch sẽ và rảnh tay:
```bash
terraform init
terraform plan
terraform apply
```

* **Ưu điểm:**
  * Giải pháp an toàn nhất, hoàn toàn loại bỏ nguy cơ lộ Access Key/Secret Key trong code và log Terminal.
  * Tốc độ gõ lệnh nhanh nhất.
  * Chuẩn hóa quy trình làm việc thực tế tại các doanh nghiệp lớn khi phân tách các tài khoản `dev`, `staging`, `prod`.
