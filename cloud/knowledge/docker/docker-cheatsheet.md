# 📑 DOCKER CHEAT SHEET

Một cẩm nang tra cứu nhanh các câu lệnh Docker cốt lõi dành cho Cloud/DevOps Engineer để xây dựng, quản lý và vận hành container hiệu quả trong cả môi trường phát triển (Local) lẫn thực tế (Production).

---

## 🛠️ I. QUẢN LÝ CONTAINER (Container Lifecycle)

Container là một thực thể chạy của Image. Đây là các câu lệnh chính để khởi tạo, điều phối, theo dõi và tắt các container.

| Câu lệnh | Giải thích chi tiết & Mục đích sử dụng |
| :--- | :--- |
| `docker run -d -p <host>:<container> --name <tên> <image>` | **Tạo và chạy container ở background**: Khởi chạy container từ image, gán tên dễ nhớ, ánh xạ cổng từ máy host vào container, chạy ẩn bên dưới. *(Ví dụ: `docker run -d -p 8080:80 --name my-web nginx:alpine`).* |
| `docker ps` | **Xem các container đang chạy**: Hiển thị danh sách container đang hoạt động kèm theo ID, tên, cổng mapping và trạng thái. |
| `docker ps -a` | **Xem toàn bộ container**: Liệt kê mọi container đang có trên hệ thống, bao gồm cả những container đã dừng (Status: Exited). |
| `docker stop <container>` | **Dừng container**: Gửi tín hiệu SIGTERM để container tắt một cách an toàn. Bạn có thể dùng Container ID hoặc Name. |
| `docker start <container>` | **Chạy lại container đã dừng**: Khởi động lại một container cũ đã bị stop mà không làm mất các file sửa đổi tạm thời bên trong container đó. |
| `docker restart <container>` | **Khởi động lại ngay lập tức**: Thực hiện dừng (stop) rồi khởi chạy lại (start) container một cách nhanh chóng. |
| `docker rm <container>` | **Xóa container**: Gỡ bỏ container khỏi hệ thống. *(Lưu ý: Chỉ xóa được khi container đã dừng).* |
| `docker rm -f <container>` | **Xóa cưỡng chế**: Ép dừng container đang chạy và xóa nó ngay lập tức bằng tín hiệu SIGKILL. |
| `docker stats` | **Theo dõi tài nguyên**: Hiển thị thời gian thực lượng CPU, RAM, Network I/O, Block I/O mà các container đang tiêu thụ. |

---

## 📦 II. QUẢN LÝ IMAGES (Image Management)

Image là khuôn mẫu đóng gói sẵn mã nguồn và môi trường. Quản lý image tốt giúp tối ưu hóa dung lượng ổ đĩa.

| Câu lệnh | Giải thích chi tiết & Mục đích sử dụng |
| :--- | :--- |
| `docker build -t <tên-image>:<tag> .` | **Build Image từ Dockerfile**: Đóng gói mã nguồn ở thư mục hiện tại (`.`) thành một Docker Image với tên và tag chỉ định. |
| `docker images` | **Xem danh sách Image**: Hiển thị toàn bộ các image hiện đang được lưu trữ trên bộ nhớ máy local của bạn. |
| `docker pull <image>:<tag>` | **Tải Image từ Registry**: Tải image từ Docker Hub hoặc các repository dùng chung khác về máy. |
| `docker push <image>:<tag>` | **Đẩy Image lên Registry**: Đăng tải image tự build lên Docker Hub hoặc Private Registry cá nhân/công ty. |
| `docker rmi <image>` | **Xóa Image**: Gỡ bỏ image khỏi máy local để giải phóng không gian ổ đĩa. |
| `docker tag <image-gốc> <image-mới>:<tag>` | **Gắn thẻ tag**: Tạo một tên gọi mới hoặc phiên bản mới trỏ tới image gốc (thường dùng trước khi push lên registry mới). |
| `docker image prune` | **Dọn dẹp image rác**: Quét và xóa toàn bộ các image "dangling" (các image trung gian bị mất tag trong quá trình rebuild). |

---

## 🛠️ III. DOCKER BUILDX (Xây dựng nâng cao & Đa nền tảng)

`docker buildx` là một công cụ mở rộng (CLI plugin) mạnh mẽ dựa trên BuildKit, cho phép xây dựng các Docker Image đa cấu trúc CPU (Multi-platform), quản lý cache nâng cao và điều khiển nhiều builder độc lập.

| Câu lệnh | Giải thích chi tiết & Mục đích sử dụng |
| :--- | :--- |
| `docker buildx create --name <tên-builder> --use` | **Tạo và kích hoạt Builder mới**: Khởi tạo một đối tượng builder độc lập sử dụng driver `docker-container` (bắt buộc để chạy được các tính năng buildx nâng cao). |
| `docker buildx ls` | **Xem danh sách các Builders**: Liệt kê các builder hiện có trên máy, trạng thái hoạt động và các hệ điều hành/cấu trúc CPU được hỗ trợ. |
| `docker buildx inspect --bootstrap` | **Kiểm tra & Khởi động Builder**: Hiển thị thông tin chi tiết về builder hiện tại và tự động khởi chạy container của builder đó nếu nó đang tắt. |
| `docker buildx build --platform linux/amd64,linux/arm64 -t <tên-image>:<tag> --push .` | **Build đa nền tảng và Push thẳng lên Registry**: Xây dựng đồng thời image chạy được trên cả chip Intel/AMD (`amd64`) và chip Apple/ARM (`arm64`), sau đó đẩy trực tiếp lên Docker Hub. |
| `docker buildx build --platform linux/amd64 -t <tên-image>:<tag> --load .` | **Build và Lưu vào Local Docker**: Xây dựng image và nạp (load) nó vào bộ lưu trữ local để bạn có thể chạy thử trực tiếp trên máy thông qua `docker run`. |
| `docker buildx build --cache-to type=registry,ref=<registry-repo> --cache-from type=registry,ref=<registry-repo> -t <image> .` | **Build tối ưu hóa Cache trên Registry**: Lưu lại bộ nhớ đệm (build cache) lên registry từ xa và tải về ở lần build sau. Cực kỳ tối ưu cho các hệ thống CI/CD (GitHub Actions, GitLab CI). |
| `docker buildx rm <tên-builder>` | **Xóa Builder**: Gỡ bỏ cấu hình builder đã tạo để dọn dẹp hệ thống. |

---

## 🔍 IV. PHÂN TÍCH & SỬA LỖI (Troubleshooting & Debugging)

Khi container hoạt động không như mong muốn, các lệnh này giúp bạn truy vết lỗi và kiểm tra trạng thái bên trong.

| Câu lệnh | Giải thích chi tiết & Mục đích sử dụng |
| :--- | :--- |
| `docker logs <container>` | **Xem log hệ thống**: In toàn bộ lịch sử log đầu ra (stdout/stderr) của ứng dụng bên trong container ra màn hình terminal. |
| `docker logs -f <container>` | **Theo dõi log thời gian thực**: Treo màn hình để liên tục đón đọc các dòng log mới phát sinh trong container. |
| `docker exec -it <container> sh` (hoặc `bash`) | **Truy cập vào container**: Mở một cửa sổ dòng lệnh trực tiếp bên trong hệ điều hành của container để kiểm tra file, test kết nối hoặc cấu hình. |
| `docker inspect <container>` (hoặc `<image>`) | **Xem thông tin chi tiết**: Trả về toàn bộ cấu hình chi tiết (định dạng JSON) của đối tượng như IP, Network, Volume, Biến môi trường. |
| `docker port <container>` | **Kiểm tra port mapping**: Hiển thị nhanh danh sách cổng của container đang ánh xạ ra cổng nào ngoài máy host. |
| `docker top <container>` | **Xem các tiến trình**: Liệt kê danh sách các process đang chạy thực tế bên trong container đó. |
| `docker diff <container>` | **Kiểm tra thay đổi file**: Liệt kê các file/thư mục đã bị thay đổi, xóa hoặc tạo thêm so với trạng thái ban đầu của Image. |

---

## 💾 V. VOLUMES & NETWORKS (Lưu trữ và Kết nối mạng)

Giúp quản lý dữ liệu bền vững (Persistent Data) và thiết lập kết nối giữa các container.

| Câu lệnh | Giải thích chi tiết & Mục đích sử dụng |
| :--- | :--- |
| `docker volume ls` | **Xem danh sách Volumes**: Liệt kê các vùng lưu trữ độc lập được Docker quản lý. |
| `docker volume create <tên-volume>` | **Tạo vùng lưu trữ mới**: Khởi tạo volume riêng để mount vào container, giữ lại dữ liệu kể cả khi container bị xóa hoàn toàn. |
| `docker volume rm <tên-volume>` | **Xóa volume**: Giải phóng dữ liệu và phân vùng volume (chỉ xóa được khi không container nào đang sử dụng volume này). |
| `docker network ls` | **Xem danh sách mạng**: Liệt kê các mạng ảo hiện có (bridge, host, none, macvlan). |
| `docker network create <tên-mạng>` | **Tạo mạng ảo mới**: Tạo mạng bridge để các container liên kết trong đó tự giao tiếp được với nhau thông qua tên container. |
| `docker network connect <tên-mạng> <container>` | **Kết nối mạng**: Kết nối nóng một container đang chạy vào một mạng ảo cụ thể. |

---

## 🐙 VI. DOCKER COMPOSE (Điều phối đa Container)

Sử dụng file YAML (`docker-compose.yml`) để quản lý toàn bộ hệ thống gồm nhiều dịch vụ (Web, Database, Cache...) chạy cùng nhau.

| Câu lệnh | Giải thích chi tiết & Mục đích sử dụng |
| :--- | :--- |
| `docker compose up -d` | **Khởi chạy hệ thống**: Đọc cấu hình file YAML, tạo mạng ảo, volume và chạy toàn bộ cụm container ở chế độ background. |
| `docker compose down` | **Dừng và dọn dẹp**: Tắt và xóa toàn bộ container, network được sinh ra bởi file compose. Dữ liệu trong volume vẫn được giữ lại. |
| `docker compose down -v` | **Xóa sạch kèm dữ liệu**: Thực hiện shutdown toàn bộ hệ thống và xóa luôn cả các volume được định nghĩa trong file compose. |
| `docker compose ps` | **Kiểm tra trạng thái**: Liệt kê danh sách các container đang chạy thuộc dự án compose hiện tại. |
| `docker compose logs -f` | **Theo dõi log tập trung**: Gom và hiển thị log của tất cả các dịch vụ trong cụm compose theo thời gian thực. |
| `docker compose exec <service-name> <lệnh>` | **Thực thi lệnh trong dịch vụ**: Chạy trực tiếp một câu lệnh bên trong container của dịch vụ được định nghĩa trong file compose. |

---

## 🎯 VII. BÍ KÍP TỐI ƯU (Dành cho DevOps thực chiến)

### 1. Dọn dẹp bộ nhớ ổ đĩa cực nhanh
Docker có thể chiếm rất nhiều dung lượng ổ đĩa qua thời gian dài sử dụng (image cũ, container rác, cache build...). Hãy dùng tổ hợp lệnh sau để dọn dẹp sạch sẽ:
```bash
# Xem dung lượng ổ đĩa Docker đang sử dụng
docker system df

# Dọn sạch container đã stop, image không dùng, build cache
docker system prune -a

# Dọn SẠCH SẼ HOÀN TOÀN (Bao gồm cả các volume dữ liệu không dùng đến)
docker system prune -a --volumes -f
```

### 2. Cấu hình phím tắt (Alias)
Mở file cấu hình Shell của bạn (Ví dụ: `~/.zshrc` trên macOS/Zsh, hoặc `~/.bashrc` trên Linux) và thêm các cấu hình viết tắt giúp thao tác nhanh gấp 3 lần:
```bash
# Docker viết tắt
alias d='docker'
alias dc='docker compose'

# Xem nhanh trạng thái các container với định dạng gọn gàng
alias dps='docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"'

# Xóa nhanh toàn bộ container đã dừng
alias drmclean='docker rm $(docker ps -a -q -f status=exited)'
```
