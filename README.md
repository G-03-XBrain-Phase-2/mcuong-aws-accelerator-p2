# 🚀 Nhật Ký Thực Hành & Tiến Độ Học Tập của em

Chào mừng Mentor đến với không gian lưu trữ các bài lab và tiến độ học tập Phase 2 của em. Thư mục này được tổ chức ngăn nắp để Mentor dễ kiểm tra và đánh giá hàng ngày.

---

## 📂 1. Cấu Trúc Thư Mục Thực Hành (`practice/`)

Em chia các bài lab thực hành thành từng chủ đề riêng biệt để tránh xung đột tài nguyên:

```
practice/
├── terraform/                     <-- Các bài lab Terraform (Tuần 8)
│   ├── secrets.tfvars             <-- Lưu API key/credentials dùng chung (đã ẩn bằng .gitignore)
│   ├── lab-01-first-ec2/          
│   ├── lab-02-github-repo/        
│   └── ...
└── gitops-cicd/                   <-- Các bài lab GitOps & CI/CD (Tuần 9)
    ├── lab-01-gha-terraform/      <-- Lab tự động Plan on PR & Apply on Merge
    ├── lab-02-argocd-sync-waves/  <-- Lab quản lý thứ tự chạy (Sync Waves)
    └── lab-03-argocd-app-of-apps-rollback/ <-- Lab mô hình App of Apps & Test Revert
```

*   **Bảo mật:** Em đã cấu hình `.gitignore` đệ quy để tự động chặn các file nhạy cảm như `*.tfstate`, `secrets.tfvars` hay thư mục cấu hình `.terraform/` không bị đẩy lên GitHub.

---

## 🎯 2. Bảng Theo Dõi Tiến Độ Học Tập

### 📅 Tuần 8 — Foundation: IaC (Terraform) + Kubernetes (K8s) (Đã hoàn thành)
*   **Thứ 2 (01/06) & Thứ 3 (02/06):** Khởi chạy EC2 trên AWS, tìm hiểu State Management và Remote State locking (S3 + DynamoDB).
*   **Thứ 4 (03/06) & Thứ 5 (04/06):** Học nền tảng Kubernetes, triển khai thử Pod/Service trên Minikube local.
*   **Thứ 6 (05/06):** Hoàn thành bài Lab tổng hợp mini dự án trên K8s.

### 📅 Tuần 9 — Deliver Smartly: GitOps + Observability + Canary (Đang học)

| Ngày học | Chủ đề cốt lõi | Trạng thái | Chi tiết tiến trình của em |
| :--- | :--- | :---: | :--- |
| **Thứ 2 (08/06)** | GitOps & CI/CD | 🟢 Đã xong | Tự cài đặt thành công Argo CD lên Minikube local, thiết lập workflow tự động Plan-on-PR và Apply-on-Merge, thực hành mô hình App-of-Apps và Rollback chuẩn GitOps (`git revert`). |
| **Thứ 3 (09/06)** | Observability — SLO/SLI/OTel | 🟡 Đang học | Đang tìm hiểu cách tích hợp Prometheus, Grafana, Loki và cấu hình Alert manager dựa trên burn rate. |
| **Thứ 4 (10/06)** | Progressive Delivery (Canary) | 🟡 Đang học | Bắt đầu đọc tài liệu về Argo Rollouts, AnalysisTemplate để triển khai chiến lược Canary Release. |
| **Thứ 5 (11/06) & Thứ 6 (12/06)** | Onsite Đà Nẵng & Lab tổng hợp | ⚪ Chưa | Sẽ tiến hành GitOps hóa cụm K8s từ W8, tích hợp thêm phần monitoring và canary release tự động abort. |

---

## 🛠️ 3. Cách Chạy Thử Code Cho Mentor

Để chạy thử một bài lab bất kỳ (ví dụ bài lab 2 của GitOps):
1. Di chuyển vào thư mục bài lab:
   ```bash
   cd practice/gitops-cicd/lab-02-argocd-sync-waves
   ```
2. Thực hiện apply các manifest K8s vào cụm local:
   ```bash
   kubectl apply -f manifests/
   ```
