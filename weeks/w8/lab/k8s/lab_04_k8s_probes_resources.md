# Lab 04: Reliability & Resource Management — Probes & Resource Limits

## 1. Mục tiêu bài lab
* Hiểu cách cấu hình **Probes** để K8s tự động kiểm tra trạng thái sức khỏe của ứng dụng (Self-healing & Traffic routing).
* Phân biệt giữa **Liveness Probe** (khi nào cần restart container) và **Readiness Probe** (khi nào ứng dụng sẵn sàng nhận traffic).
* Hiểu cách quản lý tài nguyên trong cluster thông qua **Resource Requests** (Tài nguyên yêu cầu tối thiểu để lập lịch) và **Resource Limits** (Tài nguyên tối đa container được phép dùng).
* Quan sát lỗi **OOMKilled** (Out Of Memory) khi container dùng vượt giới hạn RAM cho phép.

---

## 2. Chuẩn bị thư mục thực hành
Tạo các file YAML trong thư mục: `practice/w8-lab/lab-04-reliability/`

---

## 3. Các bước thực hiện Step-by-Step

### Bước 1: Cấu hình Liveness & Readiness Probes (Tự phục hồi & Điều hướng thông minh)
Chúng ta sẽ triển khai một ứng dụng web mô phỏng:
* Khởi đầu khỏe mạnh trong 15 giây đầu.
* Sau 15 giây, ứng dụng sẽ gặp lỗi nội bộ và trả về mã lỗi HTTP 500 cho endpoint `/healthz`.

1. Tạo file [app-probes.yaml](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/w8-lab/lab-04-reliability/app-probes.yaml):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: probe-demo-deploy
spec:
  replicas: 1
  selector:
    matchLabels:
      app: probe-demo
  template:
    metadata:
      labels:
        app: probe-demo
    spec:
      containers:
      - name: probe-container
        image: k8s.gcr.io/busybox
        args:
        - /bin/sh
        - -c
        - |
          touch /tmp/healthy;
          sleep 15;
          rm -f /tmp/healthy;
          sleep 600
        livenessProbe:
          # Kiểm tra bằng lệnh shell. Nếu mã trả về khác 0, Container sẽ bị restart
          exec:
            command:
            - cat
            - /tmp/healthy
          initialDelaySeconds: 5  # Chờ 5s sau khi container khởi động trước khi check lần đầu
          periodSeconds: 5        # Tần suất kiểm tra là mỗi 5s một lần
        readinessProbe:
          # Chỉ dẫn K8s chỉ gửi traffic vào Pod khi file này tồn tại
          exec:
            command:
            - cat
            - /tmp/healthy
          initialDelaySeconds: 5
          periodSeconds: 5
```

2. Áp dụng Deployment:
```bash
kubectl apply -f practice/w8-lab/lab-04-reliability/app-probes.yaml
```

3. Theo dõi trạng thái của Pod liên tục:
```bash
kubectl get pods -w
```
> [!NOTE]
> **Quan sát hiện tượng:**
> - Trong 15 giây đầu, Pod sẽ ở trạng thái `Running` và cột `READY` là `1/1` (Readiness pass).
> - Sau 15 giây, file `/tmp/healthy` bị xóa. Readiness check thất bại. READY sẽ chuyển sang `0/1` (không nhận traffic).
> - Sau vài giây tiếp theo, Liveness check cũng thất bại liên tục (3 lần mặc định). K8s sẽ tiến hành khởi động lại container (cột `RESTARTS` tăng lên 1).
> - Sau khi khởi động lại, chu trình lặp lại (Pod lại Ready rồi lại bị Restart).
> *Nhấn `Ctrl + C` để thoát chế độ xem realtime.*

---

### Bước 2: Thiết lập Resource Requests & Limits
K8s cho phép ta kiểm soát lượng CPU và RAM mà các Container sử dụng.
* **Requests:** Mức tối thiểu mà Node vật lý phải có trống để Pod có thể được xếp lịch chạy vào.
* **Limits:** Mức tối đa Container được phép tiêu thụ.

1. Tạo file [app-resources.yaml](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/w8-lab/lab-04-reliability/app-resources.yaml) đặt giới hạn hợp lý cho một dịch vụ web:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: resource-demo-pod
spec:
  containers:
  - name: web
    image: nginx:alpine
    resources:
      requests:
        memory: "64Mi"   # Yêu cầu tối thiểu 64 Megabytes RAM
        cpu: "100m"      # Yêu cầu tối thiểu 0.1 vCPU Core
      limits:
        memory: "128Mi"  # Không được dùng quá 128 Megabytes RAM
        cpu: "200m"      # Không được dùng quá 0.2 vCPU Core
```

2. Áp dụng Pod:
```bash
kubectl apply -f practice/w8-lab/lab-04-reliability/app-resources.yaml
```

3. Kiểm tra thông số tài nguyên thực tế:
```bash
kubectl describe pod resource-demo-pod
```

---

### Bước 3: Mô phỏng lỗi OutOfMemory (OOMKilled)
Chúng ta sẽ cố ý cấu hình giới hạn RAM cực kỳ thấp (20MB) và khởi chạy một container cố tình ngốn nhiều RAM hơn thế để xem K8s phản ứng ra sao.

1. Tạo file [app-oom.yaml](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/w8-lab/lab-04-reliability/app-oom.yaml):
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: oom-demo-pod
spec:
  containers:
  - name: oom-container
    image: pollyduan/stress
    args:
    - "--vm"
    - "1"
    - "--vm-bytes"
    - "50M" # Cố tình tiêu tốn 50 Megabytes RAM
    resources:
      limits:
        memory: "20Mi" # Giới hạn tối đa cực thấp chỉ cho phép 20 Megabytes RAM
```

2. Áp dụng Pod:
```bash
kubectl apply -f practice/w8-lab/lab-04-reliability/app-oom.yaml
```

3. Theo dõi trạng thái của Pod liên tiếp:
```bash
kubectl get pods oom-demo-pod -w
```
Bạn sẽ nhanh chóng thấy trạng thái Pod chuyển thành `OOMKilled` hoặc `CrashLoopBackOff`.

4. Xem chi tiết nguyên nhân chết của container:
```bash
kubectl describe pod oom-demo-pod
```
*Hãy tìm dòng: `Last State: Terminated` và `Reason: OOMKilled` trong log output.*

---

### Bước 4: Dọn dẹp tài nguyên
```bash
kubectl delete -f practice/w8-lab/lab-04-reliability/app-oom.yaml
kubectl delete -f practice/w8-lab/lab-04-reliability/app-resources.yaml
kubectl delete -f practice/w8-lab/lab-04-reliability/app-probes.yaml
```
