# 🚀 Nhật Ký Thực Hành & Tiến Độ Học Tập (Practice Hub)

Chào mừng Mentor đến với không gian thực hành các bài Lab DevOps của em. Thư mục này được tổ chức một cách ngăn nắp, bảo mật và dễ theo dõi nhất để Mentor tiện đánh giá tiến độ hàng ngày.

---

## 📂 1. Cấu Trúc Thư Mục Thực Hành (`practice/`)

Để tránh việc Terraform gộp chung các bài học gây xung đột tài nguyên, em đã tổ chức không gian thực hành thành cấu trúc **Multi-Lab (Nhiều bài lab độc lập)** kết hợp quản lý biến tập trung:

```
practice/
│
├── README.md                      <-- File này (Tổng quan & Tiến độ tổng quát)
│
└── terraform/                     <-- Phân vùng thực hành Terraform
    │
    ├── .gitignore                 <-- Quy tắc chặn đệ quy (loại bỏ thư mục nặng .terraform/ và *.tfstate nhạy cảm)
    ├── secrets.tfvars             <-- File chứa Key/Token dùng chung (được .gitignore bảo vệ tuyệt đối)
    │
    ├── notes/                     <-- Ghi chú kiến thức cốt lõi & Sổ tay gỡ lỗi
    │   ├── terraform_state_guide.md
    │   └── managing_sensitive_variables.md
    │
    ├── lab-01-first-ec2/          <-- Lab 01: Triển khai EC2 instance đầu tiên trên AWS
    │   ├── first-ec2.tf
    │   └── ...
    │
    └── lab-02-github-repo/        <-- Lab 02: Triển khai tạo tự động GitHub Repository
        ├── github-repo.tf
        └── ...
```

### 💡 Các điểm sáng trong thiết kế cấu trúc:
1. **Quản lý Secrets tập trung:** Sử dụng file `secrets.tfvars` ở thư mục gốc `practice/terraform/` để lưu trữ tất cả Credentials (AWS keys, GitHub token). Các file code trong lab con chỉ cần khai báo biến và trỏ đường dẫn ra ngoài (`../secrets.tfvars`), giúp code sạch sẽ và an toàn.
2. **Quy tắc bảo mật tốt:** Đã triển khai `.gitignore` đệ quy để đảm bảo không bao giờ vô tình đẩy file state (`.tfstate`) hay thông tin tài khoản lên GitHub.
3. **Phân tách môi trường độc lập:** Mỗi Lab con sở hữu một file cấu hình và vòng đời hạ tầng hoàn toàn riêng biệt.

---

## 🎯 2. Bảng Theo Dõi Tiến Độ Tổng Quát (Week 8)

Dưới đây là tiến độ học tập thực tế theo lộ trình **Week 8 — Foundation: IaC (Terraform) + Kubernetes (K8s)**:

| Ngày học | Chủ đề cốt lõi | Trạng thái thực hành | Chi tiết tiến trình |
| :--- | :--- | :---: | :--- |
| **Thứ 2 (01/06)** | Nền tảng IaC & AWS Provider | 🟢 Đã hoàn thành | Khởi chạy thành công máy chủ EC2 đầu tiên trên AWS (`ap-southeast-1`). Giải quyết lỗi AMI ID và lỗi tag cú pháp. |
| **Thứ 3 (02/06)** | State Management & Secrets | 🟢 Đã hoàn thành | Tạo thành công Repo GitHub qua Terraform. Thiết lập file `secrets.tfvars` dùng chung an toàn. Tái cấu trúc cấu trúc Multi-Lab. |
| **Thứ 4 (03/06)** | Nền tảng Kubernetes (K8s) | 🟡 Đang học | Đang nghiên cứu kiến trúc Kubernetes (Master/Worker node), viết cấu hình cho Pod và Service cơ bản. |
| **Thứ 5 (04/06)** | K8s ConfigMap, Secret, Network | ⚪ Chưa bắt đầu | Học cách quản lý cấu hình tập trung và thiết lập chính sách kết nối mạng trong K8s. |
| **Thứ 6 (05/06)** | Mini Project & Đánh giá tuần | ⚪ Chưa bắt đầu | Kết hợp Terraform + K8s để deploy một ứng dụng thực tế quy mô nhỏ. |

---

## 🛠️ 3. Quy Trình Chạy Thử Code Cho Mentor

Để chạy thử bất kỳ bài thực hành nào trong không gian này:
1. Mở Terminal và di chuyển vào thư mục lab tương ứng:
   ```bash
   cd practice/terraform/lab-02-github-repo
   ```
2. Khởi tạo môi trường:
   ```bash
   terraform init
   ```
3. Xem trước kế hoạch (Mentor cần tạo file `secrets.tfvars` của riêng mình ở thư mục cha theo mẫu trong ghi chú):
   ```bash
   terraform plan -var-file="../secrets.tfvars"
   ```
