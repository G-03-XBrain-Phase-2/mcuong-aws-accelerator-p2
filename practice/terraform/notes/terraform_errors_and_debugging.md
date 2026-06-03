# Nhật Ký Lỗi Terraform & Hướng Dẫn Sửa Lỗi (Debugging Guide)

Tài liệu này ghi lại các lỗi thường gặp trong quá trình làm việc với Terraform và AWS (đặc biệt là trong môi trường học tập như AWS Academy / AWS Learner Lab hoặc khi sử dụng Module), nguyên nhân sâu xa và cách khắc phục chi tiết.

---

## 1. Lỗi Cấu Hình AWS Region Nhầm Với Session Token

### Hiện tượng & Thông báo lỗi
Khi chạy `terraform plan` hoặc `terraform init`, bạn gặp lỗi:
```text
Error: Invalid provider configuration
Provider "registry.terraform.io/hashicorp/aws" requires explicit configuration. 
Add a provider block to the root module...

Error: invalid AWS Region: AWS Session Token [None]: IQoJb3JpZ2luX2VjEE8...
```

---

### Nguyên nhân sâu xa

#### 1.1. Chưa khai báo Block Provider
Khi sử dụng bất kỳ Module AWS nào (như `ec2-instance`), Terraform cần biết thông tin nhà cung cấp (AWS Provider) để khởi tạo tài nguyên. Nếu thư mục root chứa file chạy của bạn không có block `provider "aws"`, Terraform sẽ báo lỗi `Invalid provider configuration`.

#### 1.2. Giá trị Region bị gán nhầm thành Session Token
Khi bạn không định nghĩa rõ Region trong file `.tf`, Terraform sẽ tự động đọc từ môi trường của máy (Environment Variables) hoặc file cấu hình AWS (`~/.aws/config`). 

Lỗi `invalid AWS Region: AWS Session Token [None]: IQoJ...` xảy ra do **Session Token bị lưu đè vào cấu hình Region**. Nguyên nhân thường do:
* **Nhầm lẫn khi chạy `aws configure`:** Khi AWS CLI hỏi `Default region name [None]:`, bạn vô tình paste chuỗi *AWS Session Token* dài vào đây.
* **Copy-paste nhầm biến môi trường:** Trong AWS Academy hoặc AWS Learner Lab, thông tin xác thực tạm thời được cung cấp dưới dạng:
  ```text
  AWS Session Token: IQoJb3Jp...
  ```
  Nếu bạn copy nguyên dòng này gán vào biến `AWS_DEFAULT_REGION` hoặc `AWS_REGION` trong terminal, Terraform sẽ hiểu nhầm chuỗi token đó là tên vùng của AWS.

> [!IMPORTANT]
> **Sự khác biệt về Credentials:**
> * **Permanent Credentials (Tài khoản cá nhân/Doanh nghiệp):** Sử dụng IAM User vĩnh viễn, Access Key bắt đầu bằng **`AKIA`**. Chỉ cần cung cấp `Access Key` và `Secret Key`.
> * **Temporary Credentials (AWS Academy/Learner Lab/SSO):** Sử dụng quyền truy cập tạm thời, Access Key bắt đầu bằng **`ASIA`**. Bắt buộc phải cung cấp thêm **`AWS Session Token`** đi kèm thì AWS mới xác thực thành công.

---

### Cách khắc phục

#### Cách 1: Sửa lại cấu hình AWS CLI & Cài đặt lại Biến Môi Trường (Khuyên Dùng)
Cách tốt nhất là giữ cho code Terraform sạch sẽ bằng cách không viết cứng Credentials vào file `.tf`, thay vào đó hãy truyền qua biến môi trường của Terminal:

1. Đặt lại Region chuẩn trong file cấu hình AWS cá nhân (`~/.aws/config`):
   ```ini
   [default]
   region = ap-southeast-1
   ```
2. Trước khi chạy `terraform plan`, hãy `export` đầy đủ 4 biến môi trường (copy trực tiếp từ trang AWS Academy của bạn):
   ```bash
   export AWS_ACCESS_KEY_ID="ASIAxxxxxxxxxxxxxxxx"
   export AWS_SECRET_ACCESS_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
   export AWS_SESSION_TOKEN="IQoJb3JpZ2luX2VjEE8aCXVzLWVhc3QtMSJGMEQC..."
   export AWS_DEFAULT_REGION="ap-southeast-1"
   ```
3. File `ec2.tf` lúc này cực kỳ đơn giản và an toàn, không sợ bị lộ Key khi đẩy lên GitHub:
   ```hcl
   provider "aws" {
     region = "ap-southeast-1"
   }
   ```

#### Cách 2: Khai báo đầy đủ trong Code Terraform
Nếu bạn muốn truyền thông tin qua file `.tfvars` bí mật, bạn phải bổ sung thêm tham số `token` (Session Token) vào block provider:
```hcl
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
}

provider "aws" {
  region     = "ap-southeast-1"
  access_key = var.access_key
  secret_key = var.secret_key
  token      = var.session_token # Cần thêm dòng này cho tài khoản AWS Academy
}
```

---

## 2. Lỗi Trùng Lặp Subnet (Multiple Subnets Matched)

### Hiện tượng & Thông báo lỗi
Khi chạy `terraform plan` sử dụng Module EC2 Instance, bạn nhận được lỗi sau:
```text
Error: multiple EC2 Subnets matched; use additional constraints to reduce matches to a single EC2 Subnet

  with module.ec2-instance.data.aws_subnet.this[0],
  on .terraform/modules/ec2-instance/main.tf line 777, in data "aws_subnet" "this":
 777: data "aws_subnet" "this" {
```

---

### Nguyên nhân sâu xa

Trong Module `ec2-instance`, có một cấu hình mặc định là `create_security_group = true` (tự động tạo một Security Group mới cho EC2). 
Để tạo Security Group này, module cần biết `vpc_id`. Nếu bạn không truyền trực tiếp `vpc_id` hay `security_group_vpc_id`, module sẽ tự động tra cứu ID của VPC thông qua Subnet được truyền vào biến `subnet_id`.

Tuy nhiên, nếu bạn **không truyền `subnet_id`** (giá trị mặc định là `null`), block `data "aws_subnet" "this"` của module sẽ quét toàn bộ các Subnet đang có trong Region hiện tại của bạn.
* Một VPC mặc định trên AWS thường có **3 Subnets** nằm ở 3 Availability Zones khác nhau (ví dụ: `ap-southeast-1a`, `ap-southeast-1b`, `ap-southeast-1c`).
* Do tìm thấy nhiều hơn 1 Subnet, block `data` (yêu cầu chỉ được trả về duy nhất 1 kết quả) bị bối rối và báo lỗi `multiple EC2 Subnets matched`.

---

### Cách khắc phục

#### Cách 1: Xác định rõ Subnet ID để triển khai EC2 (Khuyên Dùng)
Bất kỳ máy chủ EC2 nào cũng cần được đặt trong một Subnet cụ thể. Bạn hãy bổ sung tham số `subnet_id` vào block khai báo module:

```hcl
module "ec2-instance" {
  source    = "terraform-aws-modules/ec2-instance/aws"
  version   = "6.4.0"
  subnet_id = "subnet-09ce9bf2bcd643f09" # <--- Điền ID Subnet của bạn vào đây
}
```

> [!TIP]
> **Cách lấy nhanh danh sách Subnet ID bằng AWS CLI:**
> Chạy lệnh sau trong Terminal để quét toàn bộ Subnets trong tài khoản của bạn:
> ```bash
> aws ec2 describe-subnets --query "Subnets[*].[SubnetId,AvailabilityZone,CidrBlock,Tags[?Key=='Name'].Value|[0]]" --output table
> ```

#### Cách 2: Tắt tính năng tự động tạo Security Group của Module
Nếu bạn đã có Security Group riêng và không muốn Module tự động thực hiện tra cứu hay tạo mới Security Group, bạn có thể truyền thêm tham số `create_security_group = false`:

```hcl
module "ec2-instance" {
  source                = "terraform-aws-modules/ec2-instance/aws"
  version               = "6.4.0"
  create_security_group = false
  subnet_id             = "subnet-xxxxxx" # Vẫn nên truyền subnet_id để kiểm soát hạ tầng tốt hơn
}
```

---

## 3. Tổng Kết Các Bài Học Kinh Nghiệm (Best Practices)

1. **Cách ly thông tin nhạy cảm:** Không bao giờ push Access Key, Secret Key hoặc Session Token lên GitHub. Hãy sử dụng file `secrets.tfvars` (đã cấu hình trong `.gitignore`) hoặc sử dụng biến môi trường.
2. **Khai báo tường minh:** Khi làm việc với các Module được đóng gói sẵn (như `ec2-instance`, `vpc`...), hãy đọc kỹ các thuộc tính bắt buộc của chúng. Các tài nguyên cơ bản như EC2 luôn yêu cầu vị trí đặt cụ thể (`subnet_id`) và nhóm bảo mật (`vpc_security_group_ids`).
3. **Cẩn trọng khi copy-paste:** Khi sao chép thông tin từ các trang Sandbox/Academy, hãy lưu ý cấu trúc dòng chữ để tránh paste nhầm nhãn tiêu đề (ví dụ: `AWS Session Token [None]:`) vào giá trị thực tế của cấu hình.
