# Hướng Dẫn Argo CD: Sync Waves, Application & Cheat Sheet Thực Hành

Tài liệu này tổng hợp các kiến thức cốt lõi về cơ chế Sync Waves, đối tượng Application trong Argo CD, cách cấu hình kết nối Repository bảo mật, kèm theo Cheat Sheet câu lệnh `kubectl` / `minikube` dùng trong quá trình thực hành và debug.

---

## 1. Cơ chế Sync Waves trong Argo CD
**Sync Waves** là tính năng của Argo CD giúp kiểm soát thứ tự triển khai (deployment order) của các tài nguyên Kubernetes trong cùng một ứng dụng.

### Cách hoạt động
*   Argo CD sắp xếp các tài nguyên dựa trên annotation `argocd.argoproj.io/sync-wave` (nhận giá trị là số nguyên âm hoặc dương, mặc định nếu không khai báo là `0`).
*   Trình tự đồng bộ sẽ chạy từ Wave có giá trị nhỏ nhất đến Wave có giá trị lớn nhất (Ví dụ: `-5` $\rightarrow$ `0` $\rightarrow$ `5`).
*   **Điểm mấu chốt**: Argo CD sẽ áp dụng các tài nguyên ở Wave hiện tại, sau đó đợi cho đến khi tất cả các tài nguyên này chuyển sang trạng thái `Healthy` (thông qua *Readiness Probe* cấu hình trên Pod) rồi mới tiếp tục chuyển sang triển khai Wave tiếp theo. Nếu Wave hiện tại bị lỗi hoặc chưa `Healthy`, tiến trình đồng bộ sẽ tạm dừng và không deploy các Wave sau.

> [!TIP]
> **Ứng dụng thực tế:** Giải quyết vấn đề phụ thuộc giữa các dịch vụ. Ví dụ: đảm bảo Database khởi động xong và sẵn sàng kết nối trước khi Frontend được triển khai, tránh việc Frontend khởi chạy trước và bị lỗi `CrashLoopBackOff`.

---

## 2. Đối tượng Application trong Argo CD
Trong Argo CD, **Application** là một Custom Resource Definition (CRD) đóng vai trò là "bản chỉ dẫn" để Argo CD biết cách vận hành và đồng bộ.

Một `Application` định nghĩa 3 thông tin cốt lõi:
1.  **Source (Nguồn)**: Lấy các file manifest (YAML) từ Git repository nào? Nhánh nào (`branch`)? Trong thư mục nào (`path`)?
2.  **Destination (Đích)**: Triển khai các manifest đó vào cụm Kubernetes nào? Namespace nào?
3.  **Sync Policy (Chính sách đồng bộ)**:
    *   Đồng bộ tự động (*Automated*) hay thủ công (*Manual*).
    *   `Self-heal`: Tự động đồng bộ lại khi cấu hình thực tế trên cụm bị lệch (drift) so với Git.
    *   `Prune`: Tự động xóa tài nguyên cũ trên cụm khi file manifest tương ứng bị xóa khỏi Git.

> [!NOTE]
> Nếu không có đối tượng `Application`, Argo CD sẽ không thể giám sát và thực hiện đồng bộ tài nguyên.

### Tại sao một số thư mục Lab không có file khai báo Application?
Trong một số bài thực hành (như `lab-02-argocd-sync-waves`), bạn chỉ thấy các file manifest của app (`database-deployment.yaml`, `frontend-service.yaml`...) mà không có file YAML nào khai báo `kind: Application`.
*   **Lý do:** Bài lab hướng dẫn tạo Application trực tiếp thông qua **Web UI** của Argo CD (`+ NEW APP`). Khi bạn tạo trên Web UI và nhấn **CREATE**, Argo CD sẽ tự động sinh ra đối tượng `Application` này và lưu trực tiếp trong namespace `argocd` trên cụm Kubernetes của bạn.

---

## 3. Cấu hình Kết nối Git Repository
Khi Argo CD cần kéo code từ Git Repository, bạn có hai cách cấu hình tùy thuộc vào chế độ của repo:

### Cách 1: Chuyển Repository sang Công khai (Public)
*Khuyên dùng cho môi trường học tập/thực hành nhanh:*
1.  Truy cập Repository trên GitHub.
2.  Vào tab **Settings** (Cài đặt) ở thanh menu của repo.
3.  Cuộn xuống cuối trang tìm phần **Danger Zone**.
4.  Bấm vào nút **Change visibility** $\rightarrow$ chọn **Change to public** và nhập tên repo để xác nhận.

### Cách 2: Cấu hình Credentials cho Private Repository
*Áp dụng khi cần bảo mật mã nguồn:*
1.  **Tạo Personal Access Token (PAT) trên GitHub**:
    *   GitHub Settings $\rightarrow$ **Developer settings** $\rightarrow$ **Personal access tokens** $\rightarrow$ **Tokens (classic)**.
    *   Nhấp chọn **Generate new token (classic)**, đặt tên gợi nhớ (ví dụ: `argocd-token`), chọn thời gian hết hạn và tích chọn scope `repo` (để đọc/ghi repo private).
    *   Nhấp **Generate token** và sao chép mã token này (token chỉ hiển thị một lần).
2.  **Khai báo Token vào Web UI Argo CD**:
    *   Truy cập Web UI Argo CD $\rightarrow$ **Settings** (biểu tượng bánh răng) $\rightarrow$ **Repositories**.
    *   Bấm nút **+ CONNECT REPO** $\rightarrow$ chọn kết nối qua **HTTPS**.
    *   Điền các thông tin:
        *   *Repository URL:* URL https của Git repo.
        *   *Username:* Tên đăng nhập GitHub của bạn.
        *   *Password:* Dán mã PAT vừa tạo ở bước trên.
    *   Nhấp **CONNECT**. Trạng thái chuyển sang màu xanh lá (`Connection Status: Successful`) là thành công.

---

## 4. Cheat Sheet: Kubectl & Minikube Thực Hành
Sử dụng các biến môi trường để tối ưu hóa câu lệnh trong Terminal:

```bash
# Định nghĩa các biến môi trường để tái sử dụng
NAMESPACE="default"
FRONTEND_SVC="frontend-service"
DATABASE_DEPLOY="database"
FRONTEND_DEPLOY="frontend"
```

### 4.1 Kiểm tra trạng thái hệ thống
| Lệnh | Mô tả |
| :--- | :--- |
| `kubectl get all -n $NAMESPACE` | Kiểm tra nhanh toàn bộ tài nguyên trong namespace |
| `kubectl get pods -n $NAMESPACE` | Xem danh sách các Pod (Kèm theo trạng thái Ready và Status) |
| `kubectl get svc -n $NAMESPACE` | Xem danh sách các Service và Cluster IP nội bộ |
| `kubectl get deploy -n $NAMESPACE` | Xem danh sách các Deployment quản lý Pod |
| `kubectl get deploy -n $NAMESPACE -o custom-columns=NAME:.metadata.name,SYNC-WAVE:.metadata.annotations."argocd\.argoproj\.io/sync-wave"` | Xem và kiểm tra giá trị Sync Wave gán cho từng Deployment |

### 4.2 Debug & Kiểm tra Log
```bash
# Xem log (nhật ký hoạt động) của các ứng dụng theo Label
kubectl logs -l app=database -n $NAMESPACE   # Log Database
kubectl logs -l app=frontend -n $NAMESPACE   # Log Frontend

# Xem chi tiết cấu hình và sự kiện (Events) của Pod khi gặp lỗi
kubectl describe pod -l app=database -n $NAMESPACE
kubectl describe pod -l app=frontend -n $NAMESPACE
```

### 4.3 Truy cập Ứng dụng ngoài cụm K8s
*   **Cách 1: Sử dụng Port-Forwarding (Ánh xạ cổng local)**
    ```bash
    # Truy cập qua trình duyệt: http://localhost:8080
    kubectl port-forward svc/$FRONTEND_SVC -n $NAMESPACE 8080:80
    ```
*   **Cách 2: Sử dụng Minikube Tunnel Service**
    ```bash
    # Tự động tạo đường hầm kết nối và mở dịch vụ trên trình duyệt mặc định
    minikube service $FRONTEND_SVC -n $NAMESPACE
    ```

---

## 5. Khắc phục lỗi Kubeconform với Custom Resources (CRD)
*   **Vấn đề:** Công cụ kiểm tra cú pháp và cấu trúc manifest `Kubeconform` báo lỗi xác thực schema khi kiểm tra file khai báo tài nguyên tùy biến (ví dụ: `kind: Application` của Argo CD), dẫn đến CI pipeline bị lỗi.
*   **Nguyên nhân:** Mặc định `Kubeconform` chỉ chứa schema của các tài nguyên Kubernetes tiêu chuẩn (Deployment, Service, Namespace...). Nó không nhận diện được schema của các Custom Resource Definition (CRD) ngoài.
*   **Khắc phục:** Cập nhật file cấu hình GitHub Actions workflow (ví dụ: `.github/workflows/validate.yml`) bằng cách thêm cờ `-ignore-missing-schemas` vào lệnh chạy của `Kubeconform`:
    ```yaml
    - name: Validate Kubernetes manifests
      run: kubeconform -ignore-missing-schemas -summary manifests/
    ```
    *Cờ này yêu cầu `Kubeconform` bỏ qua việc kiểm tra cấu trúc schema đối với các tài nguyên tùy biến chưa được khai báo schema, nhưng vẫn kiểm tra cú pháp YAML và các tài nguyên chuẩn.*
