# 📑 KUBERNETES & MINIKUBE CHEAT SHEET

Một cẩm nang tra cứu nhanh các câu lệnh cốt lõi dành cho Cloud/DevOps Engineer trong quá trình học tập, thực hành và triển khai ứng dụng trên nền tảng Kubernetes (K8s) thông qua Minikube.

---

## 🛠️ I. NHÓM LỆNH MINIKUBE (Quản lý cụm K8s ảo ở Local)

Minikube giúp giả lập một cụm Kubernetes (Single-node) ngay trên máy tính cá nhân bằng cách tận dụng các nền tảng hạ tầng như Docker, VirtualBox...

| Câu lệnh | Giải thích chi tiết & Mục đích sử dụng |
| :--- | :--- |
| `minikube start --driver=docker` | **Khởi động cụm K8s**: Sử dụng Docker làm nền tảng hạ tầng (Virtualization Provider). Ở lần đầu chạy, lệnh này sẽ pull Image nền về máy (chỉ tải một lần duy nhất). |
| `minikube status` | **Kiểm tra trạng thái**: Xem cụm Minikube (Control Plane, Host, Kubelet, Apiserver) có đang chạy ổn định hay không. |
| `minikube stop` | **Tạm dừng cụm K8s**: Tương tự như việc tắt máy tính/máy ảo. Toàn bộ trạng thái và các ứng dụng bạn đã deploy bên trong sẽ được giữ nguyên để tiếp tục sử dụng cho lần sau. |
| `minikube delete` | **Xóa sạch cụm hiện tại**: Tiến hành dọn dẹp, xóa bỏ container Minikube và toàn bộ các Pod/Service đã triển khai (đập đi xây lại). Tuy nhiên, Image gốc của Minikube vẫn được giữ lại dưới máy để khởi động nhanh cho lần sau. |
| `minikube ip` | **Xem địa chỉ IP**: Lấy IP của node Minikube đang chạy. Rất hữu ích khi cần cấu hình kết nối mạng hoặc mapping domain ảo. |
| `minikube dashboard` | **Mở giao diện Web trực quan**: Kích hoạt và tự động mở một trang Dashboard trên trình duyệt giúp bạn theo dõi, quản lý trực quan các thành phần K8s bằng chuột mà không cần gõ lệnh. |
| `minikube service <tên-service>` | **Mở đường kết nối ứng dụng**: Tạo một URL kết nối trực tiếp từ trình duyệt máy local xuyên qua lớp mạng của Docker để truy cập vào ứng dụng đang chạy bên trong K8s. |
| `minikube addons list` | **Danh sách tính năng mở rộng**: Hiển thị tất cả các tiện ích bổ sung được tích hợp sẵn (như Ingress, Metrics-server, Registry...). |
| `minikube addons enable <tên-addon>`| **Bật tính năng mở rộng**: Kích hoạt một addon cụ thể. *(Ví dụ: `minikube addons enable ingress` để sử dụng cấu hình định tuyến Ingress).* |

---

## 🚀 II. NHÓM LỆNH KUBECTL CƠ BẢN (Điều phối hệ thống K8s)

`kubectl` là công cụ dòng lệnh (CLI) chính thức để tương tác trực tiếp với API Server của Kubernetes. Các lệnh này áp dụng chung cho cả môi trường Local (Minikube) lẫn Production trên Cloud thật (AWS EKS, Google Cloud GKE...).

### 1. Triển khai & Xóa tài nguyên (Deploy & Teardown)

| Câu lệnh | Giải thích chi tiết & Mục đích sử dụng |
| :--- | :--- |
| `kubectl apply -f <tên-file>.yaml` | **Triển khai / Cập nhật cấu hình**: Đọc file manifest (YAML) và ra lệnh cho K8s tạo mới hoặc cập nhật ứng dụng theo trạng thái mong muốn. *(Đây là lệnh được sử dụng nhiều nhất).* |
| `kubectl delete -f <tên-file>.yaml` | **Xóa tài nguyên theo file**: Tìm và gỡ bỏ toàn bộ những thành phần (Pods, Deployments, Services...) được định nghĩa bên trong file YAML đó ra khỏi hệ thống. |
| `kubectl delete pod <tên-pod>` | **Xóa thủ công một Pod**: Ép một Pod dừng hoạt động. Nếu Pod này được quản lý bởi một Deployment, K8s sẽ tự động sinh ra một Pod mới thay thế ngay lập tức để đảm bảo số lượng bản sao. |

### 2. Kiểm tra trạng thái tài nguyên (Read & Monitor)

| Câu lệnh | Giải thích chi tiết & Mục đích sử dụng |
| :--- | :--- |
| `kubectl get nodes` | **Xem danh sách các máy chủ (Nodes)**: Liệt kê các máy vật lý hoặc máy ảo nằm trong cụm K8s. Với Minikube, danh sách này sẽ chỉ hiển thị duy nhất 1 node mang tên `minikube`. |
| `kubectl get pods` | **Xem danh sách Pods**: Hiển thị trạng thái hoạt động của các container ứng dụng (đang chạy, lỗi, hay đang khởi tạo) trong namespace hiện tại. |
| `kubectl get deployments` (hoặc `get deploy`) | **Xem các bản Deployment**: Kiểm tra xem ứng dụng được phân phối như thế nào, số lượng Pod thực tế (Ready) có khớp với số lượng mong muốn (Up-to-date) hay không. |
| `kubectl get services` (hoặc `get svc`) | **Xem các đầu mối mạng (Service)**: Hiển thị danh sách các Service kèm theo ClusterIP, ExternalIP và các Port đang mở để quản lý luồng traffic. |
| `kubectl get ingress` (hoặc `get ing`) | **Xem cấu hình định tuyến**: Kiểm tra các rule phân tải, domain cấu hình để trỏ traffic từ ngoài vào hệ thống K8s. |
| `kubectl get all` | **Tổng kiểm tra nhanh**: Liệt kê gần như toàn bộ mọi tài nguyên đang chạy cùng lúc trong một không gian làm việc (Pod, Service, Deployment, ReplicaSet). |
| `kubectl get pods -o wide` | **Xem thông tin nâng cao**: Thêm thông tin chi tiết về địa chỉ IP nội bộ của Pod và biết chính xác Pod đó đang được đặt ở Node nào. |

### 3. Kiểm tra chi tiết & Sửa lỗi (Troubleshooting)

| Câu lệnh | Giải thích chi tiết & Mục đích sử dụng |
| :--- | :--- |
| `kubectl describe pod <tên-pod>` | **Xem "bệnh án" chi tiết của Pod**: Xem toàn bộ thông tin chi tiết và lịch sử sự kiện (Events). Cực kỳ quan trọng khi Pod bị lỗi `CrashLoopBackOff` hoặc `ImagePullBackOff` để tìm ra nguyên nhân tận gốc. |
| `kubectl logs <tên-pod>` | **Xem nhật ký hệ thống (Log)**: In ra màn hình toàn bộ log của ứng dụng chạy bên trong Pod (Ví dụ: log từ Console của Node.js, Python, Java...). |
| `kubectl logs -f <tên-pod>` | **Xem log thời gian thực**: Treo màn hình Terminal để theo dõi các dòng log chạy ra liên tục giống như khi debug ứng dụng ở local. |
| `kubectl exec -it <tên-pod> -- sh` | **Chui vào bên trong Pod**: Mở một phiên Terminal trực tiếp bên trong container của Pod. Dùng để kiểm tra file hệ thống, môi trường hoặc test kết nối mạng nội bộ (tương tự như `docker exec`). |

---

## 🎯 III. BÍ KÍP TỐI ƯU TỐC ĐỘ (Dành cho DevOps thực chiến)

Khi làm việc với Kubernetes, tần suất gõ cụm từ `kubectl` có thể lên đến hàng trăm lần mỗi ngày. Để tiết kiệm thời gian và bảo vệ cổ tay, hãy thiết lập phím tắt (**Alias**):

### 1. Cấu hình Alias (Viết tắt)
Mở file cấu hình Terminal của bạn (Ví dụ: `.bashrc` nếu dùng Bash, hoặc `.zshrc` nếu dùng Zsh trên macOS/Linux) và thêm vào dòng sau:
```bash
alias k='kubectl'
```
Sau khi lưu file và khởi động lại Terminal, bạn có thể gõ siêu tốc:
* `k get pods` thay cho `kubectl get pods`
* `k apply -f app.yaml` thay cho `kubectl apply -f app.yaml`
* `k describe pod web-app` thay cho `kubectl describe pod web-app`

### 2. Gợi ý quy trình phát triển Local (Workflow)
1. **Khởi động**: `minikube start --driver=docker`
2. **Theo dõi trực quan**: Mở một tab Terminal riêng chạy lệnh `minikube dashboard`.
3. **Triển khai mã nguồn**: Viết file YAML rồi chạy `kubectl apply -f deployment.yaml`.
4. **Kiểm tra trạng thái**: `kubectl get pods` -> Nếu lỗi dùng `kubectl describe` và `kubectl logs`.
5. **Kiểm tra thành quả trên trình duyệt**: `minikube service <tên-service-của-bạn>`.
6. **Dọn dẹp khi tan làm**: `minikube stop` để máy tính được nghỉ ngơi mà không mất dữ liệu học tập.
