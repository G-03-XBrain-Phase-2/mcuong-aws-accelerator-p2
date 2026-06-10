# Lab 01: Thiết Lập Luồng GitOps "Plan-on-PR & Apply-on-Merge" Với GitHub Actions

## Mục Tiêu Bài Lab
*   Hiểu và thực hành xây dựng hệ thống CI/CD cho hạ tầng (IaC) sử dụng **GitHub Actions** và **Terraform**.
*   Thiết lập luồng **Plan-on-PR** để tự động kiểm tra code và chạy `terraform plan`, hiển thị kết quả trực tiếp dưới dạng bình luận trên Pull Request.
*   Thiết lập luồng **Apply-on-Merge** để tự động chạy `terraform apply` ngay khi PR được merge vào nhánh `main`.
*   *Lưu ý:* Để bài lab này có thể chạy ngay mà không phụ thuộc vào tài khoản cloud trả phí (AWS/Azure/GCP), chúng ta sẽ sử dụng **Local Provider** (`local_file`) làm ví dụ minh họa. Sau khi hoàn thành, bạn có thể tự thử thách bằng cách chuyển sang AWS.

---

## Cấu Trúc Thư Mục Dự Án
Chúng ta sẽ tổ chức mã nguồn như sau:
```text
lab-01-gha-terraform/
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml    # Workflow chạy khi tạo/cập nhật PR
│       └── terraform-apply.yml   # Workflow chạy khi merge vào main
├── terraform/
│   ├── main.tf                 # File cấu hình Terraform chính
│   ├── variables.tf            # Khai báo biến
│   └── outputs.tf              # Đầu ra thông tin
└── README.md                   # Hướng dẫn này
```

---

## Các Bước Thực Hiện

### Bước 1: Khởi Tạo Cấu Hình Terraform local
1. Di chuyển vào thư mục `terraform/` trong bài lab này.
2. Tạo file [main.tf](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/gitops-cicd/lab-01-gha-terraform/terraform/main.tf) với nội dung:
```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4.0"
    }
  }
}

resource "local_file" "pet_name" {
  filename = "${path.module}/pet.txt"
  content  = "My favorite pet name is: ${var.pet_name}"
}
```

3. Tạo file [variables.tf](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/gitops-cicd/lab-01-gha-terraform/terraform/variables.tf):
```hcl
variable "pet_name" {
  type        = string
  description = "The name of your pet"
  default     = "Rex"
}
```

4. Tạo file [outputs.tf](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/gitops-cicd/lab-01-gha-terraform/terraform/outputs.tf):
```hcl
output "pet_file_path" {
  value       = local_file.pet_name.filename
  description = "Path to the generated file"
}
```

---

### Bước 2: Viết GitHub Actions Workflow - Plan on PR
Tạo file [.github/workflows/terraform-plan.yml](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/gitops-cicd/lab-01-gha-terraform/.github/workflows/terraform-plan.yml). Workflow này sẽ chạy khi có Pull Request trỏ vào nhánh `main`.

```yaml
name: Terraform Plan on PR

on:
  pull_request:
    branches:
      - main
    paths:
      - 'terraform/**'

permissions:
  contents: read
  pull-requests: write # Bắt buộc phải có quyền này để comment vào PR

jobs:
  plan:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ./terraform

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Terraform Init
        run: terraform init

      - name: Terraform Format Check
        run: terraform fmt -check

      - name: Terraform Validate
        run: terraform validate

      - name: Terraform Plan
        id: plan
        run: terraform plan -no-color
        continue-on-error: true # Cho phép tiếp tục chạy các bước sau ngay cả khi plan lỗi

      # Đưa kết quả plan vào bình luận của PR để Reviewer dễ xem
      - name: Post Plan Comment to PR
        uses: actions/github-script@v7
        if: always() && github.event_name == 'pull_request'
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          script: |
            const fs = require('fs');
            const output = `#### Terraform Format & Style 🖌
            #### Terraform Initialization ⚙️
            #### Terraform Validation 🤖
            #### Terraform Plan 📖
            
            <details><summary>Show Plan Output</summary>
            
            \`\`\`hcl
            ${{ steps.plan.outputs.stdout }}
            \`\`\`
            
            </details>
            
            *Pusher: @${{ github.actor }}, Action: \`${{ github.event_name }}\`*`;
            
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: output
            })

      - name: Check Plan Status
        if: steps.plan.outcome == 'failure'
        run: exit 1
```

---

### Bước 3: Viết GitHub Actions Workflow - Apply on Merge
Tạo file [.github/workflows/terraform-apply.yml](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/gitops-cicd/lab-01-gha-terraform/.github/workflows/terraform-apply.yml). Workflow này chạy khi có commit push trực tiếp lên nhánh `main` (thường là do merge PR thành công).

```yaml
name: Terraform Apply on Merge

on:
  push:
    branches:
      - main
    paths:
      - 'terraform/**'

permissions:
  contents: read

jobs:
  apply:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ./terraform

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Terraform Init
        run: terraform init

      - name: Terraform Apply
        run: terraform apply -auto-approve
```

---

### Bước 4: Đẩy code lên GitHub & Thực hành kiểm thử

Để kiểm tra xem hệ thống hoạt động đúng hay không, bạn hãy làm theo các bước sau:

1.  **Khởi tạo Git repo cục bộ & Đẩy lên GitHub:**
    *   Tạo một Repository mới dạng **Private** trên tài khoản GitHub cá nhân của bạn (ví dụ đặt tên: `terraform-gitops-lab`).
    *   Thực hiện copy các file từ bài lab này sang thư mục chứa repo git mới đó:
        ```bash
        git init
        git add .
        git commit -m "initial commit"
        git branch -M main
        git remote add origin <URL-CỦA-REPO-GITHUB>
        git push -u origin main
        ```

2.  **Tạo Branch mới để kiểm tra luồng Plan:**
    *   Tạo một nhánh mới:
        ```bash
        git checkout -b feature/change-pet-name
        ```
    *   Mở file `terraform/variables.tf` và sửa giá trị default của `pet_name` từ `"Rex"` thành `"Luna"`.
    *   Commit và push nhánh này lên GitHub:
        ```bash
        git add terraform/variables.tf
        git commit -m "change pet name to Luna"
        git push origin feature/change-pet-name
        ```

3.  **Tạo Pull Request và Xem Kết Quả:**
    *   Mở giao diện GitHub của repository đó, tạo một **Pull Request (PR)** từ nhánh `feature/change-pet-name` vào nhánh `main`.
    *   Đợi vài giây, bạn sẽ thấy tab **Actions** kích hoạt workflow `Terraform Plan on PR`.
    *   Sau khi workflow chạy xong, hãy cuộn xuống phần bình luận của PR, bạn sẽ thấy bot GitHub đăng bình luận chi tiết kết quả `terraform plan` (nó báo sẽ sửa đổi file `pet.txt`).

4.  **Merge PR và Xem Apply hoạt động:**
    *   Nhấn **Merge Pull Request** trên GitHub.
    *   Sau khi merge, vào tab **Actions**, bạn sẽ thấy workflow `Terraform Apply on Merge` được tự động kích hoạt và chạy thành công lệnh `terraform apply`.

---

## 🎯 Bài Tập Nâng Cao (Challenge)

Vì bài lab trên sử dụng `local_file` nên file state được tạo ra và lưu ngay trên runner của GitHub Actions (và sẽ biến mất khi job chạy xong). Đây là một vấn đề lớn vì state không được lưu trữ tập trung!

**Thử thách:**
1.  **Cấu hình Remote Backend:** Hãy sửa đổi cấu hình Terraform để sử dụng **AWS S3** làm backend và **DynamoDB** làm state locking (hoặc sử dụng **Terraform Cloud**).
2.  **Sử dụng OIDC để xác thực:** Hãy cấu hình GitHub Actions kết nối với AWS thông qua AWS OIDC (`aws-actions/configure-aws-credentials`) thay vì dùng GitHub Secrets chứa ACCESS_KEY.
3.  **Branch Protection Rule:** Bật tính năng Branch Protection trên GitHub cho nhánh `main`, yêu cầu PR phải có status check `plan` thành công trước khi được phép merge.
