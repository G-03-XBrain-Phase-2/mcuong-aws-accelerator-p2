# Lab 06 (Chính thức): Xây Dựng Mini K8s Platform Trên Minikube

## 1. Mục tiêu & Đề bài bài lab
Xây dựng một hệ thống nền tảng Kubernetes thu nhỏ (Mini K8s Platform) trên máy cá nhân bằng Minikube để triển khai một ứng dụng Multi-tier (Frontend Web + Database Cache Redis) đáp ứng các tiêu chuẩn vận hành thực tế:
* **Networking & Service Discovery:** Liên kết an toàn giữa Frontend và Backend thông qua Service nội bộ. Expose Frontend ra ngoài qua tên miền tự chọn nhờ **Ingress Controller**.
* **Configuration & Security:** Tách biệt cấu hình ứng dụng qua **ConfigMap** và bảo mật mật khẩu kết nối Redis bằng **Secret**.
* **Reliability (Self-Healing):** Cấu hình các cơ chế tự phát hiện và phục hồi lỗi với **Liveness & Readiness Probes**.
* **Resource Control:** Đảm bảo tính ổn định của Cluster bằng cách giới hạn tài nguyên CPU/RAM cho từng Container.
* **Auto-scaling:** Tự động co giãn số lượng bản sao Frontend bằng **Horizontal Pod Autoscaler (HPA)** dựa trên CPU thực tế.

---

## 2. Mô hình kiến trúc ứng dụng (Architecture)

```
                       [ Trình duyệt Máy Client ]
                                   │
                           (my-k8s-platform.local)
                                   ▼
                    [ Ingress Controller (Nginx) ]
                                   │ (Routing path: /)
                                   ▼
                  [ Frontend Service (ClusterIP:80) ]
                                   │
               ┌───────────────────┴───────────────────┐
               ▼                                       ▼
     [ Frontend Pod (Replica 1) ]             [ Frontend Pod (Replica 2) ]
       - Mount: python code (CM)                - Mount: python code (CM)
       - Env: REDIS_HOST (CM)                   - Env: REDIS_HOST (CM)
       - Env: REDIS_PASS (Secret)               - Env: REDIS_PASS (Secret)
       - Checks: Liveness/Readiness             - Checks: Liveness/Readiness
       - Autoscaled by HPA                      - Autoscaled by HPA
               │                                       │
               └───────────────────┬───────────────────┘
                                   │ (Port 6379, Auth)
                                   ▼
                    [ Redis Service (ClusterIP:6379) ]
                                   │
                                   ▼
                       [ Redis Pod (Database Cache) ]
```

> [!TIP]
> **Giải pháp tối ưu chạy local:** Thay vì bắt bạn phải build Dockerfile và push image lên Docker Hub, bài lab này sử dụng kỹ thuật mount trực tiếp mã nguồn ứng dụng Python (Flask) từ ConfigMap vào một container chạy image `python:3.10-alpine` tiêu chuẩn. Bạn hoàn toàn có thể deploy và chạy ứng dụng chỉ với các file YAML định nghĩa sẵn!

---

## 3. Chuẩn bị thư mục thực hành
Toàn bộ mã nguồn YAML của bài Lab được lưu trữ tại thư mục: `practice/w8-lab/lab-06-mini-k8s-platform/`

---

## 4. Các bước thực hiện Step-by-Step

### Bước 1: Khởi động Minikube và kích hoạt các Addons
Đảm bảo Minikube đã được khởi động và các tính năng Ingress, Metrics-server được bật:
```bash
minikube start --driver=docker --cpus=2 --memory=4096

# Kích hoạt Ingress Controller
minikube addons enable ingress

# Kích hoạt Metrics Server để chạy HPA
minikube addons enable metrics-server
```

---

### Bước 2: Thiết lập Security & Configuration (Secret & ConfigMap)
Chúng ta cần bảo mật thông tin kết nối Database và tách riêng thông số cấu hình.

1. **Tạo Database Password Secret:**
   Mã hóa mật khẩu database sang Base64:
   ```bash
   echo -n "StrongAdminPass123" | base64
   # Kết quả: U3Ryb25nQWRtaW5QYXNzMTIz
   ```

   Tạo file [01-secrets.yaml](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/w8-lab/lab-06-mini-k8s-platform/01-secrets.yaml):
   ```yaml
   apiVersion: v1
   kind: Secret
   metadata:
     name: db-credentials
   type: Opaque
   data:
     redis-password: U3Ryb25nQWRtaW5QYXNzMTIz
   ```

2. **Tạo Ứng dụng Frontend & Cấu hình môi trường (ConfigMap):**
   Chúng ta sẽ định nghĩa ConfigMap chứa 2 phần:
   - Biến môi trường (`REDIS_HOST`, `REDIS_PORT`).
   - Mã nguồn ứng dụng Python Flask (`app.py`) có nhiệm vụ kết nối Redis, tăng số lượt truy cập và trả về trang HTML có giao diện hiển thị chuyên nghiệp.

   Tạo file [02-configmaps.yaml](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/w8-lab/lab-06-mini-k8s-platform/02-configmaps.yaml):
   ```yaml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: app-configurations
   data:
     REDIS_HOST: "redis-service"
     REDIS_PORT: "6379"
     app.py: |
       import os
       import time
       from flask import Flask, render_template_string
       import redis

       app = Flask(__name__)

       # Lấy cấu hình từ môi trường
       redis_host = os.environ.get('REDIS_HOST', 'localhost')
       redis_port = int(os.environ.get('REDIS_PORT', 6379))
       redis_pass = os.environ.get('REDIS_PASSWORD', '')

       # Kết nối database Redis
       db = redis.Redis(host=redis_host, port=redis_port, password=redis_pass, decode_responses=True)

       def get_hit_count():
           retries = 5
           while True:
               try:
                   return db.incr('hits')
               except redis.exceptions.ConnectionError as exc:
                   if retries == 0:
                       raise exc
                   retries -= 1
                   time.sleep(0.5)

       @app.route('/')
       def hello():
           try:
               count = get_hit_count()
           except Exception as e:
               return f"<h1 style='color:red;'>Lỗi kết nối CSDL: {str(e)}</h1>", 500
           
           html = """
           <!DOCTYPE html>
           <html>
           <head>
               <title>Mini K8s Platform</title>
               <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600&display=swap" rel="stylesheet">
               <style>
                   body {
                       font-family: 'Inter', sans-serif;
                       background: radial-gradient(circle, #1e3c72 0%, #2a5298 100%);
                       color: white;
                       height: 100vh;
                       display: flex;
                       justify-content: center;
                       align-items: center;
                       margin: 0;
                   }
                   .card {
                       background: rgba(255, 255, 255, 0.1);
                       backdrop-filter: blur(10px);
                       border-radius: 16px;
                       padding: 40px;
                       text-align: center;
                       box-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.3);
                       border: 1px solid rgba(255, 255, 255, 0.2);
                       max-width: 450px;
                   }
                   h1 { font-weight: 600; margin-bottom: 10px; font-size: 28px; }
                   p { font-weight: 300; opacity: 0.8; margin-bottom: 30px; }
                   .counter {
                       font-size: 64px;
                       font-weight: 600;
                       background: linear-gradient(45deg, #ff007f, #7f00ff);
                       -webkit-background-clip: text;
                       -webkit-text-fill-color: transparent;
                       margin: 20px 0;
                       animation: pulse 2s infinite;
                   }
                   .badge {
                       background: #00e676;
                       color: #0c101b;
                       padding: 6px 12px;
                       border-radius: 20px;
                       font-size: 12px;
                       font-weight: 600;
                       text-transform: uppercase;
                   }
                   @keyframes pulse {
                       0% { transform: scale(1); }
                       50% { transform: scale(1.05); }
                       100% { transform: scale(1); }
                   }
               </style>
           </head>
           <body>
               <div class="card">
                   <span class="badge">K8s Local Cluster Active</span>
                   <h1>Trang Chủ Ứng Dụng</h1>
                   <p>Ứng dụng Multi-tier chạy trên nền tảng Minikube local</p>
                   <div class="counter">{count}</div>
                   <p>Lượt truy cập hệ thống đã được lưu vào Redis</p>
               </div>
           </body>
           </html>
           """
           return render_template_string(html)

       # Endpoint kiểm tra sức khỏe
       @app.route('/healthz')
       def healthz():
           # Kiểm tra ping đến Redis
           db.ping()
           return "OK", 200

       if __name__ == "__main__":
           app.run(host="0.0.0.0", port=8000)
   ```

---

### Bước 3: Triển khai Cơ sở dữ liệu (Redis Backend Tier)

Chúng ta triển khai một Pod chạy Redis có xác thực mật khẩu lấy từ Secret, giới hạn tài nguyên và cấu hình Liveness/Readiness Probe kiểm tra cổng 6379.

Tạo file [03-redis-backend.yaml](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/w8-lab/lab-06-mini-k8s-platform/03-redis-backend.yaml):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-backend
  labels:
    app: redis
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:6.2-alpine
        # Yêu cầu khởi động redis với cờ xác thực yêu cầu mật khẩu
        args: ["redis-server", "--requirepass", "$(REDIS_PASSWORD)"]
        env:
        - name: REDIS_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: redis-password
        ports:
        - containerPort: 6379
          name: redis
        resources:
          requests:
            cpu: "50m"
            memory: "64Mi"
          limits:
            cpu: "100m"
            memory: "128Mi"
        livenessProbe:
          tcpSocket:
            port: 6379
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          tcpSocket:
            port: 6379
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: redis-service
spec:
  type: ClusterIP
  ports:
  - port: 6379
    targetPort: 6379
  selector:
    app: redis
```

---

### Bước 4: Triển khai Web Application (Frontend Tier)

Frontend chạy Flask cần các điều kiện:
1. Đọc code Python `app.py` từ ConfigMap thông qua Volume Mount.
2. Cài đặt các thư viện cần thiết trước khi khởi động (`flask`, `redis`) thông qua InitContainer hoặc chạy trực tiếp bằng cách ghi đè command chạy của image python.
3. Liên kết các biến môi trường cấu hình và secret mật khẩu.
4. Cấu hình kiểm tra Probes trên đường dẫn `/healthz` cổng `8000`.

Tạo file [04-frontend-web.yaml](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/w8-lab/lab-06-mini-k8s-platform/04-frontend-web.yaml):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-frontend
  labels:
    app: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: python-web
        image: python:3.10-alpine
        # Cài thư viện và chạy ứng dụng từ file code mounted
        command: ["/bin/sh", "-c"]
        args:
        - |
          pip install --no-cache-dir flask redis
          python /app/app.py
        env:
        - name: REDIS_HOST
          valueFrom:
            configMapKeyRef:
              name: app-configurations
              key: REDIS_HOST
        - name: REDIS_PORT
          valueFrom:
            configMapKeyRef:
              name: app-configurations
              key: REDIS_PORT
        - name: REDIS_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: redis-password
        ports:
        - containerPort: 8000
          name: http
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "250m"
            memory: "256Mi"
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8000
          initialDelaySeconds: 30 # Tăng thời gian chờ khởi tạo do container cần cài pip install
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /healthz
            port: 8000
          initialDelaySeconds: 20
          periodSeconds: 5
        volumeMounts:
        - name: code-volume
          mountPath: /app
      volumes:
      - name: code-volume
        configMap:
          name: app-configurations
          items:
          - key: app.py
            path: app.py
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 8000
  selector:
    app: frontend
```

---

### Bước 5: Cấu hình Ingress & Auto-scaling (HPA)

1. **Định cấu hình Ingress:**
   Cấp tên miền `my-k8s-platform.local` ánh xạ vào ClusterIP của frontend.

   Tạo file [05-ingress.yaml](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/w8-lab/lab-06-mini-k8s-platform/05-ingress.yaml):
   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   metadata:
     name: platform-ingress
     annotations:
       nginx.ingress.kubernetes.io/rewrite-target: /
   spec:
     ingressClassName: nginx
     rules:
     - host: my-k8s-platform.local
       http:
         paths:
         - path: /
           pathType: Prefix
           backend:
             service:
               name: frontend-service
               port:
                 number: 80
   ```

2. **Định cấu hình HPA:**
   Co giãn Frontend từ 2 đến 5 Pod, tự động scale khi CPU trung bình vượt quá 60%.

   Tạo file [06-hpa.yaml](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/w8-lab/lab-06-mini-k8s-platform/06-hpa.yaml):
   ```yaml
   apiVersion: autoscaling/v2
   kind: HorizontalPodAutoscaler
   metadata:
     name: frontend-hpa
   spec:
     scaleTargetRef:
       apiVersion: apps/v1
       kind: Deployment
       name: web-frontend
     minReplicas: 2
     maxReplicas: 5
     metrics:
     - type: Resource
       resource:
         name: cpu
         target:
           type: Utilization
           averageUtilization: 60
   ```

---

## 5. Thực thi triển khai & Kiểm tra kết quả

1. **Deploy toàn bộ tài nguyên lên K8s:**
   Áp dụng lần lượt các file cấu hình theo thứ tự:
   ```bash
   cd practice/w8-lab/lab-06-mini-k8s-platform
   
   kubectl apply -f 01-secrets.yaml
   kubectl apply -f 02-configmaps.yaml
   kubectl apply -f 03-redis-backend.yaml
   kubectl apply -f 04-frontend-web.yaml
   kubectl apply -f 05-ingress.yaml
   kubectl apply -f 06-hpa.yaml
   ```

2. **Theo dõi quá trình khởi chạy (Cực kỳ quan trọng):**
   ```bash
   kubectl get pods -w
   ```
   > [!NOTE]
   > Do Frontend Web cần cài đặt thêm thư viện pip (`flask`, `redis`) ở câu lệnh khởi động, Container sẽ mất khoảng 15-25 giây ở trạng thái chạy nền để cài đặt trước khi chuyển sang `Ready: 1/1`. Hãy kiên nhẫn đợi cho tới khi cả 3 Pod (1 Redis + 2 Frontend Web) đều Running và Ready.

3. **Ánh xạ DNS cục bộ:**
   Lấy IP của Minikube và đưa vào file `/etc/hosts`:
   ```bash
   minikube ip
   sudo sh -c "echo '$(minikube ip) my-k8s-platform.local' >> /etc/hosts"
   ```

4. **Truy cập và kiểm nghiệm:**
   Mở trình duyệt hoặc dùng Terminal chạy lệnh:
   ```bash
   curl http://my-k8s-platform.local
   ```
   *Kết quả mong đợi: Một trang HTML hiển thị đẹp mắt với bộ đếm lượt truy cập bắt đầu từ số 1. Khi bạn F5 hoặc lặp lại lệnh curl, bộ đếm sẽ tự động tăng dần (1, 2, 3, 4...). Điều này chứng tỏ Frontend và Database Redis đã bắt tay kết nối thành công!*

5. **Giám sát tải và Scaling:**
   Bạn có thể sinh tải cho frontend giống như bài Lab 05 để chứng kiến HPA tự động nhân bản Frontend từ 2 lên 5 bản sao để chia sẻ tải:
   ```bash
   kubectl run -i --tty --rm load-generator --image=busybox:1.35 --restart=Never -- /bin/sh -c "while true; do wget -q -O- http://frontend-service; done"
   ```

---

## 6. Dọn dẹp tài nguyên
```bash
kubectl delete -f 06-hpa.yaml
kubectl delete -f 05-ingress.yaml
kubectl delete -f 04-frontend-web.yaml
kubectl delete -f 03-redis-backend.yaml
kubectl delete -f 02-configmaps.yaml
kubectl delete -f 01-secrets.yaml
```
Khuyên dùng: Bạn có thể sửa file `/etc/hosts` để gỡ bỏ dòng tên miền ảo vừa thêm.
