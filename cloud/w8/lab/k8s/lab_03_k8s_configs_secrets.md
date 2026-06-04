# Lab 03: Kubernetes Configuration & Secrets Management — ConfigMaps & Secrets

## 1. Mục tiêu bài lab
* Hiểu triết lý thiết kế của mô hình ứng dụng 12-factor: Tách rời cấu hình (Configuration) khỏi mã nguồn ứng dụng.
* Biết cách sử dụng **ConfigMap** để nạp cấu hình thông thường (Environment variables, config files).
* Biết cách sử dụng **Secret** để nạp cấu hình nhạy cảm (Passwords, API Tokens, Private Keys).
* Hiểu cách nạp cấu hình dưới dạng **Biến môi trường (Env)** và **Gắn kết đĩa (Volume Mount)**.

---

## 2. Chuẩn bị thư mục thực hành
Tạo các file YAML trong thư mục: `practice/w8-lab/lab-03-configs-secrets/`

---

## 3. Các bước thực hiện Step-by-Step

### Bước 1: Tạo và sử dụng ConfigMap
Chúng ta sẽ tạo một ConfigMap lưu cấu hình môi trường chạy ứng dụng.

1. Tạo file [app-configmap.yaml](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/w8-lab/lab-03-configs-secrets/app-configmap.yaml):
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  APP_ENV: "production"
  APP_THEME: "dark"
  app_properties: |
    max.connections=20
    db.pool.timeout=30s
```

2. Áp dụng ConfigMap lên Cluster:
```bash
kubectl apply -f practice/w8-lab/lab-03-configs-secrets/app-configmap.yaml
```

3. Kiểm tra ConfigMap vừa tạo:
```bash
kubectl get configmap app-config -o yaml
```

---

### Bước 2: Tạo và sử dụng Secret (Bảo mật)
> [!WARNING]
> Mặc định, dữ liệu trong K8s Secrets được mã hóa dạng **Base64** chứ không phải mã hóa bảo mật (Encryption). Mục tiêu là tránh vô tình hiển thị mật khẩu ở dạng plain-text trên log hoặc git repo.

1. Mã hóa mật khẩu của bạn sang Base64 trên macOS Terminal:
```bash
# Mã hóa chuỗi mật khẩu "SuperSecretDBPassword"
echo -n "SuperSecretDBPassword" | base64
# Kết quả sẽ dạng: U3VwZXJTZWNyZXREQlBhc3N3b3Jk

# Mã hóa database user "db-admin"
echo -n "db-admin" | base64
# Kết quả sẽ dạng: ZGItYWRtaW4=
```

2. Tạo file [app-secret.yaml](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/w8-lab/lab-03-configs-secrets/app-secret.yaml) và đưa dữ liệu Base64 vừa mã hóa vào phần `data`:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-db-secret
type: Opaque
data:
  DB_USER: ZGItYWRtaW4=
  DB_PASS: U3VwZXJTZWNyZXREQlBhc3N3b3Jk
```

3. Áp dụng Secret:
```bash
kubectl apply -f practice/w8-lab/lab-03-configs-secrets/app-secret.yaml
```

4. Kiểm tra Secret (Bạn sẽ thấy dữ liệu không hiển thị plain-text trực tiếp):
```bash
kubectl get secret app-db-secret -o yaml
```

---

### Bước 3: Triển khai Pod tiêu thụ ConfigMap & Secret qua Biến môi trường (Env Variables)

1. Tạo file [app-pod-env.yaml](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/w8-lab/lab-03-configs-secrets/app-pod-env.yaml):
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: config-demo-pod
spec:
  containers:
  - name: demo-container
    image: busybox:1.35
    command: ["sh", "-c", "echo 'ENV:' $MY_APP_ENV; echo 'THEME:' $MY_APP_THEME; echo 'DB USER:' $DB_USER; echo 'DB PASS:' $DB_PASS; sleep 3600"]
    env:
    # Nạp từ ConfigMap
    - name: MY_APP_ENV
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: APP_ENV
    - name: MY_APP_THEME
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: APP_THEME
    # Nạp từ Secret
    - name: DB_USER
      valueFrom:
        secretKeyRef:
          name: app-db-secret
          key: DB_USER
    - name: DB_PASS
      valueFrom:
        secretKeyRef:
          name: app-db-secret
          key: DB_PASS
```

2. Áp dụng Pod:
```bash
kubectl apply -f practice/w8-lab/lab-03-configs-secrets/app-pod-env.yaml
```

3. Kiểm tra logs để xem Pod đã nhận được biến môi trường chưa:
```bash
kubectl logs config-demo-pod
```
*Bạn sẽ thấy log in ra các biến được trích xuất từ ConfigMap và Secret ở dạng plain-text chính xác.*

---

### Bước 4: Triển khai Pod nạp ConfigMap & Secret dưới dạng Tập tin (Volume Mounts)
Đôi khi ứng dụng cần đọc cấu hình từ một file tĩnh hoặc file properties hơn là biến môi trường.

1. Tạo file [app-pod-volume.yaml](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/w8-lab/lab-03-configs-secrets/app-pod-volume.yaml):
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: volume-config-pod
spec:
  containers:
  - name: demo-container
    image: busybox:1.35
    command: ["sh", "-c", "echo '--- File Config: ---'; cat /etc/config/app_properties; echo '--- File Secret: ---'; cat /etc/secrets/DB_PASS; sleep 3600"]
    volumeMounts:
    # Gắn thư mục Config vào /etc/config
    - name: config-volume
      mountPath: /etc/config
    # Gắn thư mục Secrets vào /etc/secrets
    - name: secret-volume
      mountPath: /etc/secrets
      readOnly: true
  volumes:
  # Định nghĩa volume liên kết với ConfigMap
  - name: config-volume
    configMap:
      name: app-config
  # Định nghĩa volume liên kết với Secret
  - name: secret-volume
    secret:
      secretName: app-db-secret
```

2. Áp dụng Pod:
```bash
kubectl apply -f practice/w8-lab/lab-03-configs-secrets/app-pod-volume.yaml
```

3. Kiểm tra logs để xác minh file được mount thành công:
```bash
kubectl logs volume-config-pod
```
> [!TIP]
> Một ưu điểm cực kỳ lớn khi sử dụng Volume Mount thay vì Env Variables là: Khi bạn thay đổi giá trị trong ConfigMap/Secret trên K8s cluster, các file được gắn kết trong Container sẽ **tự động cập nhật trực tiếp** (hot-reload) sau vài chục giây mà không cần khởi động lại Pod. Trong khi Env Variables yêu cầu phải restart Pod mới nhận giá trị mới.

---

### Bước 5: Dọn dẹp tài nguyên
```bash
kubectl delete -f practice/w8-lab/lab-03-configs-secrets/app-pod-volume.yaml
kubectl delete -f practice/w8-lab/lab-03-configs-secrets/app-pod-env.yaml
kubectl delete -f practice/w8-lab/lab-03-configs-secrets/app-secret.yaml
kubectl delete -f practice/w8-lab/lab-03-configs-secrets/app-configmap.yaml
```
