# 🔬 Lab 3: Điều phối ứng dụng 3-Tier bằng Docker Compose (Nginx, Flask, Redis)

## 📌 1. Mục tiêu bài lab
*   Thực hành viết file `docker-compose.yml` để định nghĩa hệ thống microservices phức tạp.
*   Thiết lập phân vùng mạng bảo mật (**Network Isolation**): Tách biệt mạng ngoài (Frontend) và mạng trong (Backend) sử dụng mạng Bridge.
*   Cấu hình cơ chế tự động khởi động và kiểm tra sức khỏe dịch vụ (**Healthcheck & depends_on**).
*   Sử dụng Nginx làm **Reverse Proxy** phân phối các yêu cầu đến các container Flask.
*   Thực hành cơ chế **Load Balancing** tích hợp sẵn của Docker DNS khi scale số lượng container.

---

## 🛠️ 2. Mô hình kiến trúc ứng dụng (3-Tier)
```text
                  [ Máy Host ] (Port 80)
                       │
                       ▼ (Mạng frontend-net)
             ┌──────────────────┐
             │   nginx-proxy    │ (Reverse Proxy)
             └─────────┬────────┘
                       │
                       ▼ (Mạng frontend-net & backend-net)
             ┌──────────────────┐
             │  flask-app-1,2   │ (API Services)
             └─────────┬────────┘
                       │
                       ▼ (Mạng backend-net)
             ┌──────────────────┐
             │   redis-cache    │ (Database/In-Memory Cache)
             └──────────────────┘
```

*   **Mạng `frontend-net`:** Chỉ chứa `nginx-proxy` và `flask-app`. Người ngoài có thể truy cập `nginx-proxy`.
*   **Mạng `backend-net`:** Chỉ chứa `flask-app` và `redis-cache`. `redis-cache` hoàn toàn bị ẩn và bảo mật khỏi thế giới bên ngoài.

---

## 🚀 3. Hướng dẫn từng bước (Step-by-Step)

### Bước 1: Chuẩn bị thư mục dự án
Tạo một thư mục trống tên là `lab3-compose-orchestration` và thiết lập các thư mục con và file theo cấu trúc sau:
```text
lab3-compose-orchestration/
├── app/
│   ├── app.py
│   ├── requirements.txt
│   └── Dockerfile
├── nginx/
│   └── default.conf
└── docker-compose.yml
```

#### 1. File `app/app.py` (Mã nguồn Flask API đếm số lượng truy cập dùng Redis)
```python
import os
import socket
from flask import Flask
from redis import Redis

app = Flask(__name__)
# Kết nối tới container Redis bằng hostname 'redis-cache'
redis = Redis(host='redis-cache', port=6379)

@app.route('/')
def index():
    # Tăng giá trị đếm trong Redis
    count = redis.incr('hits')
    # Lấy tên của container đang xử lý request này để kiểm tra load balancing
    container_hostname = socket.gethostname()
    return f"<h2>Ứng dụng Flask [ID: {container_hostname}]</h2>\n" \
           f"<p>Số lượt truy cập được lưu trữ trong Redis: {count}</p>\n"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
```

#### 2. File `app/requirements.txt`
```text
Flask==2.3.3
redis==5.0.1
```

#### 3. File `app/Dockerfile`
```dockerfile
FROM python:3.9-alpine
WORKDIR /code
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
EXPOSE 5000
CMD ["python", "app.py"]
```

#### 4. File `nginx/default.conf` (Cấu hình Nginx Proxy ngược)
Nginx sẽ lắng nghe ở port 80 và điều phối traffic tới service tên là `flask-app` ở port 5000. Do Docker có DNS nội bộ, hostname `flask-app` sẽ tự động trỏ vòng tròn (Round-Robin) tới các container đang chạy của service này.
```nginx
server {
    listen 80;

    location / {
        proxy_pass http://flask-app:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

#### 5. File `docker-compose.yml` (File điều phối chính)
```yaml
version: '3.8'

services:
  # Caching Layer
  redis-cache:
    image: redis:7-alpine
    container_name: redis-cache
    restart: always
    networks:
      - backend-net
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5

  # Application Layer (Flask)
  flask-app:
    build: ./app
    restart: always
    environment:
      - REDIS_HOST=redis-cache
    networks:
      - frontend-net
      - backend-net
    depends_on:
      redis-cache:
        condition: service_healthy # Chỉ chạy Flask khi Redis đã vượt qua bài test healthcheck

  # Web/Proxy Layer (Nginx)
  nginx-proxy:
    image: nginx:1.25-alpine
    container_name: nginx-proxy
    restart: always
    ports:
      - "80:80"
    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
    networks:
      - frontend-net
    depends_on:
      - flask-app

# Khai báo các mạng ảo riêng biệt
networks:
  frontend-net:
    driver: bridge
  backend-net:
    driver: bridge
```

---

### Bước 2: Khởi chạy hệ thống bằng Docker Compose
Mở terminal tại thư mục `lab3-compose-orchestration` và chạy lệnh sau:

```bash
# Xây dựng các image và khởi chạy toàn bộ dịch vụ ở chế độ background
docker compose up -d
```

---

### Bước 3: Thực hành mở rộng (Scale) ứng dụng để Load Balancing
Một trong những sức mạnh lớn nhất của Docker Compose là khả năng tăng số lượng bản sao (Replicas) dễ dàng:

```bash
# Scale dịch vụ flask-app lên 3 container chạy song song
docker compose up -d --scale flask-app=3
```

---

## 📊 4. Kết quả mong đợi & Cách so sánh (Verification)

### Kiểm tra 1: Trạng thái của cụm container
Chạy lệnh hiển thị các tiến trình trong Compose:
```bash
docker compose ps
```
**Kết quả mong đợi:** Sau khi scale lên 3 app, bạn sẽ thấy tổng cộng 5 container đang hoạt động:
```text
NAME                               IMAGE                COMMAND                  SERVICE       STATUS        PORTS
nginx-proxy                        nginx:1.25-alpine    "/docker-entrypoint.…"   nginx-proxy   running       0.0.0.0:80->80/tcp
redis-cache                        redis:7-alpine       "docker-entrypoint.s…"   redis-cache   running (healthy)
lab3-compose-orchestration-flask-app-1  lab3...-flask-app   "python app.py"          flask-app     running       5000/tcp
lab3-compose-orchestration-flask-app-2  lab3...-flask-app   "python app.py"          flask-app     running       5000/tcp
lab3-compose-orchestration-flask-app-3  lab3...-flask-app   "python app.py"          flask-app     running       5000/tcp
```

### Kiểm tra 2: Xác thực tính năng Phân tải (Load Balancing)
Dùng trình duyệt truy cập địa chỉ `http://localhost` (port 80 của Nginx) hoặc dùng lệnh `curl` liên tục:
```bash
curl http://localhost
curl http://localhost
curl http://localhost
```
**Kết quả mong đợi:**
Bạn sẽ thấy ID của Flask App thay đổi liên tục qua các lượt gửi request (do Nginx chuyển tiếp traffic qua cơ chế DNS Round-Robin của Docker), nhưng giá trị Hits trong Redis vẫn liên tục được cộng dồn chính xác:
```text
<h2>Ứng dụng Flask [ID: a1b2c3d4e5f6]</h2>
<p>Số lượt truy cập được lưu trữ trong Redis: 1</p>

<h2>Ứng dụng Flask [ID: f6e5d4c3b2a1]</h2>
<p>Số lượt truy cập được lưu trữ trong Redis: 2</p>

<h2>Ứng dụng Flask [ID: 9x8y7z6w5v4u]</h2>
<p>Số lượt truy cập được lưu trữ trong Redis: 3</p>
```

### Kiểm tra 3: Xác thực phân vùng bảo mật (Network Isolation)
Chúng ta sẽ kiểm tra xem container `redis-cache` có thực sự được bảo mật ở lớp trong hay không.
*   **Thử nghiệm 1:** Quét port từ máy host bên ngoài:
    ```bash
    curl http://localhost:6379
    ```
    **Kết quả mong đợi:** Báo lỗi kết nối hoặc Connection Refused (vì port 6379 không hề được map ra máy host).
*   **Thử nghiệm 2:** Đứng từ container `nginx-proxy` (chỉ thuộc mạng `frontend-net`) ping thử tới `redis-cache`:
    ```bash
    docker exec -it nginx-proxy ping redis-cache
    ```
    **Kết quả mong đợi:** Báo lỗi không tìm thấy host (Bad address/Ping failed) vì Nginx và Redis nằm ở hai phân vùng mạng khác nhau, không có đường kết nối trực tiếp.

---

## 🧹 5. Dọn dẹp tài nguyên (Cleanup)

Sau khi hoàn thành bài Lab, bạn có thể dễ dàng dọn dẹp sạch sẽ toàn bộ tài nguyên bằng Docker Compose:

```bash
# 1. Dừng và xóa toàn bộ container, cùng với các mạng bridge đã tạo
docker compose down

# 2. Xóa các build image và cache image liên quan để giải phóng đĩa
docker rmi lab3-compose-orchestration-flask-app nginx:1.25-alpine redis:7-alpine
```

