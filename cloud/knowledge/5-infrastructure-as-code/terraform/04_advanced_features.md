# Chuyên đề 4: Các Tính năng Nâng cao (Advanced Features)

Khi hạ tầng mở rộng, bạn cần xử lý các logic phức tạp như lặp (loop), rẽ nhánh (conditional), hoặc cấu hình lại vòng đời tài nguyên.

## 1. Meta-Arguments quan trọng

### A. Lifecycle Block (Quản lý vòng đời tài nguyên)
* `create_before_destroy = true`: Tạo tài nguyên mới trước rồi mới xóa tài nguyên cũ (giúp zero-downtime).
* `prevent_destroy = true`: Ngăn chặn việc lỡ tay chạy `terraform destroy` làm mất tài nguyên quan trọng (như RDS Database).
* `ignore_changes = [tags, ami]`: Bỏ qua các thay đổi đối với một số thuộc tính nếu chúng bị sửa tay ở ngoài AWS Console.

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  lifecycle {
    prevent_destroy = true
  }
}
```

### B. Depends On
Bắt buộc Terraform phải tạo tài nguyên A xong xuôi hoàn toàn mới được tạo tài nguyên B (chỉ dùng khi Terraform không tự phát hiện được mối quan hệ phụ thuộc).
```hcl
resource "aws_instance" "app" {
  # ...
  depends_on = [aws_iam_role_policy_attachment.app_logs]
}
```

## 2. Vòng lặp & Câu điều kiện (Loops & Conditionals)

### A. Toán tử ba ngôi (Conditional Expression)
```hcl
# Chỉ tạo IP tĩnh (EIP) nếu env là prod
resource "aws_eip" "nat" {
  count = var.env == "prod" ? 1 : 0
}
```

### B. Count vs. For Each
* **`count`:** Thích hợp khi muốn tạo ra một số lượng cụ thể các tài nguyên giống hệt nhau.
* **`for_each`:** Thích hợp khi muốn tạo danh sách tài nguyên dựa trên một Map hoặc Set thông tin chi tiết (Khuyên dùng vì khi xóa 1 phần tử trong danh sách, state không bị dịch chuyển chỉ số như `count`).

```hcl
resource "aws_iam_user" "users" {
  for_each = toset(["an", "binh", "cuong"])
  name     = each.value
}
```

### C. Dynamic Blocks (Khai báo lặp các khối con bên trong Resource)
Thường dùng cho các khối cấu hình lặp lại như Security Group Rules.
```hcl
resource "aws_security_group" "allow_ports" {
  name        = "allow_multiple_ports"
  
  dynamic "ingress" {
    for_each = [80, 443, 22]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}
```
