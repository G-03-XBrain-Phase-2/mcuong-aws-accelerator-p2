# Thứ 2 (01/06) - Tổng kết & Tiến trình

## 1. Nội dung đã học hôm nay

- **Tổng quan về IaC (Infrastructure as Code):** Hiểu rõ sự khác biệt giữa Declarative (Khai báo trạng thái mong muốn) và Imperative (Mệnh lệnh chỉ định các bước). Hiểu thuộc tính Idempotent (Đồng nhất kết quả).
- **Cú pháp HCL cốt lõi:** Khai báo cấu trúc khối `provider` và khối `resource`.
- **Workflow cơ bản của Terraform:** Quy trình 3 bước cốt lõi gồm `terraform init` (tải plugin/providers), `terraform plan` (xem trước kế hoạch thay đổi), và `terraform apply` (thực thi thay đổi lên Cloud).

## 2. Bài tập / Hands-on đã hoàn thành

- Khởi chạy thành công máy chủ **EC2 Instance đầu tiên** (`t3.micro`) trên AWS ở vùng Singapore (`ap-southeast-1`).
- **Đường dẫn thực hành:** \[lab-01-first-ec2/first-ec2.tf\](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/terraform/lab-01-first-ec2/first-ec2.tf)

## 3. Khó khăn gặp phải & Cách giải quyết

- **Lỗi** `InvalidAMIID.NotFound`**:** Ban đầu copy một AMI ID của vùng Singapore nhưng lại chạy provider ở vùng `us-east-1` (N. Virginia), dẫn đến lỗi không tìm thấy ảnh đĩa.
  - *Cách giải quyết:* Đã chuyển Region của AWS provider sang `ap-southeast-1` để tương thích hoàn toàn với ID AMI đã chọn.
- **Lỗi cú pháp khai báo nhãn (tag):** Sử dụng khối `tag { Name = "" }` không có dấu bằng dẫn đến lỗi biên dịch HCL.
  - *Cách giải quyết:* Tìm hiểu và sửa lại đúng cấu trúc kiểu bản đồ của thuộc tính `tags` (có chữ `s` ở cuối và sử dụng toán tử gán `=`):

    ```hcl
    tags = {
      Name = "cuong-ec2"
    }
    ```

## 4. Tiến trình hiện tại

- [ ] Chưa bắt đầu

- [ ] Đang tiến hành

- [x] Đã hoàn thành