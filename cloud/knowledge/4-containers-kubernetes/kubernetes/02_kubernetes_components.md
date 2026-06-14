# Chuyên đề 2: Các Thành phần & Đối tượng cốt lõi trong Kubernetes (K8s Objects)

Tài liệu này giải thích chi tiết khái niệm, vai trò, nguyên lý hoạt động và cung cấp ví dụ khai báo YAML thực tế cho các đối tượng (Objects) cơ bản nhất của Kubernetes.

---

## 1. Pod — Đơn vị tính toán nhỏ nhất

### 1.1. Pod là gì?

**Pod** là đơn vị nhỏ nhất có thể tạo lập, triển khai và quản lý trong Kubernetes. Một Pod đại diện cho một tiến trình đang chạy trong cụm của bạn.

- **Tính chất:** Pod có vòng đời ngắn (ephemeral). Chúng có thể bị hủy, di dời hoặc tạo mới bất kỳ lúc nào và địa chỉ IP của Pod sẽ thay đổi theo.
- **Mối quan hệ Container:** Một Pod có thể chứa một hoặc nhiều Container (thường là Docker). Các container trong cùng một Pod sẽ:
  - Chia sẻ chung một địa chỉ IP và dải cổng (Network namespace - kết nối qua `localhost`).
  - Chia sẻ chung các ổ đĩa lưu trữ (Volumes).

> **Mẹo hình dung:** Hãy coi Pod như một "căn hộ". Các container bên trong là các "thành viên" sống chung. Họ dùng  chung địa chỉ nhà (IP), chung đường ống nước/khí (Volume) và giao tiếp trực tiếp với nhau rất nhanh.

### 1.2. Sơ đồ minh họa Pod

![Sơ đồ Pod trong Kubernetes](https://kubernetes.io/images/docs/pod.svg)### 1.3. Ví dụ khai báo YAML

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-web-pod
  labels:
    app: web
spec:
  containers:
    - name: nginx-container
      image: nginx:1.25
      ports:
        - containerPort: 80
```

---

## 2. ReplicaSet & Deployment — Quản lý trạng thái không lưu trữ (Stateless)

### 2.1. Khái niệm

- **ReplicaSet:** Có một nhiệm vụ duy nhất là duy trì chính xác số lượng bản sao (Replicas) của các Pod hoạt động ổn định tại mọi thời điểm. Nếu một Pod bị lỗi hoặc node bị sập, ReplicaSet sẽ tự động tạo Pod mới thay thế.
- **Deployment:** Là một đối tượng cấp cao hơn, bọc ngoài ReplicaSet. Nó cung cấp các tính năng quản lý vòng đời ứng dụng cực kỳ mạnh mẽ như:
  - **Rolling Update:** Cập nhật phiên bản ứng dụng mới lần lượt mà không làm gián đoạn hệ thống (Zero Downtime).
  - **Rollback:** Quay lại phiên bản cũ ngay lập tức nếu phiên bản mới bị lỗi.

### 2.2. Sơ đồ hoạt động

```
[ User/CD Pipeline ] ──► [ Deployment ] ──► [ ReplicaSet ] ──► [ Pod 1 ] [ Pod 2 ] [ Pod 3 ]
```

### 2.3. Ví dụ khai báo Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deployment
spec:
  replicas: 3 # Duy trì chạy liên tục 3 Pods
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app # Nhãn để ReplicaSet nhận diện và quản lý các Pod
    spec:
      containers:
        - name: app-node
          image: node:18-alpine
          ports:
            - containerPort: 3000
```

---

## 3. Service — Điểm kết nối cố định và Cân bằng tải

### 3.1. Service là gì?

Vì các Pod có thể bị hủy và tạo mới liên tục, địa chỉ IP của chúng không bao giờ cố định. **Service** sinh ra để giải quyết vấn đề này. Nó cung cấp:

1. Một **IP ảo cố định (ClusterIP)** và một **tên miền DNS nội bộ** duy nhất đại diện cho nhóm Pod.
2. Cơ chế **Cân bằng tải (Load Balancing)** tự động phân phối lượng truy cập đến các Pod khỏe mạnh phía sau.

### 3.2. Sơ đồ minh họa Service

![Sơ đồ Service định tuyến tới các Pod](https://kubernetes.io/images/docs/services-subdeployment.svg)### 3.3. Các loại Service chính (Service Types)

- **ClusterIP (Mặc định):** Chỉ cho phép truy cập dịch vụ từ **bên trong** cụm K8s. Các dịch vụ bên ngoài không thể kết nối tới IP này.
- **NodePort:** Mở một cổng tĩnh (từ `30000 - 32767`) trên tất cả các Node vật lý. Bằng cách gọi `IP_Node:Port`, traffic ngoài internet có thể đi vào Service.
- **LoadBalancer:** Tích hợp với dịch vụ cân bằng tải của các nhà cung cấp Cloud (như AWS ALB/NLB). K8s sẽ tự tạo ra một Public IP/DNS trên Cloud để người dùng truy cập trực tiếp.

### 3.4. Ví dụ khai báo Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-web-service
spec:
  type: ClusterIP # Loại service kết nối nội bộ
  selector:
    app: web-app # Tìm tất cả các Pod có nhãn (label) app=web-app
  ports:
    - protocol: TCP
      port: 80        # Cổng của Service
      targetPort: 3000 # Cổng thực tế ứng dụng đang lắng nghe trong Container
```

---

## 4. Ingress — Cổng vào Layer 7 (HTTP/HTTPS Routing)

### 4.1. Khái niệm

Nếu như `Service (LoadBalancer)` chỉ định tuyến ở Layer 4 (TCP/UDP) và mỗi Service cần một Load Balancer tốn phí riêng trên Cloud, thì **Ingress** là giải pháp định tuyến ở Layer 7 (HTTP/HTTPS) thông minh và tiết kiệm:

- Đóng vai trò làm điểm truy cập duy nhất (Single Entry Point) từ internet vào toàn bộ Cluster.
- Hỗ trợ định tuyến dựa trên **Domain Name** (ví dụ: `app.com`) hoặc **Đường dẫn/Path** (ví dụ: `app.com/api`).
- Tích hợp chứng chỉ SSL/TLS tập trung (SSL Termination).

### 4.2. Sơ đồ Ingress

```
               Internet (Traffic)
                       │
                       ▼
                 [ Ingress ]
                /           \
     domain.com/web       domain.com/api
              /               \
             ▼                 ▼
     [ Web Service ]     [ API Service ]
            │                  │
         [ Pods ]           [ Pods ]
```

### 4.3. Ví dụ khai báo Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
    - host: my-company-app.com
      http:
        paths:
          - path: /web
            pathType: Prefix
            backend:
              service:
                name: my-web-service
                port:
                  number: 80
```

---

## 5. Volume, PV & PVC — Quản lý lưu trữ dữ liệu bền vững

### 5.1. Khái niệm

Dữ liệu của Container mặc định là tạm thời (sẽ mất sạch khi container bị crash hoặc khởi động lại). Để lưu trữ dữ liệu bền vững (như database, log, file upload), K8s sử dụng hệ thống Volume:

- **PersistentVolume (PV):** Là tài nguyên lưu trữ thực tế trong cụm (như một ổ cứng AWS EBS, ổ cứng vật lý NFS) được cấu hình sẵn bởi Quản trị viên (Cluster Admin).
- **PersistentVolumeClaim (PVC):** Là "yêu cầu xin cấp phát dung lượng" từ người dùng/lập trình viên. Nó tương tự như một tấm vé yêu cầu: *"Tôi cần 10GB dung lượng lưu trữ dạng ReadWrite"*. K8s sẽ tự động tìm kiếm PV phù hợp để gắn (bind) vào PVC này.

### 5.2. Luồng hoạt động

```
[ Pod ] ── yêu cầu mount ──► [ PVC ] ── tự động ánh xạ ──► [ PV ] ── kết nối vật lý ──► [ Ổ cứng Cloud/NFS ]
```

### 5.3. Ví dụ khai báo PVC và mount vào Pod

```yaml
# 1. Tạo yêu cầu cấp phát dung lượng (PVC)
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi

---
# 2. Gắn PVC vào Pod để sử dụng
apiVersion: v1
kind: Pod
metadata:
  name: mysql-pod
spec:
  containers:
    - name: mysql
      image: mysql:8.0
      volumeMounts:
        - mountPath: "/var/lib/mysql"
          name: db-storage
  volumes:
    - name: db-storage
      persistentVolumeClaim:
        claimName: mysql-pvc # Trỏ đến tên PVC đã tạo ở trên
```

---

## 6. ConfigMap & Secret — Tách biệt cấu hình khỏi ứng dụng

### 6.1. Khái niệm

- **ConfigMap:** Dùng để lưu trữ các tham số cấu hình không nhạy cảm (dưới dạng key-value) như tệp config, biến môi trường (ENV), cổng dịch vụ.
- **Secret:** Dùng để lưu trữ các thông tin nhạy cảm cần bảo mật như mật khẩu cơ sở dữ liệu, API Key, Token, Chứng chỉ SSL. Dữ liệu trong Secret mặc định được mã hóa ở dạng **Base64**.

### 6.2. Ví dụ khai báo ConfigMap & Secret

```yaml
# 1. Khai báo ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  LOG_LEVEL: "info"
  API_URL: "https://api.internal.app"

---
# 2. Khai báo Secret
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
type: Opaque
data:
  # Mật khẩu "SuperSecretPass" sau khi được encode Base64
  DB_PASSWORD: U3VwZXJTZWNyZXRQYXNz
```

---

## 7. Namespace — Phân chia tài nguyên cụ thể

### 7.1. Khái niệm

**Namespace** được sử dụng để phân chia một cụm Kubernetes vật lý thành nhiều cụm logic ảo độc lập.

- Giúp tách biệt các môi trường làm việc trên cùng một hạ tầng (ví dụ: `development`, `staging`, `production`).
- Giúp phân quyền (RBAC) chi tiết: lập trình viên chỉ có quyền sửa đổi trong namespace `dev`, không thể can thiệp vào namespace `prod`.

### 7.2. Ví dụ khai báo Namespace

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: development
```

*(Để chạy một Pod trong namespace này, ta chỉ cần thêm trường* `namespace: development` *vào phần* `metadata` *của Pod).*