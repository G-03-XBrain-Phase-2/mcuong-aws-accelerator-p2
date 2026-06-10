# Lab 03: Thiết Lập App-of-Apps Pattern & Kịch Bản Rollback GitOps

## Mục Tiêu Bài Lab
*   Thực hành thiết lập mô hình quản lý nhiều ứng dụng tập trung bằng **App of Apps Pattern** trong Argo CD.
*   Hiểu bản chất của cơ chế **Self-healing (Tự phục hồi)** và **Drift Detection (Phát hiện trôi lệch trạng thái)**.
*   Kiểm chứng kịch bản **Rollback** an toàn chuẩn GitOps bằng `git revert` và phân tích tại sao không nên dùng `kubectl rollout undo`.

---

## Cấu Trúc Thư Mục Bài Lab
```text
lab-03-argocd-app-of-apps-rollback/
├── child-apps/                    # Khai báo các ứng dụng con cho Argo CD đọc
│   ├── app-backend.yaml
│   └── app-frontend.yaml
├── apps-code/                     # Code manifests Kubernetes thực tế của app
│   ├── backend/
│   │   └── deployment.yaml
│   └── frontend/
│       └── deployment.yaml
├── root-app.yaml                  # Ứng dụng gốc (Root App) quản lý toàn bộ
└── README.md                      # Hướng dẫn này
```

---

## Các Bước Thực Hiện

### GIAI ĐOẠN 1: THIẾT LẬP APP-OF-APPS

#### Bước 1: Tạo các tài nguyên mẫu cho Backend và Frontend
Tạo các tệp cấu hình triển khai Kubernetes trong thư mục `apps-code/`:

*   **File [apps-code/backend/deployment.yaml](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/gitops-cicd/lab-03-argocd-app-of-apps-rollback/apps-code/backend/deployment.yaml):**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-app
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend-app
  template:
    metadata:
      labels:
        app: backend-app
    spec:
      containers:
      - name: web
        image: nginx:1.21 # Phiên bản cũ chạy ổn định
        ports:
        - containerPort: 80
```

*   **File [apps-code/frontend/deployment.yaml](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/gitops-cicd/lab-03-argocd-app-of-apps-rollback/apps-code/frontend/deployment.yaml):**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-app
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend-app
  template:
    metadata:
      labels:
        app: frontend-app
    spec:
      containers:
      - name: web
        image: nginx:alpine
        ports:
        - containerPort: 80
```

#### Bước 2: Tạo định nghĩa Child Applications cho Argo CD
Tạo các tệp khai báo Application con nằm trong thư mục `child-apps/`:

*   **File [child-apps/app-backend.yaml](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/gitops-cicd/lab-03-argocd-app-of-apps-rollback/child-apps/app-backend.yaml):**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: child-backend
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/<YOUR-GITHUB-USER>/<YOUR-REPO>.git' # Thay link repo của bạn
    targetRevision: HEAD
    path: apps-code/backend
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true # Bật tự động sửa đổi khi lệch state
```

*   **File [child-apps/app-frontend.yaml](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/gitops-cicd/lab-03-argocd-app-of-apps-rollback/child-apps/app-frontend.yaml):**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: child-frontend
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/<YOUR-GITHUB-USER>/<YOUR-REPO>.git' # Thay link repo của bạn
    targetRevision: HEAD
    path: apps-code/frontend
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

#### Bước 3: Tạo Root Application quản lý toàn bộ
Tạo tệp [root-app.yaml](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/gitops-cicd/lab-03-argocd-app-of-apps-rollback/root-app.yaml) ở thư mục gốc của bài lab:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/<YOUR-GITHUB-USER>/<YOUR-REPO>.git' # Thay link repo của bạn
    targetRevision: HEAD
    path: child-apps
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

#### Bước 4: Đẩy code lên GitHub & Triển khai Root Application
1. Đẩy toàn bộ cấu trúc thư mục trên lên một Git repository của bạn (Thay các placeholder `<YOUR-GITHUB-USER>` và `<YOUR-REPO>` bằng thông tin thật của bạn).
2. Dùng lệnh CLI để triển khai Root App lên Minikube:
   ```bash
   kubectl apply -f root-app.yaml
   ```
3. Mở giao diện Web Argo CD. Bạn sẽ thấy điều kỳ diệu: Chỉ cần khai báo `root-app`, Argo CD sẽ tự quét thư mục `child-apps/` để sinh ra thêm 2 ứng dụng con `child-backend` và `child-frontend` và tự động deploy toàn bộ hệ thống.

---

### GIAI ĐOẠN 2: KIỂM CHỨNG TÍNH NĂNG ROLLBACK & SELF-HEALING

#### Kịch bản 1: Sửa đổi ứng dụng bị lỗi và Deploy lên main
1. Tiến hành sửa lỗi: Hãy đổi image trong file `apps-code/backend/deployment.yaml` từ `nginx:1.21` thành một phiên bản lỗi/không tồn tại, ví dụ: `nginx:1.21-error-version`.
2. Commit và push lên GitHub nhánh `main`.
3. Argo CD sẽ tự phát hiện và đồng bộ. Kết quả: Pod của backend sẽ bị lỗi `ImagePullBackOff` hoặc `ErrImagePull` (Trạng thái ứng dụng trên UI sẽ báo màu đỏ/vàng).

#### Kịch bản 2: Thử nghiệm lỗi Rollback truyền thống (`kubectl rollout undo`)
1. Bạn cố gắng cứu lỗi nhanh bằng lệnh Kubernetes truyền thống dưới máy local:
   ```bash
   kubectl rollout undo deployment/backend-app
   ```
2. Hãy nhìn vào giao diện Web Argo CD ngay lập tức.
3. **Hiện tượng xảy ra:** Argo CD phát hiện ra cụm đang chạy bản cũ nhưng Git vẫn khai báo bản lỗi. Vì có thuộc tính `selfHeal: true`, Argo CD lập tức ghi đè (override) hành động `undo` của bạn và đưa bản lỗi `nginx:1.21-error-version` quay trở lại. Lệnh `kubectl rollout undo` hoàn toàn vô tác dụng!

#### Kịch bản 3: Thực hiện Rollback đúng chuẩn GitOps (`git revert`)
1. Để đưa hệ thống về trạng thái an toàn thực sự, hãy chạy lệnh revert commit lỗi trên Git:
   ```bash
   # Tìm commit gây lỗi
   git log --oneline
   
   # Revert commit đó
   git revert HEAD
   
   # Push commit revert lên main
   git push origin main
   ```
2. Argo CD tự nhận diện commit revert và đồng bộ trạng thái cluster về phiên bản ổn định cũ `nginx:1.21` một cách an toàn, mượt mà và không hề bị ghi đè.
3. **Kết quả:** Hệ thống sống lại bình thường và lưu lại lịch sử kiểm toán đầy đủ trên Git.
