# Cách xác định Port Mapping trong Docker

Khi chạy lệnh `docker ps`, thông tin về port của container sẽ được hiển thị trong cột **PORTS**. 

Ví dụ:
```bash
CONTAINER ID   IMAGE          COMMAND                  CREATED          STATUS          PORTS                                                                                    NAMES
d2bf45e74042   nginx:alpine   "/docker-entrypoint.…"   19 seconds ago   Up 18 seconds   0.0.0.0:3456->3456/tcp, [::]:3456->3456/tcp, 0.0.0.0:38080->80/tcp, [::]:38080->80/tcp   affectionate_jemison
```

Dưới đây là hướng dẫn chi tiết cách đọc thông tin này để biết được số lượng port và port nào được expose bên trong container.

---

## 1. Cấu trúc hiển thị Port của Docker

Định dạng chung cho ánh xạ cổng (port mapping) là:
```text
[IP_Host]:[Port_Host]->[Port_Container]/[Giao_thức]
```

*   **Port_Host** (nằm bên trái dấu `->`): Cổng được mở trên máy Host (máy vật lý hoặc máy ảo chạy Docker). Cổng này dùng để nhận traffic từ ngoài vào.
*   **Port_Container** (nằm bên phải dấu `->`): Cổng chạy thực tế **bên trong container** (inside the container). Đây là cổng mà ứng dụng trong container thực sự lắng nghe (listen).
*   **Giao_thức**: Thường là `tcp` hoặc `udp`.

---

## 2. Phân tích ví dụ cụ thể

Với chuỗi ports:
`0.0.0.0:3456->3456/tcp, [::]:3456->3456/tcp, 0.0.0.0:38080->80/tcp, [::]:38080->80/tcp`

Ta có thể phân tích thành 2 nhóm port như sau:

### Nhóm 1: Port `3456`
*   `0.0.0.0:3456->3456/tcp`
*   `[::]:3456->3456/tcp`
*   **Ý nghĩa:** Cổng **`3456`** bên trong container được ánh xạ ra cổng **`3456`** của máy Host cho cả IPv4 (`0.0.0.0`) và IPv6 (`[::]`).

### Nhóm 2: Port `80`
*   `0.0.0.0:38080->80/tcp`
*   `[::]:38080->80/tcp`
*   **Ý nghĩa:** Cổng **`80`** bên trong container được ánh xạ ra cổng **`38080`** của máy Host cho cả IPv4 (`0.0.0.0`) và IPv6 (`[::]`).

---

## 3. Kết luận

Dựa vào phân tích trên:
1.  **Số lượng port được expose bên trong container:** Có **2 port**.
2.  **Đó là những port nào?** Đó là port **`3456`** và **`80`** (đều sử dụng giao thức TCP).
