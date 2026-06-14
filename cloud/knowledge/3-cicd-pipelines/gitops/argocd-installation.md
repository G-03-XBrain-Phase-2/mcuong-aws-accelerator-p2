# Hướng Dẫn Cài Đặt & Cấu Hình Argo CD trên Kubernetes Local (Minikube)

Tài liệu này hướng dẫn chi tiết các lệnh cài đặt Argo CD, giải quyết lỗi giới hạn kích thước metadata (`Too long: may not be more than 262144 bytes`), cách truy cập Web UI và lấy mật khẩu quản trị mặc định.

---

## 1. Lệnh Cài Đặt (Khuyên Dùng)

Sử dụng phương pháp **Server-Side Apply (SSA)** để tránh lỗi giới hạn dung lượng annotation của Kubernetes đối với các tài nguyên CustomResourceDefinition (CRD) quá lớn trong Argo CD:

```bash
# Bước 1: Tạo Namespace riêng cho Argo CD
kubectl create namespace argocd

# Bước 2: Cài đặt Argo CD bằng Server-Side Apply để tránh lỗi kích thước CRD
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

* **`--server-side`**: Bắt buộc phải có để bypass giới hạn 256KB annotation lưu trữ lịch sử cấu hình client-side.
* **`--force-conflicts`**: Đảm bảo quyền kiểm soát tài nguyên được bàn giao suôn sẻ cho bộ quản lý Server-side, khắc phục các tranh chấp nếu trước đó bạn lỡ chạy lệnh apply thường.

---

## 2. Kiểm Tra Trạng Thái Pods

Đợi khoảng 1-2 phút và kiểm tra xem tất cả các cấu phần của Argo CD đã khởi chạy thành công hay chưa:

```bash
kubectl get pods -n argocd
```

*Trạng thái lý tưởng của toàn bộ các Pod phải là **`Running`** hoặc **`Completed`**.*

---

## 3. Truy Cập Giao Diện Web (Port-Forwarding)

Vì mặc định Argo CD Server không được công khai ra ngoài cụm, chúng ta sẽ mở một kênh kết nối trực tiếp (Port-forward) từ máy tính local vào cụm K8s:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

* **Địa chỉ truy cập trên trình duyệt:** **`https://localhost:8080`**
* *Lưu ý:* Terminal chạy lệnh này phải được giữ mở liên tục trong suốt quá trình bạn thao tác trên Web UI. Nếu trình duyệt báo kết nối HTTPS không an toàn (do chứng chỉ SSL tự ký), hãy nhấn **Advanced** $\rightarrow$ **Proceed to localhost**.

---

## 4. Đăng Nhập & Lấy Mật Khẩu Admin Mặc Định

Mở một tab terminal mới và chạy lệnh giải mã base64 để lấy mật khẩu đăng nhập lần đầu tiên:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

* **Username:** `admin`
* **Password:** Chuỗi ký tự ngẫu nhiên thu được từ lệnh trên (ví dụ: `x1y2z3a4b5c6`).

> [!TIP]
> **Khuyên dùng:** Ngay sau khi đăng nhập thành công lần đầu tiên, hãy đi tới phần **User Info** trên thanh menu bên trái của giao diện Web Argo CD để đổi mật khẩu quản trị sang mật khẩu mới dễ nhớ và bảo mật hơn.
