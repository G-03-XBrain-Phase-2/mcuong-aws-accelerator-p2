# Tổng Quan Kiến Trúc Kubernetes (K8s)

Tài liệu này cung cấp cái nhìn toàn cảnh về kiến trúc hệ thống Kubernetes, mối quan hệ giữa các thành phần cốt lõi, cách ánh xạ chúng vào hạ tầng truyền thống và hướng dẫn lựa chọn tài nguyên phù hợp cho từng bài toán thực tế.

> 📖 **Xem thêm:** Để tìm hiểu sâu về khái niệm, vai trò và ví dụ YAML của từng đối tượng cốt lõi (Pod, Service, Deployment, Ingress, Volume, ConfigMap/Secret), hãy đọc tài liệu: [Các Thành phần & Đối tượng cốt lõi trong Kubernetes](./02_kubernetes_components.md).

---

## 1. Sơ đồ kiến trúc tổng quan (Kubernetes Cluster Architecture)

Dưới đây là sơ đồ kiến trúc chính thức của một cụm Kubernetes (Cluster) từ trang chủ [kubernetes.io](https://kubernetes.io), mô tả mối quan hệ giữa **Control Plane** (Master) và các **Nodes** (Worker):

![Kiến trúc tổng quan của một cụm Kubernetes](https://kubernetes.io/images/docs/components-of-kubernetes.svg)&gt; \[!NOTE\] 💡

> Sơ đồ trên thể hiện rõ: 1. Control Plane (Master Node): Đóng vai trò là bộ não điều khiển, giám sát và quản lý vòng đời của các tài nguyên (gồm kube-apiserver, etcd, kube-scheduler, kube-controller-manager). 2. Worker Nodes: Các máy chủ vật lý hoặc máy ảo thực thi chạy các ứng dụng thực tế (chứa các Pods, trình quản lý kubelet, và bộ định tuyến kube-proxy). 3. Luồng tương tác: Người quản trị và các hệ thống CI/CD giao tiếp với cụm thông qua công cụ dòng lệnh kubectl hoặc các API requests gửi trực tiếp tới kube-apiserver.

---

## 2. Chi tiết các thành phần cốt lõi (Components Explained)

Hệ thống K8s chia làm 2 phân vùng chính:

### A. Control Plane (Master Node) — "Bộ não điều khiển"

*Chịu trách nhiệm ra quyết định toàn cục cho Cluster (lập lịch, phát hiện lỗi, co giãn tài nguyên).*

- **kube-apiserver**: Điểm liên lạc trung tâm của Cluster. Tất cả các công cụ (như lệnh `kubectl`) hay các dịch vụ nội bộ đều gọi tới API Server này.
- **etcd**: Cơ sở dữ liệu dạng key-value, lưu trữ toàn bộ trạng thái cấu hình của Cluster. Đây là nguồn dữ liệu tin cậy duy nhất (Single Source of Truth).
- **kube-scheduler**: Có nhiệm vụ tìm kiếm các Pod mới được tạo mà chưa được phân bổ node, sau đó chọn Node vật lý phù hợp nhất dựa trên RAM/CPU trống để đưa Pod vào chạy.
- **kube-controller-manager**: Chạy các tiến trình controller kiểm soát trạng thái hệ thống. Ví dụ: tự động khởi động lại Pod khi Pod bị chết (ReplicaSet Controller), quản lý Node (Node Controller).

### B. Worker Node — "Lực lượng lao động"

N*ơi trực tiếp khởi chạy các Container chứa ứng dụng của bạn.*

- **kubelet**: Một Agent chạy trên mỗi Node. Nó đảm bảo các container được khai báo trong Pod luôn chạy khỏe mạnh đúng thiết kế.
- **kube-proxy**: Trình quản lý mạng chạy trên mỗi node. Nó thiết lập các luật định tuyến IP (IPTables/IPVS) để các dịch vụ có thể kết nối được với nhau.
- **Container Runtime**: Phần mềm chạy container bên dưới (thông dụng nhất hiện nay là `containerd` hoặc `CRI-O`).

---

## 3. Khi nào sử dụng tài nguyên nào? (Decision Matrix)

Kubernetes cung cấp nhiều loại tài nguyên (Objects). Bảng dưới đây giúp bạn quyết định nên sử dụng loại nào tùy theo mục đích:

| Loại Tài Nguyên (K8s Object) | Khi nào cần sử dụng? | Ví dụ Thực tế |
| --- | --- | --- |
| **Pod** | **Tránh chạy trực tiếp.** Chỉ dùng để test nhanh một container độc lập. Pod không có tính tự phục hồi. | Test cú pháp, chạy một container script dùng 1 lần. |
| **Deployment** | Sử dụng cho các ứng dụng **Stateless** (không lưu trữ dữ liệu tại chỗ). Cho phép co giãn dễ dàng, cập nhật không downtime. | Web Frontend (Flask, React), API Backend (NodeJS, Java, Go). |
| **StatefulSet** | Sử dụng cho các ứng dụng **Stateful** (cần lưu trạng thái dữ liệu riêng biệt cho từng Pod, cần thứ tự khởi động và định danh cố định). | CSDL (PostgreSQL, MongoDB, MySQL), Cluster lưu cache (Redis Cluster, Elasticsearch). |
| **DaemonSet** | Khi bạn muốn chạy **chính xác 1 bản sao** của Pod trên tất cả các Worker Nodes (hoặc các node được chỉ định). | Dịch vụ thu gom logs (Fluentd, Logstash), giám sát hệ thống (Prometheus Node Exporter). |
| **Job / CronJob** | Sử dụng cho các tác vụ chạy xong rồi kết thúc (Job) hoặc chạy lặp lại định kỳ theo thời gian (CronJob). | Backup database tự động hàng đêm, quét dọn file rác định kỳ, gửi email bản tin tuần. |
| **Service (ClusterIP)** | Khi cần kết nối nội bộ giữa các Pod bên trong cluster. Các Pod khác sẽ gọi qua tên miền Service. | API backend kết nối với Database Redis thông qua tên miền `redis-service`. |
| **Service (NodePort)** | Dành cho môi trường test/local khi muốn mở cổng trực tiếp từ Node ảo Minikube ra máy cá nhân để gọi thử. | Expose web server ra cổng `30080` của Minikube VM để test. |
| **Ingress** | Tiếp nhận lượng truy cập HTTP/HTTPS từ ngoài internet, thực hiện định tuyến theo domain/path tới các Service nội bộ. | Truy cập `my-app.com` chuyển tới web-service, truy cập `my-app.com/api` chuyển tới api-service. |
| **ConfigMap** | Lưu cấu hình thông thường dạng plain-text không bảo mật, tách biệt file config/env khỏi mã nguồn. | Cấu hình log-level, tên database host, cổng port ứng dụng. |
| **Secret** | Lưu cấu hình nhạy cảm (mã hóa Base64), bảo vệ thông tin trước nguy cơ lộ lọt. | API Key, mật khẩu root MySQL, SSL Certificates. |
| **HPA** | Khi muốn ứng dụng tự động tăng số lượng Pod khi lượng người dùng tăng đột biến và giảm đi khi rảnh rỗi. | Tự động tăng từ 2 pod lên 5 pod vào khung giờ Flash Sale của website thương mại điện tử. |

---

## 4. Ánh xạ từ Kubernetes sang Hệ thống Hạ tầng Truyền thống

Nếu bạn đã quen với cách thiết lập hệ thống trên các máy chủ ảo (VM) truyền thống hoặc trên AWS, bảng ánh xạ sau sẽ giúp bạn dễ hình dung:

| Khái niệm Kubernetes (K8s) | Hạ tầng truyền thống (VM/OS) | Hạ tầng trên Cloud AWS |
| --- | --- | --- |
| **Pod** | Một nhóm các Container chạy chung Network/Storage trên cùng 1 server ảo. | ECS Task / Pod trên EKS. |
| **Deployment / ReplicaSet** | Template cấu hình VM chạy sau một Auto Scaling Group để duy trì đúng số lượng máy chủ mong muốn. | AWS Auto Scaling Group (ASG) quản lý các EC2 Instances. |
| **Service (ClusterIP)** | Máy chủ DNS nội bộ kết hợp cơ chế Load Balancing nội bộ để chia tải. | AWS Route 53 private hosted zone + Internal Application Load Balancer. |
| **Service (NodePort)** | Cơ chế Port Forwarding (NAT) chuyển tiếp port từ card mạng vật lý vào card ảo. | AWS Target Group ánh xạ cổng EC2 Instance. |
| **Ingress Controller** | Hệ thống Web Server trung tâm làm nhiệm vụ Reverse Proxy & Routing. | Nginx Reverse Proxy / AWS Application Load Balancer (ALB). |
| **Persistent Volume (PV/PVC)** | Ổ đĩa cứng gắn mạng dạng Network Attached Storage (NAS/SAN) hoặc ổ đĩa mạng mount qua giao thức NFS. | AWS EBS Volume (Elastic Block Store) hoặc AWS EFS (Elastic File System). |
| **ConfigMap / Secret** | File cấu hình lưu trên đĩa cứng hệ thống (`/etc/config.conf`) hoặc các biến môi trường (`ENV`) cấu hình trên máy. | AWS Systems Manager Parameter Store / AWS Secrets Manager. |
| **Horizontal Pod Autoscaler (HPA)** | Script tự động phát hiện tải hệ thống CPU và kích hoạt tăng giảm máy chủ VM trong ASG. | AWS Auto Scaling Policy dựa trên CPU Utilization. |
