# 🐳 THƯ MỤC THỰC HÀNH DOCKER LABS

Thư mục này chứa chuỗi các bài thực hành (Lab) thực chiến từ mức độ Trung bình đến Khá, được thiết kế dựa trên nội dung khóa học **Docker for the Absolute Beginner - Hands On - DevOps**.

Các bài lab này giúp bạn củng cố kiến trúc Docker, cách đóng gói ứng dụng tối ưu, cách liên kết hệ thống đa dịch vụ và bảo mật mạng lưới container.

---

## 📑 Danh sách các bài Lab

### [🔬 Lab 1: Triển khai Ứng dụng Multi-Container với Custom Network & Volume (Manual)](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/docker/lab1_multi_container.md)
*   **Chủ đề tập trung:** Docker Network, Storage Volume, Biến môi trường, Đọc log & Khắc phục sự cố.
*   **Độ khó:** Trung bình.
*   **Kịch bản:** Xây dựng thủ công cụm ứng dụng Flask kết nối cơ sở dữ liệu PostgreSQL. Thiết lập volume riêng để đảm bảo dữ liệu truy cập không bị mất đi khi xóa container database.

### [🔬 Lab 2: Tối ưu kích thước Image với Multi-Stage Build & Private Registry](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/docker/lab2_multistage_registry.md)
*   **Chủ đề tập trung:** Viết Dockerfile tối ưu (Multi-stage), Giảm dung lượng Image, Quản lý Docker Registry local.
*   **Độ khó:** Khá.
*   **Kịch bản:** Biên dịch ứng dụng bằng ngôn ngữ Go. So sánh trực quan kích thước image khi build thông thường (>250MB) và build tối ưu (<15MB). Setup một Docker Registry local và thực hành tag/push/pull ảnh.

### [🔬 Lab 3: Điều phối ứng dụng 3-Tier bằng Docker Compose (Nginx, Flask, Redis)](file:///Users/enma/Downloads/Coding/Cloud_Engineer/Unitled/devops/practice/docker/lab3_compose_orchestration.md)
*   **Chủ đề tập trung:** Viết file `docker-compose.yml`, Phân tách mạng bảo mật (Network Isolation), Tự động kiểm tra sức khỏe (Healthcheck), Tự động phân tải (Load Balancing & Scale-up).
*   **Độ khó:** Khá.
*   **Kịch bản:** Triển khai một kiến trúc 3 lớp gồm Nginx Proxy ngược ở ngoài cùng, một cụm Flask API xử lý logic ở giữa, và cơ sở dữ liệu Redis Cache ở trong cùng. Thực hành scale cụm API lên nhiều container và kiểm tra cơ chế tự động cân bằng tải của Docker DNS.

---

## 💡 Gợi ý quy trình thực hành
1.  Đọc kỹ phần **Mục tiêu** và **Mô hình kiến trúc** của từng bài Lab.
2.  Tự tạo các thư mục trống tương ứng ngoài máy (hoặc trong thư mục `practice/docker/`) để viết các file mã nguồn (`app.py`, `Dockerfile`, `docker-compose.yml`...) theo hướng dẫn.
3.  Thực hiện chạy các câu lệnh trên Terminal.
4.  So sánh kết quả đầu ra trên màn hình Terminal của bạn với phần **Kết quả mong đợi & Cách so sánh (Verification)** ở cuối mỗi bài lab để tự đánh giá mức độ hoàn thành.
