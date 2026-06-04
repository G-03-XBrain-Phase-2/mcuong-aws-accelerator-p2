# Chuỗi Lab Thực Hành Kubernetes Trên Minikube

Chào mừng bạn đến với chuỗi bài lab Kubernetes (K8s) được thiết kế từ cơ bản đến nâng cao. Chuỗi lab này sẽ giúp bạn nắm vững các khái niệm cốt lõi của K8s và sẵn sàng cho bài Lab thực tế **"Mini K8s platform trên minikube"** (Lab 06).

---

## 📋 Danh sách bài Lab

| Tên bài Lab | Mô tả mục tiêu | Thư mục thực hành |
| :--- | :--- | :--- |
| **[Lab 01: K8s Basics](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/cloud/w8/lab/k8s/lab_01_k8s_basics.md)** | Làm quen với Pods, ReplicaSets, Deployments, thao tác câu lệnh `kubectl`. | `practice/w8-lab/lab-01-basics/` |
| **[Lab 02: K8s Networking](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/cloud/w8/lab/k8s/lab_02_k8s_networking.md)** | Cấu hình Service (ClusterIP, NodePort) và Ingress để định tuyến traffic bên ngoài vào. | `practice/w8-lab/lab-02-networking/` |
| **[Lab 03: K8s Configs & Secrets](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/cloud/w8/lab/k8s/lab_03_k8s_configs_secrets.md)** | Tách biệt cấu hình ứng dụng bằng ConfigMap và bảo mật thông tin nhạy cảm với Secret. | `practice/w8-lab/lab-03-configs-secrets/` |
| **[Lab 04: Reliability & Resource Management](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/cloud/w8/lab/k8s/lab_04_k8s_probes_resources.md)** | Cấu hình Liveness/Readiness Probes và đặt giới hạn tài nguyên CPU/RAM cho Container. | `practice/w8-lab/lab-04-reliability/` |
| **[Lab 05: Auto-scaling (HPA)](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/cloud/w8/lab/k8s/lab_05_k8s_scaling_hpa.md)** | Cấu hình Horizontal Pod Autoscaler (HPA) để K8s tự động tăng giảm số lượng Pod theo tải thực tế. | `practice/w8-lab/lab-05-scaling/` |
| **[Lab 06: Mini K8s Platform trên Minikube](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/cloud/w8/lab/k8s/lab_06_mini_k8s_platform.md)** | **[Lab Chính thức]** Xây dựng hệ thống Multi-tier (Frontend, Backend, Cache) kết hợp toàn bộ kiến thức trên. | `practice/w8-lab/lab-06-mini-k8s-platform/` |

---

## 🛠️ Chuẩn bị môi trường chung

Để thực hành các bài Lab này trên máy cá nhân (macOS), hãy đảm bảo bạn đã cài đặt và khởi tạo các công cụ sau:

1. **Docker Desktop** (hoặc Docker engine): Dùng làm driver container chạy bên dưới.
2. **Kubectl**: Command-line tool để tương tác với cluster K8s.
3. **Minikube**: Giải pháp chạy K8s single-node local.

### Lệnh khởi động Minikube khuyến nghị:
```bash
minikube start --driver=docker --cpus=2 --memory=4096
```
> [!TIP]
> Việc cấu hình `--cpus=2 --memory=4096` giúp cluster local của bạn có đủ tài nguyên để chạy nhiều Pod, Ingress Controller và Horizontal Pod Autoscaler (HPA) ở Lab 05 & Lab 06 mà không bị treo hay nghẽn.

### Kiểm tra trạng thái Cluster:
```bash
# Kiểm tra xem kubectl có kết nối được với Minikube không
kubectl cluster-info

# Xem danh sách các node (phải ở trạng thái Ready)
kubectl get nodes
```
