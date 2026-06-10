# Lab 02: Quản Lý Thứ Tự Triển Khai Với Argo CD Sync Waves

## Mục Tiêu Bài Lab
*   Hiểu cách sử dụng tính năng **Sync Waves** của Argo CD để thiết lập thứ tự triển khai tài nguyên trong Kubernetes.
*   Thực hành triển khai ứng dụng gồm 2 phần: **Database** (phải chạy trước) và **Frontend** (chạy sau khi Database đã sẵn sàng).
*   Kiểm chứng cơ chế dừng và tiếp tục đồng bộ của Argo CD dựa trên trạng thái Health Check của các Pod.

---

## Cấu Trúc Thư Mục Bài Lab
```text
lab-02-argocd-sync-waves/
├── manifests/
│   ├── database-deployment.yaml   # Chạy Database (Wave -5)
│   ├── database-service.yaml      # Service của DB
│   ├── frontend-deployment.yaml   # Chạy Frontend (Wave 0)
│   └── frontend-service.yaml      # Service của Frontend
└── README.md                      # Hướng dẫn này
```

---

## Các Bước Thực Hiện

### Bước 1: Tạo các file Manifests Kubernetes

Hãy tạo các file cấu hình sau trong thư mục `manifests/`:

#### 1. File Database Deployment
Tạo file [database-deployment.yaml](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/gitops-cicd/lab-02-argocd-sync-waves/manifests/database-deployment.yaml). Chú ý annotation `argocd.argoproj.io/sync-wave: "-5"` để chạy trước.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: database
  namespace: default
  annotations:
    argocd.argoproj.io/sync-wave: "-5" # Chạy ở Wave -5
spec:
  replicas: 1
  selector:
    matchLabels:
      app: database
  template:
    metadata:
      labels:
        app: database
    spec:
      containers:
      - name: database
        image: alpine
        command: ["sh", "-c", "echo 'Database starting...'; sleep 10; echo 'Database is ready!'; while true; do sleep 3600; done"]
        ports:
        - containerPort: 5432
        # Cấu hình Readiness Probe để Argo CD biết khi nào DB "Healthy"
        readinessProbe:
          exec:
            command:
            - sh
            - -c
            - "pgrep alpine"
          initialDelaySeconds: 2
          periodSeconds: 5
```

#### 2. File Database Service
Tạo file [database-service.yaml](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/gitops-cicd/lab-02-argocd-sync-waves/manifests/database-service.yaml) (Chạy chung Wave `-5` với deployment):

```yaml
apiVersion: v1
kind: Service
metadata:
  name: database-service
  namespace: default
  annotations:
    argocd.argoproj.io/sync-wave: "-5"
spec:
  ports:
  - port: 5432
  selector:
    app: database
```

#### 3. File Frontend Deployment
Tạo file [frontend-deployment.yaml](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/gitops-cicd/lab-02-argocd-sync-waves/manifests/frontend-deployment.yaml). File này chạy ở Wave `0` (lớn hơn `-5`), nên nó phải đợi DB chuyển sang Healthy thì mới được tạo.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: default
  annotations:
    argocd.argoproj.io/sync-wave: "0" # Chạy sau ở Wave 0
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: nginx:alpine
        ports:
        - containerPort: 80
```

#### 4. File Frontend Service
Tạo file [frontend-service.yaml](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/gitops-cicd/lab-02-argocd-sync-waves/manifests/frontend-service.yaml):

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: default
  annotations:
    argocd.argoproj.io/sync-wave: "0"
spec:
  ports:
  - port: 80
  selector:
    app: frontend
```

---

### Bước 2: Đẩy thư mục này lên GitHub cá nhân của bạn
1. Tạo một repository mới trên GitHub (Ví dụ: `argocd-sync-waves-demo`).
2. Copy các file trên vào repo mới đó và push lên nhánh `main`.

---

### Bước 3: Tạo Ứng Dụng trên Argo CD UI và Kiểm Chứng
1. Truy cập Web UI của Argo CD, bấm **`+ NEW APP`**.
2. Thiết lập:
   *   **Application Name:** `sync-waves-app`
   *   **Project Name:** `default`
   *   **Sync Policy:** Chọn **`Manual`**
   *   **Repo URL:** Điền link GitHub bạn vừa tạo ở Bước 2.
   *   **Path:** Điền `manifests`
   *   **Cluster URL:** Chọn `https://kubernetes.default.svc`
   *   **Namespace:** `default`
3. Bấm **`CREATE`**.
4. Click vào ứng dụng `sync-waves-app` để xem sơ đồ trực quan.
5. Bấm nút **`SYNC`** $\rightarrow$ **`SYNCHRONIZE`**.

#### 🧐 Quan sát hiện tượng cực kỳ quan trọng:
*   Bạn sẽ thấy Argo CD **chỉ tạo** tài nguyên `database` và `database-service` trước (do Wave `-5` chạy trước).
*   Argo CD sẽ đứng chờ ở Wave `-5` và theo dõi tình trạng Health Check (`readinessProbe`) của Pod Database.
*   **Chỉ khi** Pod database chuyển sang màu xanh lá cây (**Healthy**), Argo CD mới tiếp tục tạo ra tài nguyên `frontend` và `frontend-service` ở Wave `0`.
*   Điều này giúp tránh tình trạng Frontend khởi động lên trước, không kết nối được Database và bị lỗi crash lặp đi lặp lại.
