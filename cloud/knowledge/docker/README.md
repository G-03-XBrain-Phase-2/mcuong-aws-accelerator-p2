# Kiến thức & Lý thuyết về Container & Docker

## 1. Core Concepts (Khái niệm cơ bản)
* **Containers vs. Virtual Machines (VMs):**
* **Docker Image, Container, Registry:**
* **Dockerfile Syntax:**

## 2. Docker Best Practices
* **Multi-stage Builds:** (Giảm dung lượng image)
* **Layer Caching Optimization:**
* **Non-root User Security:**

## 3. Lệnh thường dùng (Cheatsheet)
* `docker build -t <tag> .`
* `docker run -d -p <host_port>:<container_port> <image>`
* `docker ps`, `docker logs -f <container_id>`
* `docker exec -it <container_id> sh`
