# Hướng Dẫn Quản Lý Biến Nhạy Cảm & Thông Tin Xác Thực (Credentials) Trong Terraform

Khi làm việc với các hệ thống Cloud như AWS hay dịch vụ SaaS như GitHub, việc quản trị các thông tin nhạy cảm (như API Access Tokens, AWS Access Keys) là cực kỳ quan trọng. 

Dưới đây là hướng dẫn chi tiết về **3 giải pháp lưu trữ biến nhạy cảm dùng chung** cho cấu trúc nhiều lab con mà không cần lặp lại cấu hình ở từng thư mục, trong đó **Cách 1 (Dùng file `.tfvars` bản xứ)** là cách được ưu tiên hàng đầu dành cho người học và thi chứng chỉ Terraform.

---

## 🌟 CÁCH 1: Sử Dụng File Biến Bản Xứ Của Terraform (`.tfvars` - ƯU TIÊN HÀNG ĐẦU)

Đây là cơ chế chính thống của Terraform để truyền tham số đầu vào. Nó giúp bạn hiểu sâu sắc về cách khai báo và truyền biến (`variables`) trong HCL.

### Cấu trúc tổ chức file:
```
practice/terraform/
├── secrets.tfvars               <-- LƯU DUY NHẤT 1 FILE BIẾN CHUNG Ở ĐÂY
├── lab-01-first-ec2/
└── lab-02-github-repo/
    └── github-repo.tf           <-- File code chính của Lab 2
```

### Các bước thực hiện:

#### Bước 1: Khai báo biến và gán vào Provider trong code `.tf`
Trong file code thực hành của bạn, không ghi cứng token nữa. Thay vào đó hãy khai báo nó thông qua khối `variable`:

```hcl
# File: practice/terraform/lab-02-github-repo/github-repo.tf

# 1. Khai báo biến nhạy cảm
variable "github_token" {
  type        = string
  description = "Token kết nối đến GitHub"
  sensitive   = true # Báo Terraform không in giá trị này ra log màn hình
}

# 2. Gán biến vào Provider
provider "github" {
  token = var.github_token
}
```

#### Bước 2: Tạo file lưu thông tin nhạy cảm dùng chung ở thư mục gốc
Tạo file **`secrets.tfvars`** nằm ở thư mục cha `practice/terraform/` và điền giá trị bí mật của bạn:

```hcl
# File: practice/terraform/secrets.tfvars
github_token = "ghp_chuoi_token_github_cua_ban_o_day"
```

#### Bước 3: Thực thi lệnh và trỏ đường dẫn file biến ra thư mục cha (`../`)
Khi bạn đang đứng ở thư mục con (ví dụ `lab-02-github-repo`), hãy chạy lệnh kèm theo tham số `-var-file` hướng ra ngoài:

```bash
# Di chuyển vào lab con
cd lab-02-github-repo/

# Chạy lệnh nạp file biến từ thư mục cha
terraform plan -var-file="../secrets.tfvars"
terraform apply -var-file="../secrets.tfvars"
```

* **Ưu điểm:**
  * Thuần túy Terraform, rất dễ học, dễ hiểu cách truyền biến.
  * Phục vụ trực tiếp cho kỳ thi **HashiCorp Certified: Terraform Associate**.
  * Rất an toàn vì file `secrets.tfvars` đã nằm trong danh sách `.gitignore` nên không sợ bị lộ lên GitHub.

---

## CÁCH 2: Sử Dụng Duy Nhất Một File `.env` Ở Thư Mục Gốc

Giải pháp này sử dụng các biến môi trường hệ thống. Bạn chỉ cần viết duy nhất 1 file cấu hình ở thư mục cha và nạp nó vào Terminal.

### Cấu trúc tổ chức file:
```
practice/terraform/
├── .env                         <-- CHỈ CẦN 1 FILE CHUNG Ở ĐÂY
├── lab-01-first-ec2/
└── lab-02-github-repo/
```

### Các bước thực hiện:

#### Bước 1: Tạo file `.env` ở thư mục cha
```bash
# File: practice/terraform/.env
export GITHUB_TOKEN="ghp_chuoi_token_cua_ban_o_day"
export AWS_ACCESS_KEY_ID="AKIAXXXXXXXXXXXX"
export AWS_SECRET_ACCESS_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

#### Bước 2: Nạp biến môi trường từ thư mục con
Khi mở Terminal thực hành tại thư mục con `lab-02-github-repo/`, bạn gõ lệnh nạp biến trỏ ra thư mục cha:
```bash
source ../.env
```

#### Bước 3: Chạy lệnh Terraform bình thường
Code `.tf` lúc này chỉ cần khai báo provider trống, Terraform sẽ tự động dò tìm biến môi trường trong bộ nhớ của Terminal hiện tại để thực thi:
```hcl
provider "github" {
  # Tự động đọc biến môi trường GITHUB_TOKEN
}
```

* **Ưu điểm:** Không cần khai báo biến `variable` trong code, cực kỳ tiện lợi khi làm việc với nhiều Provider khác nhau.

---

## CÁCH 3: Tự Động Hóa Dùng Chung Với Công Cụ `direnv`

Đây là cách nâng cao được sử dụng phổ biến bởi các Cloud/DevOps Engineer trong các dự án lớn thực tế để hoàn toàn rảnh tay.

### Các bước thực hiện:

#### Bước 1: Cài đặt công cụ `direnv` trên máy Mac
```bash
brew install direnv
```
*(Sau đó tích hợp `direnv` vào shell `zsh` trên máy theo tài liệu hướng dẫn của direnv).*

#### Bước 2: Tạo duy nhất một file `.envrc` ở thư mục cha
Tạo file `practice/terraform/.envrc`:
```bash
export GITHUB_TOKEN="ghp_chuoi_token_cua_ban_o_day"
export AWS_ACCESS_KEY_ID="AKIAXXXXXXXXXXXX"
export AWS_SECRET_ACCESS_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

#### Bước 3: Cấp quyền cho direnv
Chạy lệnh này duy nhất một lần tại thư mục cha:
```bash
direnv allow
```

#### Bước 4: Tận hưởng sự tự động hóa
Kể từ giờ, mỗi khi bạn mở Terminal và dùng lệnh `cd` vào bất kỳ thư mục con nào (`lab-01-first-ec2`, `lab-02-github-repo`), `direnv` sẽ tự động kích hoạt nạp toàn bộ các biến môi trường của thư mục cha vào Terminal của bạn. Không cần gõ bất cứ lệnh gì khác!

---

## 🛡️ TỔNG KẾT NGUYÊN TẮC BẢO MẬT (QUAN TRỌNG)

Dù bạn chọn cách nào, hãy luôn tuân thủ nguyên tắc:
1. **Tuyệt đối không commit các file bí mật:** Các file như `.env`, `.envrc`, và `secrets.tfvars` phải luôn được ghi nhận trong file `.gitignore` của dự án để tránh đẩy lên GitHub.
2. **Sử dụng `sensitive = true`:** Luôn thêm thuộc tính này vào các khai báo biến nhạy cảm trong Terraform để giá trị của chúng không bao giờ bị lộ ra màn hình Terminal hoặc các file log hệ thống.
