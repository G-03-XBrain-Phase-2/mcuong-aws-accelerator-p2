# Tài Liệu Ôn Thi Cấp Tốc: Lý Thuyết & Thực Hành Terraform (Full Tự Luận)

Tài liệu này tổng hợp toàn bộ các kiến thức cốt lõi nhất được tinh lọc để chuẩn bị cho bài thi tự luận (60 phút) của bạn, bao quát từ định nghĩa, cú pháp, kiểu dữ liệu đến các tính năng nâng cao và module.

---

## 1. IaC (Infrastructure as Code) Là Gì?

### 1.1. Định nghĩa IaC
**Infrastructure as Code (IaC)** là phương pháp quản lý và thiết lập hạ tầng công nghệ thông tin (mạng, máy chủ, CSDL, cân bằng tải...) bằng cách sử dụng các tệp tin cấu hình (mã nguồn) thay vì cấu hình thủ công trên giao diện web (Console) hoặc sử dụng các script dòng lệnh rời rạc.

### 1.2. Các đặc trưng chính của IaC
* **Declarative (Khai báo - Terraform sử dụng):** Bạn chỉ cần định nghĩa **trạng thái mong muốn (Desired State)** của hạ tầng (ví dụ: "Tôi muốn có 3 server EC2"). Terraform sẽ tự so sánh với thực tế và chạy các bước để đạt được trạng thái đó.
* **Imperative (Mệnh lệnh - Ansible/Bash sử dụng):** Chỉ ra từng bước cụ thể phải chạy (ví dụ: "Bước 1: Tạo EC2, Bước 2: Cài nginx...").
* **Idempotency (Tính đồng nhất):** Chạy cấu hình IaC nhiều lần với cùng một tham số đầu vào sẽ luôn cho ra một kết quả hạ tầng duy nhất giống nhau, không tạo ra tài nguyên thừa hay trùng lặp.
* **Version Control:** Vì hạ tầng là code, ta có thể lưu trữ trên GitHub/GitLab, theo dõi lịch sử thay đổi (commit history), review code (Pull Request) trước khi triển khai.

---

## 2. Cú Pháp HCL (HashiCorp Configuration Language)

### 2.1. Cấu trúc Syntax cơ bản
Ngôn ngữ HCL bao gồm các **Block** (khối), bên trong block là các **Argument** (đối số) dưới dạng `key = value`.

```hcl
# Cú pháp tổng quát:
<BLOCK TYPE> "<BLOCK LABEL 1>" "<BLOCK LABEL 2>" {
  # Block Body
  <IDENTIFIER> = <EXPRESSION> # Argument
}
```

### 2.2. Các loại Block phổ biến nhất
1. **`terraform {}`:** Khai báo các cài đặt cho chính Terraform (yêu cầu phiên bản, cấu hình remote backend, phiên bản provider bắt buộc).
2. **`provider {}`:** Cấu hình plugin kết nối đến cloud/dịch vụ (AWS, GCP, GitHub).
3. **`resource {}`:** Định nghĩa tài nguyên cần tạo (VPC, EC2, S3).
4. **`data {}`:** Truy vấn thông tin của tài nguyên có sẵn trên cloud (không tạo mới tài nguyên).
5. **`variable {}`:** Định nghĩa tham số đầu vào (Inputs).
6. **`output {}`:** Định nghĩa giá trị trả về hiển thị ra màn hình hoặc truyền sang module khác.
7. **`locals {}`:** Định nghĩa các hằng số hoặc biến cục bộ dùng trong nội bộ file.

### 2.3. Quy tắc Comment trong HCL
* `#` hoặc `//`: Comment trên một dòng.
* `/* ... */`: Comment trên nhiều dòng.

---

## 3. Resource Block (Khối Tài Nguyên)

### 3.1. Cú pháp khai báo
```hcl
resource "aws_instance" "my_web" {
  ami           = "ami-0543dbdaf4e114be7"
  instance_type = "t3.micro"
}
```
* **`aws_instance` (Label 1):** Là **Resource Type** (Kiểu tài nguyên), do Provider quy định.
* **`my_web` (Label 2):** Là **Resource Name** (Tên nội bộ), do người viết tự đặt để tham chiếu trong code.
* **Cách tham chiếu:** Cú pháp để trỏ tới giá trị của tài nguyên này từ nơi khác trong code là:
  `<RESOURCE TYPE>.<RESOURCE NAME>.<ATTRIBUTE>`
  *(Ví dụ: `aws_instance.my_web.public_ip`)*.

---

## 4. Kiểu Dữ Liệu Trong Terraform (Data Types)

Các biến trong Terraform bắt buộc hoặc tự động nhận diện các kiểu dữ liệu dưới đây:

### 4.1. Kiểu Nguyên Bản (Primitive Types)
* `string`: Chuỗi ký tự (đặt trong dấu ngoặc kép `"..."`).
* `number`: Số nguyên hoặc số thực (ví dụ: `10`, `3.14`).
* `bool`: Giá trị logic (`true` hoặc `false`).

### 4.2. Kiểu Phức Tạp/Cấu Trúc (Complex/Collection Types)
* **`list(<TYPE>)`:** Danh sách các phần tử **cùng kiểu**, sắp xếp theo thứ tự index (bắt đầu từ `0`). Cho phép trùng lặp.
  * *Ví dụ:* `list(string)` -> `["ap-southeast-1a", "ap-southeast-1b"]`.
* **`set(<TYPE>)`:** Tập hợp các phần tử **cùng kiểu**, không sắp xếp thứ tự và **không cho phép trùng lặp**.
  * *Ví dụ:* `toset(["user1", "user2"])`.
* **`map(<TYPE>)`:** Tập hợp các cặp `key = value` có khóa là string và các giá trị phải **cùng kiểu**.
  * *Ví dụ:* `map(string)` -> `{ env = "dev", project = "billing" }`.
* **`object({ <ATTR> = <TYPE> })`:** Tập hợp cấu trúc phức tạp chứa các thuộc tính có **kiểu dữ liệu khác nhau**.
  * *Ví dụ:*
    ```hcl
    variable "instance_config" {
      type = object({
        ami  = string
        size = number
        monitoring = bool
      })
    }
    ```
* **`tuple([<TYPE>, <TYPE>])`:** Danh sách các phần tử có **kiểu dữ liệu khác nhau**, sắp xếp theo thứ tự cố định.

---

## 5. Input Variables (Biến Đầu Vào)

### 5.1. Cú pháp khai báo đầy đủ
```hcl
variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "Size of the EC2 instance"
  sensitive   = false # Nếu để true, giá trị sẽ bị ẩn đi trong màn hình log CLI
}
```

### 5.2. Thứ tự ưu tiên của biến (Precedence) - Cực kỳ quan trọng trong thi cử!
Nếu cùng một biến được truyền giá trị từ nhiều nguồn khác nhau, Terraform sẽ áp dụng giá trị theo thứ tự ưu tiên từ **cao xuống thấp** như sau:

```
[ ƯU TIÊN CAO NHẤT ]
  1. Đối số dòng lệnh CLI: -var hoặc -var-file="secrets.tfvars"
  2. Các file tự động load có đuôi: *.auto.tfvars hoặc *.auto.tfvars.json
  3. File cấu hình biến mặc định: terraform.tfvars
  4. Biến môi trường hệ thống: export TF_VAR_name="value"
  5. Giá trị default trong block variable {}
[ ƯU TIÊN THẤP NHẤT ]
```

---

## 6. Local Values (Biến Cục Bộ)

### 6.1. Ý nghĩa
Dùng để tính toán các biểu thức phức tạp hoặc tránh lặp lại cùng một chuỗi cấu hình nhiều lần (nguyên tắc DRY). Biến cục bộ **không thể** được truyền từ ngoài vào như `variable`.

### 6.2. Cú pháp khai báo và sử dụng
```hcl
locals {
  service_name = "payment-gateway"
  owner        = "devops-team"
  
  # Kết hợp các chuỗi và biến
  common_tags = {
    Name  = "${local.service_name}-server"
    Owner = local.owner
    Env   = var.env
  }
}

resource "aws_instance" "app" {
  ami           = "ami-xxx"
  instance_type = "t3.micro"
  
  # Cách gọi Local Value:
  tags = local.common_tags
}
```

---

## 7. Output Variables & Expressions (Giá Trị Đầu Ra)

### 7.1. Ý nghĩa
Dùng để xuất thông tin ra màn hình sau khi chạy xong `terraform apply`, hoặc để truyền thông tin từ **Child Module** lên **Root Module**.

### 7.2. Cú pháp khai báo
```hcl
output "server_public_ip" {
  value       = aws_instance.app.public_ip
  description = "Public IP of the server"
  sensitive   = false # Nếu để true, Terraform sẽ ẩn IP này trong console output
}
```

### 7.3. Các biểu thức tính toán phổ biến (Expressions)
* **Toán tử ba ngôi (Conditional):** `condition ? true_val : false_val`
  * *Ví dụ:* `instance_type = var.env == "prod" ? "t3.medium" : "t3.micro"`
* **Vòng lặp For trong Expression:**
  * *Ví dụ:* Trích xuất tất cả ID của instance ra một list:
    `value = [for instance in aws_instance.web : instance.id]`
* **Splat Operator (`*`):** Lấy nhanh tất cả giá trị của một danh sách tài nguyên:
  * *Ví dụ:* `aws_instance.web[*].public_ip` (tương đương với việc dùng vòng lặp for ở trên).

---

## 8. Meta-Arguments (Tham Số Hệ Thống)

Meta-arguments là các tham số đặc biệt do Terraform cung cấp sẵn, có thể áp dụng cho **bất kỳ Resource block nào** để thay đổi cách thức tạo tài nguyên.

1. **`depends_on` (Khai báo phụ thuộc tường minh):** Chỉ định tài nguyên A chỉ được tạo sau khi tài nguyên B đã tạo xong.
   ```hcl
   resource "aws_instance" "web" {
     depends_on = [aws_iam_role_policy_attachment.app_policy]
   }
   ```
2. **`count` (Tạo nhiều tài nguyên giống nhau):** Dựa trên một số lượng cụ thể.
   ```hcl
   resource "aws_instance" "web" {
     count = 3 # Tạo ra 3 EC2 instance
     tags = { Name = "server-${count.index}" } # count.index chạy từ 0 đến 2
   }
   ```
3. **`for_each` (Tạo nhiều tài nguyên dựa trên Map hoặc Set):** Giúp tránh lỗi dịch chuyển index của `count` khi xóa tài nguyên ở giữa danh sách.
   ```hcl
   resource "aws_iam_user" "users" {
     for_each = toset(["An", "Binh", "Cuong"])
     name     = each.key # each.key hoặc each.value đại diện cho tên user
   }
   ```
4. **`provider` (Chọn provider alias cụ thể):**
   ```hcl
   resource "aws_instance" "us_web" {
     provider = aws.us_east # Sử dụng provider alias us-east-1 thay vì default
   }
   ```
5. **`lifecycle` (Quản lý vòng đời tài nguyên):** Xem mục 9 bên dưới.

---

## 9. Lifecycle Block (Quản Lý Vòng Đời)

Nằm bên trong block `resource`, dùng để can thiệp vào quy trình tạo/xóa tài nguyên mặc định của Terraform.

### 9.1. Các tham số cấu hình của `lifecycle`
* **`create_before_destroy = true`:**
  * *Mặc định:* Terraform sẽ xóa tài nguyên cũ trước, sau đó mới tạo tài nguyên mới thay thế (gây downtime).
  * *Khi bật:* Terraform sẽ tạo tài nguyên mới trước, kiểm tra thành công rồi mới xóa tài nguyên cũ đi (đảm bảo Zero-Downtime).
* **`prevent_destroy = true`:**
  * Ngăn cản hoàn toàn việc vô tình chạy lệnh `terraform destroy` làm mất các tài nguyên cực kỳ quan trọng (ví dụ: Database sản xuất, ổ cứng lưu trữ).
* **`ignore_changes = [<LIST ATTRIBUTES>]`:**
  * Bỏ qua các thay đổi đối với một số thuộc tính cụ thể nếu chúng bị thay đổi bên ngoài Terraform (ví dụ: Thay đổi Tag thủ công trên AWS Console hoặc cấu hình Auto Scaling tự thay đổi size EC2).
  ```hcl
  resource "aws_instance" "web" {
    ami           = "ami-0543dbdaf4e114be7"
    instance_type = "t3.micro"

    lifecycle {
      create_before_destroy = true
      prevent_destroy       = false
      ignore_changes        = [tags, instance_type]
    }
  }
  ```

---

## 10. Module (Đóng Gói Hạ Tầng)

* **Root Module:** Thư mục làm việc hiện hành (nơi chạy `terraform apply`).
* **Child Module:** Thư mục con hoặc gói bên ngoài được gọi thông qua block `module`.
* **Cấu trúc gọi module:**
  ```hcl
  module "vpc" {
    source = "./modules/aws-vpc" # Local path hoặc Git repository URL
    
    # Các biến đầu vào khai báo ở variables.tf của module con
    vpc_cidr = "10.0.0.0/16"
  }
  ```
* **Lấy dữ liệu ra từ module:** Sử dụng cú pháp `module.<MODULE_NAME>.<OUTPUT_NAME>`
  *(Ví dụ: `vpc_id = module.vpc.vpc_id`)*.

---

## 11. Các Lệnh Thực Hành CLI Cơ Bản Nhất

* `terraform fmt`: Tự động định dạng lại code thụt đầu dòng cho đúng chuẩn HCL.
* `terraform validate`: Kiểm tra lỗi cú pháp và kiểm tra logic khai báo biến mà không cần kết nối cloud.
* `terraform init`: Tải provider plugins và khởi tạo cấu hình backend.
* `terraform plan`: So sánh code và thực tế, in ra kế hoạch thay đổi (`+` tạo mới, `~` cập nhật, `-` xóa).
* `terraform apply`: Thực thi triển khai hạ tầng lên Cloud.
* `terraform destroy`: Xóa bỏ toàn bộ tài nguyên được quản lý trong dự án.
