# Chuyên đề 2: Quản lý State & Vòng Đời Hạ Tầng (State Management & Lifecycle)

> [!NOTE]  
> Tài liệu này được tổng hợp và cập nhật dựa trên lộ trình ôn thi chứng chỉ **HashiCorp Certified: Terraform Associate 2026** (Udemy). Tập trung vào các Module 31, 33, 34, 35 và 36.

---

## 1. Tổng Quan Về Terraform State File (Module 33)

File `terraform.tfstate` là một tài liệu JSON được tự động sinh ra nhằm ghi lại trạng thái thực tế của tất cả các tài nguyên hạ tầng mà Terraform đã tạo ra trên Cloud.

### Cấu trúc cơ bản của State File:
```json
{
  "version": 4,
  "terraform_version": "1.15.5",
  "serial": 3,
  "lineage": "326fa4fc-ce0d-8206-b9c0-0da11905e0e2",
  "resources": [
    {
      "mode": "managed",
      "type": "aws_instance",
      "name": "myec2",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "attributes": {
            "ami": "ami-0543dbdaf4e114be7",
            "arn": "arn:aws:ec2:ap-southeast-1:1234567890:instance/i-03950e2...",
            "public_ip": "13.250.4.15"
          }
        }
      ]
    }
  ]
}
```

### Các thông số quan trọng:
* **`serial` (Số tuần tự):** Tự động tăng lên `+1` sau mỗi lần chạy lệnh chỉnh sửa hạ tầng thành công. Giúp Terraform xác định đâu là phiên bản state mới nhất.
* **`lineage` (Dòng họ):** Một mã ID duy nhất được gán cố định cho một thư mục dự án Terraform khi khởi tạo. Giúp đảm bảo state không bị gán nhầm lẫn sang dự án khác.
* **`resources`:** Danh sách chi tiết cấu hình và ID thực tế của các tài nguyên trên Cloud (metadata, IP, ARN, Subnet ID...).

---

## 2. Trạng Thái Mong Muốn vs Trạng Thái Thực Tế (Module 34 + 35)

Terraform hoạt động dựa trên việc so sánh và đồng bộ giữa 3 trạng thái:

```
[ 1. Desired State ]  <======== (So sánh) ========>  [ 2. Current State ]
(Những gì bạn viết trong file .tf)                    (Nội dung file terraform.tfstate)
                                                              ||
                                                        (Được đồng bộ với)
                                                              ||
                                                              \/
                                                    [ 3. Real Infrastructure ]
                                                    (Hạ tầng thực tế chạy trên AWS)
```

1. **Desired State (Trạng thái mong muốn):** Là cấu hình hạ tầng bạn viết trong các file `.tf`.
2. **Current State (Trạng thái hiện tại):** Là thông tin ghi nhận trong file `terraform.tfstate`.
3. **Real Infrastructure (Hạ tầng thực tế):** Các tài nguyên đang thực sự chạy trên nền tảng đám mây (ví dụ: các server EC2, CSDL RDS thực tế).

### Quá trình làm việc của Terraform khi chạy `terraform plan/apply`:
* **Bước 1 (Refresh):** Terraform đọc file state hiện có, sau đó gửi API lên Cloud để kiểm tra xem hạ tầng thực tế có khớp với những gì ghi trong file state không.
* **Bước 2 (Compare):** So sánh giữa **Desired State** (code HCL mới nhất bạn vừa viết) và **Current State** (đã được refresh).
* **Bước 3 (Reconcile):** Lên kế hoạch (`Plan`):
  * Nếu code `.tf` khai báo thêm tài nguyên mới $\rightarrow$ Terraform sẽ **Tạo mới (Create)**.
  * Nếu code `.tf` có thay đổi thông số $\rightarrow$ Terraform sẽ **Cập nhật (Update)** hoặc **Tái tạo (Replace)**.
  * Nếu code `.tf` xóa bỏ dòng tài nguyên cũ $\rightarrow$ Terraform sẽ **Hủy bỏ (Delete/Destroy)**.

---

## 3. Terraform Refresh là gì? (Module 36)

**`terraform refresh`** là lệnh dùng để cập nhật lại file `terraform.tfstate` cho khớp với thực tế đang chạy trên Cloud mà **không làm thay đổi** hạ tầng Cloud hay code `.tf` của bạn.

* **Khi nào cần sử dụng?** Khi có ai đó lỡ đăng nhập vào AWS Web Console và sửa tay hạ tầng (ví dụ: thay đổi loại instance từ `t3.micro` lên `t3.medium`). Lệnh refresh sẽ kéo cấu hình thực tế về lưu vào file state trên máy bạn.
* **Thay đổi trong phiên bản mới:**
  * Lệnh đơn lẻ `terraform refresh` hiện nay **không được khuyên dùng độc lập** nữa vì nó có thể tự động ghi đè lên state mà không báo trước.
  * Thay vào đó, Terraform khuyên dùng:
    ```bash
    terraform plan -refresh-only   # Xem trước sự thay đổi của thực tế so với State
    terraform apply -refresh-only  # Đồng ý cập nhật những thay đổi đó vào file State
    ```

---

## 4. Terraform Destroy - Quy Trình Hủy Hạ Tầng (Module 31)

Lệnh `terraform destroy` dùng để xóa bỏ sạch sẽ mọi tài nguyên được định nghĩa và quản lý trong dự án hiện tại.

* **Cơ chế hoạt động:**
  * Terraform sẽ đọc file `terraform.tfstate` để lấy danh sách tài nguyên và ID của chúng trên Cloud.
  * Phân tích mối quan hệ phụ thuộc (dependencies) để xóa theo thứ tự ngược lại (tài nguyên phụ thuộc sẽ bị xóa trước, tài nguyên gốc xóa sau) để tránh lỗi API.
  * Sau khi hoàn tất xóa sạch trên Cloud, file `terraform.tfstate` sẽ được cập nhật thành rỗng (empty).

### Các tham số quan trọng thường dùng:
* **Hủy một tài nguyên cụ thể (Targeted Destroy):** Khi bạn chỉ muốn xóa một tài nguyên cụ thể mà không muốn đụng chạm đến toàn bộ hệ thống khác:
  ```bash
  terraform destroy -target=aws_instance.myec2
  ```
* **Bỏ qua bước xác nhận (Auto Approve):** Tự động đồng ý xóa mà không bắt gõ chữ `yes` (thường dùng trong CI/CD pipeline):
  ```bash
  terraform destroy -auto-approve
  ```

---

## 5. Remote State & State Locking (Mô hình làm việc nhóm)

Khi làm dự án thực tế, nhiều người cùng chạy Terraform. Nếu lưu State ở máy cá nhân (Local State) sẽ bị xung đột. Do đó ta dùng **Remote Backend**.

### Thiết lập tiêu biểu trên AWS:
* **Amazon S3:** Nơi lưu trữ an toàn file `terraform.tfstate` hỗ trợ Versioning.
* **DynamoDB:** Sử dụng cơ chế khóa **State Locking** nhằm ngăn chặn việc 2 người cùng thực hiện lệnh `apply` một lúc gây lỗi hạ tầng.

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "w8/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "terraform-lock-table" # DynamoDB table để lock
    encrypt        = true
  }
}
```

---

## 6. Các lệnh quản lý State quan trọng

* `terraform state list`: Liệt kê tất cả tài nguyên đang được quản lý trong file state.
* `terraform state show <resource_path>`: Xem chi tiết cấu hình lưu trong state của 1 tài nguyên.
* `terraform state mv <old_path> <new_path>`: Đổi tên tài nguyên trong state mà không làm mất/tạo lại nó.
* `terraform state rm <resource_path>`: Xóa quyền quản lý của Terraform đối với tài nguyên đó (nhưng tài nguyên thực tế trên Cloud vẫn tồn tại).
* `terraform import <resource_path> <cloud_id>`: Đưa một tài nguyên đã được tạo tay trước đó trên Cloud vào tầm quản lý của Terraform.
