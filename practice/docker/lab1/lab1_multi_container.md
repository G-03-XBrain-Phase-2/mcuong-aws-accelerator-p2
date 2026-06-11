# 🔬 Lab 1: Triển khai Ứng dụng Multi-Container với Custom Network & Volume (Manual)

## 📌 1. Mục tiêu bài lab
*   Thực hành tạo và quản lý mạng tùy chỉnh (**Custom Bridge Network**) để các container giao tiếp nội bộ.
*   Cấu hình lưu trữ dữ liệu bền vững (**Docker Volume**) cho Database.
*   Cách truyền biến môi trường (**Environment Variables**) vào container.
*   Build ứng dụng Python Flask từ Dockerfile và chạy liên kết với PostgreSQL.
*   Kiểm tra tính bền vững của dữ liệu (Data Persistence) khi container database bị xóa và chạy lại.

---

## 🛠️ 2. Các công cụ & thành phần tham gia
1.  **Database:** PostgreSQL (dùng image `postgres:15-alpine`).
2.  **App:** Python Flask (tự build từ Dockerfile).
3.  **Network:** `backend-net` (mạng bridge riêng biệt).
4.  **Storage:** `postgres-db-data` (volume lưu trữ dữ liệu DB).

---

## 🚀 3. Hướng dẫn từng bước (Step-by-Step)

### Bước 1: Chuẩn bị thư mục và mã nguồn
Tạo một thư mục trống tên là `lab1-multi-container` và tạo các file sau bên trong:

#### 1. File `app.py` (Mã nguồn Flask API)
Ứng dụng sẽ kết nối tới PostgreSQL, tạo bảng và lưu trữ số lần truy cập (counter).
```python
import os
import time
import psycopg2
from flask import Flask

app = Flask(__name__)

# Lấy cấu hình kết nối DB từ biến môi trường
DB_HOST = os.environ.get('DB_HOST', 'db-postgres')
DB_NAME = os.environ.get('DB_NAME', 'mydb')
DB_USER = os.environ.get('DB_USER', 'myuser')
DB_PASS = os.environ.get('DB_PASS', 'mypassword')

def get_db_connection():
    while True:
        try:
            conn = psycopg2.connect(
                host=DB_HOST,
                database=DB_NAME,
                user=DB_USER,
                password=DB_PASS
            )
            return conn
        except psycopg2.OperationalError:
            print("Đang chờ PostgreSQL khởi động...")
            time.sleep(2)

# Khởi tạo bảng visits
conn = get_db_connection()
cur = conn.cursor()
cur.execute('''
    CREATE TABLE IF NOT EXISTS visits (
        id SERIAL PRIMARY KEY,
        count INT NOT NULL
    );
''')
cur.execute('SELECT count FROM visits WHERE id=1;')
row = cur.fetchone()
if not row:
    cur.execute('INSERT INTO visits (id, count) VALUES (1, 0);')
conn.commit()
cur.close()
conn.close()

@app.route('/')
def hello():
    conn = get_db_connection()
    cur = conn.cursor()
    
    # Tăng biến đếm trong Database
    cur.execute('UPDATE visits SET count = count + 1 WHERE id = 1;')
    conn.commit()
    
    # Lấy giá trị mới
    cur.execute('SELECT count FROM visits WHERE id = 1;')
    count = cur.fetchone()[0]
    
    cur.close()
    conn.close()
    return f"<h3>Xin chào! Số lượt truy cập hệ thống hiện tại là: {count}</h3>\n"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

#### 2. File `requirements.txt` (Khai báo thư viện Python)
```text
Flask==2.3.3
psycopg2-binary==2.9.9
```

#### 3. File `Dockerfile` (Xây dựng Image cho Flask App)
```dockerfile
FROM python:3.9-alpine

WORKDIR /app

# Cài đặt các dependencies cần thiết
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy mã nguồn
COPY app.py .

EXPOSE 5000

CMD ["python", "app.py"]
```

---

### Bước 2: Tạo Network và Volume
Mở Terminal và chạy các lệnh sau:

```bash
# 1. Tạo mạng Bridge riêng biệt
docker network create backend-net

# 2. Tạo Volume lưu trữ dữ liệu Postgres
docker volume create postgres-db-data
```

---

### Bước 3: Khởi chạy Container Database (PostgreSQL)
Chạy container Postgres, kết nối vào mạng `backend-net`, mount volume `postgres-db-data` và đặt tên container là `db-postgres` (tên này sẽ làm Hostname cho Flask kết nối).

```bash
docker run -d \
  --name db-postgres \
  --network backend-net \
  -v postgres-db-data:/var/lib/postgresql/data \
  -e POSTGRES_DB=mydb \
  -e POSTGRES_USER=myuser \
  -e POSTGRES_PASSWORD=mypassword \
  postgres:15-alpine
```

---

### Bước 4: Xây dựng & Khởi chạy Container Flask App
```bash
# 1. Build image từ Dockerfile trong thư mục lab1-multi-container
docker build -t flask-counter-app:v1 .

# 2. Chạy container Flask ứng dụng
docker run -d \
  --name web-counter \
  --network backend-net \
  -p 5000:5000 \
  -e DB_HOST=db-postgres \
  -e DB_NAME=mydb \
  -e DB_USER=myuser \
  -e DB_PASS=mypassword \
  flask-counter-app:v1
```

---

### Bước 5: Kiểm tra tính bền vững của dữ liệu (Data Persistence)
Để chắc chắn volume lưu trữ hoạt động đúng cách:
1. Gửi vài request để tăng số lượt truy cập.
2. Xóa bỏ container Database.
3. Tạo lại container Database mới sử dụng chung volume cũ.
4. Kiểm tra xem lượt truy cập cũ có bị mất hay không.

```bash
# Xóa container DB hiện tại
docker rm -f db-postgres

# Tạo lại container DB mới, sử dụng lại volume 'postgres-db-data'
docker run -d \
  --name db-postgres \
  --network backend-net \
  -v postgres-db-data:/var/lib/postgresql/data \
  -e POSTGRES_DB=mydb \
  -e POSTGRES_USER=myuser \
  -e POSTGRES_PASSWORD=mypassword \
  postgres:15-alpine
```

---

## 📊 4. Kết quả mong đợi & Cách so sánh (Verification)

### Kiểm tra 1: Trạng thái container và mạng
Chạy lệnh `docker ps` để kiểm tra cả 2 container có đang ở trạng thái `Up`:
```bash
docker ps
```
**Kết quả mong đợi:**
```text
CONTAINER ID   IMAGE                  COMMAND                  STATUS         PORTS                    NAMES
...            flask-counter-app:v1   "python app.py"          Up 2 minutes   0.0.0.0:5000->5000/tcp   web-counter
...            postgres:15-alpine     "docker-entrypoint.s…"   Up 2 minutes   5432/tcp                 db-postgres
```

Chạy lệnh `docker network inspect backend-net` để đảm bảo 2 container nằm chung mạng:
```bash
docker network inspect backend-net
```
**Kết quả mong đợi:** Trường `"Containers"` phải hiển thị cả 2 container `web-counter` và `db-postgres` với IP nội bộ (ví dụ: `172.18.0.2` và `172.18.0.3`).

### Kiểm tra 2: Hoạt động của ứng dụng
Sử dụng trình duyệt truy cập `http://localhost:5000` hoặc dùng lệnh `curl` nhiều lần:
```bash
curl http://localhost:5000
curl http://localhost:5000
```
**Kết quả mong đợi:**
Mỗi lần chạy lệnh, màn hình phải in ra số lượt truy cập tăng dần:
```text
<h3>Xin chào! Số lượt truy cập hệ thống hiện tại là: 1</h3>
<h3>Xin chào! Số lượt truy cập hệ thống hiện tại là: 2</h3>
```

### Kiểm tra 3: Xác thực Data Persistence (Sau khi tái tạo container DB ở Bước 5)
Sau khi xóa và khởi chạy lại container `db-postgres` ở Bước 5, hãy thực hiện lại lệnh `curl`:
```bash
curl http://localhost:5000
```
**Kết quả mong đợi:**
Giá trị lượt truy cập phải tiếp tục tăng tiếp (ví dụ là `3`), chứ **không được reset về 1**. Điều này chứng tỏ dữ liệu của PostgreSQL lưu trong volume `postgres-db-data` không bị mất đi khi container cũ bị phá hủy.

---

## 🧹 5. Dọn dẹp tài nguyên (Cleanup)

Sau khi hoàn thành bài Lab, hãy chạy các lệnh sau để dọn dẹp sạch sẽ toàn bộ tài nguyên đã tạo, tránh làm rác và nặng máy:

```bash
# 1. Dừng và xóa cưỡng chế các container đang chạy
docker rm -f web-counter db-postgres

# 2. Xóa mạng Bridge tùy chỉnh
docker network rm backend-net

# 3. Xóa volume lưu trữ dữ liệu Database (Thao tác này sẽ xóa vĩnh viễn dữ liệu PostgreSQL)
docker volume rm postgres-db-data

# 4. Xóa image ứng dụng đã build để giải phóng dung lượng ổ đĩa
docker rmi flask-counter-app:v1
```

