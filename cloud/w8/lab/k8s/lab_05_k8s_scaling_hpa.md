# Lab 05: Auto-scaling — Horizontal Pod Autoscaler (HPA)

## 1. Mục tiêu bài lab
* Hiểu cơ chế co giãn tài nguyên tự động theo chiều ngang (Horizontal Pod Autoscaling).
* Biết cách kích hoạt và sử dụng **Metrics Server** trên Minikube để giám sát tài nguyên CPU/RAM.
* Thiết lập cấu hình **Horizontal Pod Autoscaler (HPA)** cho ứng dụng.
* Mô phỏng tạo tải giả lập (Load generator) để chứng kiến hệ thống tự động nhân bản thêm Pod khi quá tải và tự động thu hẹp lại khi hết tải.

---

## 2. Chuẩn bị thư mục thực hành
Tạo các file YAML trong thư mục: `practice/w8-lab/lab-05-scaling/`

---

## 3. Các bước thực hiện Step-by-Step

### Bước 1: Kích hoạt Metrics Server trên Minikube
HPA cần dữ liệu về mức tiêu thụ CPU/RAM thực tế của các Pod để quyết định khi nào cần scale. Dữ liệu này được cung cấp bởi Metrics Server.

1. Bật Addon Metrics Server:
```bash
minikube addons enable metrics-server
```

2. Kiểm tra xem Metrics Server đã chạy ổn định chưa (đôi khi mất 1-2 phút):
```bash
kubectl get pods -n kube-system -l k8s-app=metrics-server
```

3. Thử nghiệm xem đã lấy được thông số tài nguyên chưa:
```bash
# Xem thông số CPU/RAM của Node
kubectl top nodes

# Xem thông số CPU/RAM của Pod (nếu chưa có pod nào chạy, lệnh sẽ trả về trống)
kubectl top pods
```

---

### Bước 2: Triển khai Ứng dụng mẫu có giới hạn tài nguyên
Để HPA có thể tính toán tỷ lệ phần trăm CPU tiêu thụ, bắt buộc Deployment phải khai báo `resources.requests.cpu`.

1. Tạo file [app-apache.yaml](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/w8-lab/lab-05-scaling/app-apache.yaml) (sử dụng một image PHP có sẵn hàm tính toán nặng để dễ sinh tải):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: php-apache
spec:
  replicas: 1
  selector:
    matchLabels:
      run: php-apache
  template:
    metadata:
      labels:
        run: php-apache
    spec:
      containers:
      - name: php-apache
        image: registry.k8s.io/hpa-example
        ports:
        - containerPort: 80
        resources:
          limits:
            cpu: 500m
          requests:
            cpu: 200m # HPA sẽ căn cứ vào mức 200m CPU này làm mốc 100%
---
apiVersion: v1
kind: Service
metadata:
  name: php-apache
spec:
  ports:
  - port: 80
  selector:
    run: php-apache
```

2. Triển khai ứng dụng:
```bash
kubectl apply -f practice/w8-lab/lab-05-scaling/app-apache.yaml
```

---

### Bước 3: Khởi tạo Horizontal Pod Autoscaler (HPA)
Chúng ta sẽ cấu hình HPA:
* Duy trì số lượng Pod tối thiểu là 1.
* Số lượng Pod tối đa khi quá tải là 5.
* Mục tiêu: Duy trì mức tiêu thụ CPU trung bình của các Pod ở khoảng 50%. Nếu vượt qua 50%, HPA sẽ tự động tạo thêm Pod mới.

1. Tạo file [app-hpa.yaml](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/w8-lab/lab-05-scaling/app-hpa.yaml):
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: php-apache-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: php-apache
  minReplicas: 1
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
```

2. Áp dụng HPA:
```bash
kubectl apply -f practice/w8-lab/lab-05-scaling/app-hpa.yaml
```

3. Kiểm tra danh sách HPA hiện tại:
```bash
kubectl get hpa
```
*Lưu ý: Ban đầu cột TARGETS có thể hiển thị `<unknown>/50%`. Đợi khoảng 1 phút để Metrics Server thu thập đủ dữ liệu, nó sẽ hiển thị số thực tế, ví dụ `0%/50%`.*

---

### Bước 4: Tạo Tải (Stress Test) và Quan sát Quá trình Scale Up
Chúng ta sẽ chạy một Pod phụ gửi hàng nghìn request liên tục tới Service `php-apache` để sinh tải CPU.

1. Mở một cửa sổ Terminal mới (Terminal 2) để giám sát trạng thái HPA liên tục:
```bash
kubectl get hpa php-apache-hpa -w
```

2. Mở thêm một cửa sổ Terminal mới nữa (Terminal 3) để quan sát số lượng Pod thay đổi:
```bash
kubectl get pods -l run=php-apache -w
```

3. Quay lại Terminal chính, chạy lệnh khởi tạo Pod sinh tải:
```bash
kubectl run -i --tty --rm load-generator --image=busybox:1.35 --restart=Never -- /bin/sh -c "while true; do wget -q -O- http://php-apache; done"
```

4. **Quan sát kết quả ở các Terminal:**
- **Terminal 2:** Bạn sẽ thấy mức tiêu thụ CPU tăng vọt vượt ngưỡng (ví dụ: `150%/50%`, `220%/50%`).
- **Terminal 3:** K8s lập tức phản hồi bằng việc sinh thêm các Pod mới: số lượng Pod tăng từ 1 lên 2, 3, 4 và đạt mức tối đa 5 Pod.
- Khi số lượng Pod đạt 5, tải CPU trung bình giữa các Pod sẽ giảm dần xuống dưới mức 50%.

---

### Bước 5: Ngắt Tải và Quan sát Quá trình Scale Down
1. Quay lại Terminal chính (nơi đang chạy lệnh sinh tải `load-generator`) và nhấn `Ctrl + C` để dừng việc gửi request. Pod `load-generator` sẽ tự động bị xóa đi nhờ tham số `--rm`.

2. Tiếp tục quan sát trạng thái HPA ở Terminal 2:
- Tải CPU sẽ giảm nhanh về `0%/50%`.
- > [!IMPORTANT]
  > Để tránh tình trạng hệ thống bị "trồi sụt" liên tục (flapping) khi tải biến động ngắn hạn, Kubernetes có cơ chế **Cool-down delay** (mặc định khoảng 5 phút).
  > Bạn cần kiên nhẫn chờ khoảng 5 phút sau khi tắt tải, HPA mới bắt đầu giảm số lượng Pod (scale-down) từ 5 về lại 1 Pod ban đầu.

---

### Bước 6: Dọn dẹp tài nguyên
```bash
kubectl delete -f practice/w8-lab/lab-05-scaling/app-hpa.yaml
kubectl delete -f practice/w8-lab/lab-05-scaling/app-apache.yaml
```
Khuyên dùng: Bạn có thể tắt metrics-server nếu không cần thiết nữa bằng lệnh `minikube addons disable metrics-server` để giảm tải cho máy ảo Minikube.
