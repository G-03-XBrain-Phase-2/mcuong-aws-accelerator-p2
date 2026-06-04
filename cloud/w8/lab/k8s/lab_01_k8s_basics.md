# Lab 01: Kubernetes Basics — Pods & Deployments

## 1. Mục tiêu bài lab
* Hiểu cách định nghĩa và chạy các thực thể cơ bản nhất trong Kubernetes: **Pod** và **Deployment**.
* Thành thạo các câu lệnh `kubectl` cơ bản để xem trạng thái, logs, troubleshoot và dọn dẹp tài nguyên.
* Hiểu vai trò của **Deployment** trong việc tự động phục hồi (self-healing) và cập nhật ứng dụng.

---

## 2. Chuẩn bị thư mục thực hành
Tạo các file YAML trong thư mục: `practice/w8-lab/lab-01-basics/`

---

## 3. Các bước thực hiện Step-by-Step

### Bước 1: Khởi chạy và kiểm tra Minikube
Đảm bảo Minikube đang chạy:
```bash
minikube status
```
Nếu chưa chạy, hãy khởi động bằng lệnh:
```bash
minikube start --driver=docker
```

---

### Bước 2: Tạo và chạy một Pod đơn lẻ (Tĩnh)
**Pod** là đơn vị triển khai nhỏ nhất trong Kubernetes. Một Pod có thể chứa một hoặc nhiều Container dùng chung Network Namespace và Storage.

1. Tạo file cấu hình Pod [pod-nginx.yaml](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/w8-lab/lab-01-basics/pod-nginx.yaml):
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-nginx-pod
  labels:
    app: web
    env: dev
spec:
  containers:
  - name: nginx-container
    image: nginx:alpine
    ports:
    - containerPort: 80
```

2. Triển khai Pod lên cluster:
```bash
kubectl apply -f practice/w8-lab/lab-01-basics/pod-nginx.yaml
```

3. Kiểm tra trạng thái Pod:
```bash
# Xem danh sách Pod
kubectl get pods

# Xem thông tin chi tiết (IP, Event)
kubectl describe pod my-nginx-pod

# Kiểm tra logs của container trong Pod
kubectl logs my-nginx-pod
```

4. Truy cập nhanh vào Pod để test (Port-forwarding):
```bash
# Forward port 8080 của máy local vào port 80 của Pod
kubectl port-forward my-nginx-pod 8080:80
```
*Mở trình duyệt truy cập `http://localhost:8080` hoặc chạy lệnh `curl localhost:8080` ở terminal khác để kiểm tra.*
*Nhấn `Ctrl + C` để dừng port-forwarding.*

---

### Bước 3: Tạo và chạy một Deployment (Khuyên dùng trong Production)
Thay vì chạy Pod trực tiếp, trong thực tế chúng ta luôn dùng **Deployment**. Deployment quản lý **ReplicaSet**, giúp tự động duy trì số lượng Pod mong muốn và hỗ trợ cơ chế Rolling Update (cập nhật không gián đoạn).

1. Tạo file cấu hình Deployment [deployment-nginx.yaml](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/w8-lab/lab-01-basics/deployment-nginx.yaml):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: web-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: nginx
        image: nginx:1.21.6-alpine
        ports:
        - containerPort: 80
```

2. Áp dụng Deployment:
```bash
kubectl apply -f practice/w8-lab/lab-01-basics/deployment-nginx.yaml
```

3. Kiểm tra các tài nguyên được tạo ra:
```bash
# Xem danh sách Deployments
kubectl get deployments

# Xem danh sách ReplicaSet (được tạo bởi Deployment)
kubectl get replicaset (hoặc kubectl get rs)

# Xem danh sách Pod (phải có 3 Pod nginx đang chạy)
kubectl get pods -l app=web-app
```

---

### Bước 4: Kiểm tra tính tự phục hồi (Self-Healing)
Một trong những điểm mạnh nhất của K8s là khả năng tự phục hồi.

1. Xem danh sách Pod để lấy tên một Pod bất kỳ:
```bash
kubectl get pods
```

2. Xóa thủ công một Pod thuộc Deployment:
```bash
kubectl delete pod <TEN-POD-VUA-LAY>
```

3. Ngay lập tức kiểm tra lại danh sách Pod:
```bash
kubectl get pods
```
> [!NOTE]
> Bạn sẽ thấy Pod cũ bị xóa đi nhưng một Pod mới với tên ngẫu nhiên khác sẽ lập tức được tạo ra để duy trì đúng số lượng replicas bằng 3 như khai báo trong Deployment.

---

### Bước 5: Cập nhật ứng dụng (Rolling Update) & Rollback

1. Thay đổi phiên bản ảnh đĩa (Image version) từ `nginx:1.21.6-alpine` sang bản mới hơn `nginx:alpine`:
```bash
kubectl set image deployment/nginx-deployment nginx=nginx:alpine
```

2. Quan sát quá trình cập nhật diễn ra từng Pod một để tránh gián đoạn dịch vụ:
```bash
kubectl rollout status deployment/nginx-deployment
```

3. Nếu phát hiện phiên bản mới bị lỗi hoặc muốn quay lại phiên bản cũ:
```bash
# Xem lịch sử các lần deploy
kubectl rollout history deployment/nginx-deployment

# Quay lại phiên bản ngay trước đó
kubectl rollout undo deployment/nginx-deployment
```

---

### Bước 6: Dọn dẹp tài nguyên
Sau khi hoàn thành bài thực hành, hãy dọn dẹp các tài nguyên đã tạo để tránh tốn RAM máy ảo:
```bash
kubectl delete -f practice/w8-lab/lab-01-basics/pod-nginx.yaml
kubectl delete -f practice/w8-lab/lab-01-basics/deployment-nginx.yaml
```
Khuyên dùng: luôn kiểm tra lại bằng lệnh `kubectl get all` để đảm bảo tài nguyên đã được xóa sạch.
