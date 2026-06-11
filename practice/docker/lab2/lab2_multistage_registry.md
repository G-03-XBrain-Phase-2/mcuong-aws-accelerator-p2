# 🔬 Lab 2: Tối ưu hóa Image với Multi-Stage Build & Quản lý Private Registry Local

## 📌 1. Mục tiêu bài lab
*   Hiểu và thực hành kỹ thuật **Multi-stage Build** để giảm tối đa kích thước của Docker Image.
*   So sánh sự khác biệt dung lượng giữa ảnh build thông thường (Single-stage) và ảnh build tối ưu (Multi-stage).
*   Khởi chạy và vận hành một **Local Private Registry** (Kho chứa Image nội bộ).
*   Đăng ký (`tag`), đẩy (`push`), xóa (`rmi`) và kéo (`pull`) Image từ Private Registry cá nhân ở local.

---

## 🛠️ 2. Các thành phần tham gia
1.  **Mã nguồn:** Một web server đơn giản viết bằng ngôn ngữ **Go (Golang)**. Ngôn ngữ Go rất thích hợp để thực hành Multi-stage vì sau khi biên dịch (compile) nó chỉ cần 1 file binary chạy độc lập, không cần cài đặt cả bộ cài Go SDK cồng kềnh.
2.  **Docker Registry:** Image `registry:2` từ Docker Hub để chạy server lưu trữ ảnh.

---

## 🚀 3. Hướng dẫn từng bước (Step-by-Step)

### Bước 1: Chuẩn bị mã nguồn Go
Tạo thư mục trống tên là `lab2-multistage-registry` và tạo các file sau bên trong:

#### 1. File `main.go` (Mã nguồn Web Server Go)
```go
package main

import (
	"fmt"
	"net/http"
)

func handler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "<h1>Ứng dụng Go chạy từ Docker Image siêu nhẹ!</h1>\n")
}

func main() {
	http.HandleFunc("/", handler)
	fmt.Println("Server đang lắng nghe tại port 8080...")
	http.ListenAndServe(":8080", nil)
}
```

---

### Bước 2: Viết Dockerfile kiểu truyền thống (Single-stage)
Cách build này sẽ chứa cả bộ compiler Go SDK bên trong image, tạo ra dung lượng rất lớn.

#### 1. File `Dockerfile.single`
```dockerfile
FROM golang:1.20-alpine

WORKDIR /app

COPY main.go .

# Biên dịch ứng dụng trực tiếp trong image
RUN go build -o main main.go

EXPOSE 8080

CMD ["./main"]
```

Tiến hành build image single-stage:
```bash
docker build -f Dockerfile.single -t go-app:single-stage .
```

---

### Bước 3: Viết Dockerfile tối ưu (Multi-stage Build)
Cách này chia quá trình build thành 2 giai đoạn:
*   **Stage 1 (Build):** Dùng bộ Golang SDK đầy đủ để biên dịch file mã nguồn `main.go` thành file thực thi `main`.
*   **Stage 2 (Run):** Chỉ copy duy nhất file chạy `main` vào một hệ điều hành siêu nhẹ (`alpine`), loại bỏ hoàn toàn bộ Go SDK.

#### 1. File `Dockerfile.multi`
```dockerfile
# --- Stage 1: Build stage ---
FROM golang:1.20-alpine AS builder

WORKDIR /build

COPY main.go .

# Biên dịch tĩnh (Static compile) để file binary chạy độc lập không phụ thuộc thư viện động
RUN CGO_ENABLED=0 GOOS=linux go build -o main main.go

# --- Stage 2: Final run stage ---
FROM alpine:3.18

WORKDIR /app

# Chỉ copy file chạy đã biên dịch từ Stage 1
COPY --from=builder /build/main .

EXPOSE 8080

CMD ["./main"]
```

Tiến hành build image multi-stage:
```bash
docker build -f Dockerfile.multi -t go-app:multi-stage .
```

---

### Bước 4: Khởi chạy Local Private Registry
Chúng ta sẽ dựng một kho chứa ảnh Docker ngay trên máy local của mình bằng cách chạy container Registry:
```bash
docker run -d \
  -p 5000:5000 \
  --name local-registry \
  --restart=always \
  registry:2
```

---

### Bước 5: Đăng ký & Đẩy Image lên Local Registry
Để đẩy image lên registry vừa dựng, ta cần đặt lại nhãn (Tag) theo định dạng URL của registry.

```bash
# 1. Gắn nhãn mới trỏ tới registry localhost:5000
docker tag go-app:multi-stage localhost:5000/go-web:v1.0

# 2. Đẩy image lên local registry
docker push localhost:5000/go-web:v1.0
```

---

### Bước 6: Kiểm chứng việc Tải/Xóa từ Registry
Hãy xóa sạch các image ở máy local để kiểm tra xem có kéo (pull) lại thành công từ Registry hay không.

```bash
# 1. Xóa các image local đã build/tag trước đó
docker rmi localhost:5000/go-web:v1.0
docker rmi go-app:multi-stage

# 2. Kiểm tra xem image đã biến mất khỏi máy chưa (Lệnh này không được chứa các tên trên nữa)
docker images | grep go-web

# 3. Kéo image lại từ local registry
docker pull localhost:5000/go-web:v1.0
```

---

## 📊 4. Kết quả mong đợi & Cách so sánh (Verification)

### Kiểm tra 1: So sánh kích thước Image (Quan trọng nhất)
Chạy lệnh hiển thị các image đã build:
```bash
docker images | grep go-app
```
**Kết quả mong đợi:**
```text
REPOSITORY   TAG            IMAGE ID       CREATED          SIZE
go-app       single-stage   a1b2c3d4e5f6   2 minutes ago    265MB
go-app       multi-stage    f6e5d4c3b2a1   10 seconds ago   14.6MB
```
*   **Đánh giá:** Kích thước image giảm từ **~265MB** xuống chỉ còn **~14.6MB** (giảm tới **94%** dung lượng) nhờ kỹ thuật Multi-stage build.

### Kiểm tra 2: Truy vấn API của Local Registry
Chúng ta có thể truy cập cổng API của Registry để kiểm tra danh sách image đang được lưu trữ trong đó:
```bash
curl http://localhost:5000/v2/_catalog
```
**Kết quả mong đợi:**
```json
{"repositories":["go-web"]}
```
Và kiểm tra tag của image `go-web`:
```bash
curl http://localhost:5000/v2/go-web/tags/list
```
**Kết quả mong đợi:**
```json
{"name":"go-web","tags":["v1.0"]}
```

### Kiểm tra 3: Chạy thử Image được kéo về từ Registry
Chạy thử container từ image đã pull từ registry để xem nó hoạt động bình thường không:
```bash
docker run -d -p 8080:8080 --name test-go-web localhost:5000/go-web:v1.0
curl http://localhost:8080
```
**Kết quả mong đợi:**
Màn hình trả về kết quả:
```text
<h1>Ứng dụng Go chạy từ Docker Image siêu nhẹ!</h1>
```
Dọn dẹp container test:
```bash
docker rm -f test-go-web
```

---

## 🧹 5. Dọn dẹp tài nguyên (Cleanup)

Sau khi hoàn thành bài Lab, bạn hãy thực hiện dọn dẹp các tài nguyên sau để giải phóng dung lượng ổ đĩa và RAM:

```bash
# 1. Dừng và xóa container Private Registry local
docker rm -f local-registry

# 2. Xóa các image đã build và đã pull về máy để giải phóng bộ nhớ
docker rmi localhost:5000/go-web:v1.0
docker rmi go-app:single-stage
docker rmi registry:2
```

