# Lab 02: Kubernetes Networking — Services & Ingress

## 1. Mục tiêu bài lab
* Hiểu cách giao tiếp mạng trong K8s thông qua đối tượng **Service** (ClusterIP, NodePort).
* Hiểu cách tiếp xúc ứng dụng ra ngoài internet qua tên miền (Local domain) sử dụng **Ingress Controller** trên Minikube.
* Thực hành định tuyến traffic qua các Service khác nhau.

---

## 2. Chuẩn bị thư mục thực hành
Tạo các file YAML trong thư mục: `practice/w8-lab/lab-02-networking/`

---

## 3. Các bước thực hiện Step-by-Step

### Bước 1: Kích hoạt Ingress Controller trên Minikube
Mặc định Minikube không bật Ingress Controller. Chúng ta cần bật addon này lên:
```bash
minikube addons enable ingress
```
*Chờ khoảng 1-2 phút để Pod của Ingress Controller chuyển sang trạng thái `Running`.* Kiểm tra trạng thái bằng lệnh:
```bash
kubectl get pods -n ingress-nginx
```

---

### Bước 2: Triển khai ứng dụng Web mẫu
Chúng ta sẽ triển khai một web server nhỏ trả về thông tin HTTP header để kiểm tra.

1. Tạo file [web-deployment.yaml](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/w8-lab/lab-02-networking/web-deployment.yaml):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app-deploy
  labels:
    app: web-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: hashicorp-http-echo
        image: hashicorp/http-echo:0.2.3
        args:
        - "-text=Welcome to the K8s Networking Lab!"
        ports:
        - containerPort: 5678
```

2. Áp dụng Deployment:
```bash
kubectl apply -f practice/w8-lab/lab-02-networking/web-deployment.yaml
```

---

### Bước 3: Tạo ClusterIP Service (Giao tiếp nội bộ)
**ClusterIP** là Service mặc định của K8s, nó cung cấp một địa chỉ IP ảo cố định cho các Pod giao tiếp nội bộ trong cụm.

1. Tạo file [web-service-clusterip.yaml](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/w8-lab/lab-02-networking/web-service-clusterip.yaml):
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service-clusterip
spec:
  type: ClusterIP
  selector:
    app: web-app
  ports:
  - port: 80         # Cổng Service lắng nghe bên trong Cluster
    targetPort: 5678 # Cổng của Container đang chạy ứng dụng
```

2. Áp dụng Service:
```bash
kubectl apply -f practice/w8-lab/lab-02-networking/web-service-clusterip.yaml
```

3. Kiểm tra thông tin Service:
```bash
kubectl get service web-service-clusterip
```
> [!NOTE]
> Bạn sẽ nhận được IP ảo của ClusterIP (ví dụ `10.96.x.x`). IP này chỉ truy cập được từ bên trong cluster K8s (ví dụ từ một Pod khác). Máy tính cá nhân của bạn không thể trực tiếp truy cập vào IP này.

---

### Bước 4: Tạo NodePort Service (Truy cập qua Port của Node)
**NodePort** mở một cổng cố định trên toàn bộ Node của Cluster (tầm cổng `30000-32767`). Bất kỳ traffic nào gửi tới cổng này của Node sẽ được forward vào Service.

1. Tạo file [web-service-nodeport.yaml](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/w8-lab/lab-02-networking/web-service-nodeport.yaml):
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service-nodeport
spec:
  type: NodePort
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 5678
    nodePort: 30080  # Đặt cứng cổng ngoài của Node (30000-32767)
```

2. Áp dụng Service:
```bash
kubectl apply -f practice/w8-lab/lab-02-networking/web-service-nodeport.yaml
```

3. Truy cập thông qua Minikube IP:
```bash
# Lấy địa chỉ IP của Minikube VM/Container
minikube ip

# Thực hiện curl truy cập thử qua cổng NodePort
curl $(minikube ip):30080
```
*Kết quả trả về sẽ là: `Welcome to the K8s Networking Lab!`*

---

### Bước 5: Cấu hình Ingress (Truy cập bằng tên miền thông qua Ingress Controller)
**Ingress** quản lý luồng traffic từ bên ngoài đi vào các Service bên trong cluster dựa trên URL path hoặc Host header (Tên miền).

1. Tạo file [web-ingress.yaml](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/w8-lab/lab-02-networking/web-ingress.yaml):
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: my-k8s-app.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service-clusterip
            port:
              number: 80
```

2. Áp dụng Ingress:
```bash
kubectl apply -f practice/w8-lab/lab-02-networking/web-ingress.yaml
```

3. Cập nhật file `/etc/hosts` trên máy tính cá nhân để ánh xạ tên miền `my-k8s-app.local` sang IP của Minikube:
```bash
# Lấy IP Minikube
minikube ip

# Mở terminal và thêm dòng cấu hình sau vào file /etc/hosts (yêu cầu quyền sudo)
sudo sh -c "echo '$(minikube ip) my-k8s-app.local' >> /etc/hosts"
```

4. Truy cập kiểm thử bằng domain:
```bash
curl http://my-k8s-app.local
```
*Bạn sẽ nhận lại dòng thông báo chào mừng thông qua Ingress định tuyến tới ClusterIP.*

---

### Bước 6: Dọn dẹp tài nguyên
```bash
kubectl delete -f practice/w8-lab/lab-02-networking/web-ingress.yaml
kubectl delete -f practice/w8-lab/lab-02-networking/web-service-nodeport.yaml
kubectl delete -f practice/w8-lab/lab-02-networking/web-service-clusterip.yaml
kubectl delete -f practice/w8-lab/lab-02-networking/web-deployment.yaml
```
Khôi phục file `/etc/hosts` bằng cách mở `/etc/hosts` bằng editor và xóa dòng vừa thêm nếu bạn không muốn giữ tên miền ảo này nữa.
