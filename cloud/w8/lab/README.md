# Tài liệu Lab Tuần 8 (IaC & Kubernetes)

Chào mừng bạn đến với thư mục Lab của Tuần 8. Thư mục này được tổ chức lại để phân chia rõ ràng các nội dung thực hành:

## 1. Cấu trúc thư mục Lab
* **[terraform/](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/cloud/w8/lab/terraform/)**: Chứa các bài thực hành về Terraform (IaC) từ cơ bản đến nâng cao (Module, Multi-provider, Workspaces).
* **[k8s/](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/cloud/w8/lab/k8s/)**: Chứa chuỗi bài lab thực hành Kubernetes trên Minikube, đi từ nền tảng cơ bản đến việc xây dựng một nền tảng K8s thu nhỏ hoàn chỉnh.

---

## 2. Chuỗi Lab Kubernetes (K8s) trên Minikube
Chuỗi bài lab K8s được thiết kế đi từ mức cơ bản nhất đến độ phức tạp của bài lab **"Mini K8s platform trên minikube"** được yêu cầu trong chương trình:
1. **[Lab 01: K8s Basics](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/cloud/w8/lab/k8s/lab_01_k8s_basics.md)** - Làm quen với Pod, ReplicaSet và Deployment.
2. **[Lab 02: K8s Networking](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/cloud/w8/lab/k8s/lab_02_k8s_networking.md)** - Thiết lập Service (ClusterIP, NodePort) và Ingress Controller.
3. **[Lab 03: K8s Config & Secrets](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/cloud/w8/lab/k8s/lab_03_k8s_configs_secrets.md)** - Sử dụng ConfigMap và Secret để quản lý cấu hình.
4. **[Lab 04: Reliability & Resources](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/cloud/w8/lab/k8s/lab_04_k8s_probes_resources.md)** - Cấu hình Probes (Liveness/Readiness) và quản lý tài nguyên (Requests/Limits).
5. **[Lab 05: Auto-scaling](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/cloud/w8/lab/k8s/lab_05_k8s_scaling_hpa.md)** - Cấu hình Horizontal Pod Autoscaler (HPA) tự động co giãn theo tải.
6. **[Lab 06 (Chính thức): Mini K8s Platform](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/cloud/w8/lab/k8s/lab_06_mini_k8s_platform.md)** - Triển khai một ứng dụng Multi-tier hoàn chỉnh tích hợp toàn bộ các kỹ thuật trên.

---

## 3. Đường dẫn thực hành (Practice Codes)
* Toàn bộ mã nguồn Terraform được lưu trữ tại: [practice/terraform/](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/terraform/)
* Toàn bộ file cấu hình Kubernetes (YAML) của bài Lab được lưu trữ tại: [practice/w8-lab/](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/w8-lab/)

