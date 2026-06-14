# 🧠 Cơ Chế Đóng Gói, Dung Lượng & Bảo Mật Docker Image

Tài liệu này giải thích chi tiết về kiến trúc bên dưới của Docker Image, cách Docker quản lý dung lượng qua các lớp (Layers) và các khía cạnh liên quan đến bảo mật mã nguồn (Reverse Engineering).

***

## 1. Cơ Chế Đóng Gói Của Docker (Image Layers & UnionFS)

Một Docker Image không phải là một tệp nén duy nhất mà là sự kết hợp của nhiều **lớp (Layers)** xếp chồng lên nhau thông qua công nghệ **Union File System (UnionFS)**.

```text
┌───────────────────────────────────────────────────────────┐
│ [Read-Write Layer] Container Layer (Chỉ tạo khi Run)      │
├───────────────────────────────────────────────────────────┤
│ [Read-Only Layer 3] Chỉ chứa file `app.py` (Lệnh COPY)    │
├───────────────────────────────────────────────────────────┤
│ [Read-Only Layer 2] Thư viện cài thêm (Lệnh RUN pip)     │
├───────────────────────────────────────────────────────────┤
│ [Read-Only Layer 1] Base Image (Hệ điều hành + SDK)       │
└───────────────────────────────────────────────────────────┘
```

### Cách thức hoạt động:

* <br />

  + *Khi Build:* \* Mỗi câu lệnh trong `Dockerfile ` (như ` FROM `, ` RUN `, ` COPY `) tạo ra một Layer Read-Only mới. Docker nén từng Layer này thành tệp `.tar` và lưu trên ổ đĩa.

* <br />

  + *Khi Push/Pull:* \* Docker chỉ đẩy hoặc tải về các Layer này dưới dạng các khối nén riêng biệt.

* <br />

  + *Khi Run (Khởi chạy):*  \ \ \ * Docker giải nén các lớp này, xếp chồng lên nhau và phủ lên trên cùng một lớp ghi tạm thời (\*  *Read-Write Container Layer* \*). Ứng dụng khi chạy sẽ nhìn thấy toàn bộ hệ thống file hợp nhất từ các Layer bên dưới.

***

## 2. Cách Tính Dung Lượng Docker Image

Về lý thuyết, dung lượng hiển thị của một Image bằng **tổng dung lượng của toàn bộ các Layer** cấu thành nên nó. Tuy nhiên, Docker tối ưu hóa bộ nhớ thông qua cơ chế **Chia Sẻ Layer (Layer Sharing)**:

* <br />

  + *Chia sẻ bộ nhớ:*  \ \ \ * Nếu bạn có 10 images khác nhau sử dụng chung một dòng khai báo `FROM python:3.9-alpine` (nặng \~45MB), Docker chỉ tải và lưu trữ Layer cơ sở này \*  *đúng 1 lần duy nhất* \* trên ổ đĩa máy của bạn.

* <br />

  + *Tính bất biến (Immutability):* \* Các Layer sau khi build là bất biến. Bạn không thể làm giảm dung lượng image bằng cách xóa file ở Layer phía sau nếu file đó đã được ghi ở Layer trước.

  + *Viết sai:*

    ```dockerfile
    RUN wget http://example.com/big-file.zip  # Layer này tăng thêm 100MB
    RUN rm big-file.zip                       # File chỉ bị ẩn đi, image vẫn nặng thêm 100MB
    ```

  + *Viết đúng:*

    ```dockerfile
    RUN wget http://example.com/big-file.zip && rm big-file.zip  # Tải và xóa trên cùng 1 Layer
    ```

***

## 3. Khả Năng Dịch Ngược (Reverse Engineering) Docker Image

Việc lấy lại source code từ một Docker Image là **hoàn toàn khả thi** và mức độ khó/dễ phụ thuộc vào loại ngôn ngữ lập trình:

### A. Đối với ngôn ngữ thông dịch (Python, Node.js, PHP)

* <br />

  + *Đặc điểm:* \* Mã nguồn gốc (Plaintext) được sao chép trực tiếp vào image thông qua lệnh `COPY`.

* <br />

  + *Khả năng lấy code:*  \ \ \ * \*  *Cực kỳ dễ dàng* \*. Bất kỳ ai có quyền pull image đều có thể xem code bằng cách:

  1. Chạy container với shell: `docker run -it <image> sh` rồi đọc các file mã nguồn.
  2. Sử dụng các công cụ phân tích layer trực quan như \ \ \ *\* `dive` \ \ \ *\* để soi từng file được thêm vào ở mỗi layer.
  3. Xuất image thành file tar và giải nén thủ công:

     ```bash
     docker save <image> -o image.tar
     tar -xvf image.tar
     ```

### B. Đối với ngôn ngữ biên dịch (Go, Rust, C++)

* <br />

  + *Đặc điểm:*  \ \ \ * Mã nguồn được biên dịch thành file nhị phân (Binary - mã máy). Khi dùng \*  *Multi-stage build* \*, chỉ có file binary này được copy vào image chạy cuối cùng.

* <br />

  + *Khả năng lấy code:*  \ \ \ * \*  *Khó* \*.

  + Người dùng chỉ tìm thấy file chạy mã máy (ví dụ: file `main ` ), không có các file mã nguồn gốc ( `.go `, `.rs `, `.cpp` ).

  + Để hiểu chương trình làm gì, họ phải sử dụng các công cụ dịch ngược (Decompiler/Disassembler như Ghidra, IDA Pro) để đọc mã Assembly (hợp ngữ). Quá trình này phức tạp và không thể khôi phục lại mã nguồn nguyên bản 100%.

***

## 4. Hướng Dẫn Truy Cập Và Đọc File Trong Container Đang Chạy

Khi một container đang hoạt động (Running), bạn có thể kiểm tra trực tiếp hệ thống file ảo bên trong nó bằng các phương pháp sau:

### Cách A: Truy cập trực tiếp vào Shell tương tác (Interactive Shell)

Sử dụng lệnh `docker exec -it` để mở một phiên Terminal ảo bên trong container:

```bash
# Đối với các container chạy Linux Alpine (nhẹ, không có bash):
docker exec -it <tên-container> sh

# Đối với các container chạy Ubuntu, Debian (hoặc hệ điều hành hỗ trợ bash):
docker exec -it <tên-container> bash
```

Sau khi chui vào shell của container, bạn dùng các câu lệnh Linux bình thường để xem file:

```bash
ls -la
cat app.py
```

*Gõ* \ \ \ * `exit` \* *để thoát shell và quay trở lại máy host.*

### Cách B: Đọc nội dung file trực tiếp từ máy host (Không cần chui vào shell)

Bạn có thể ra lệnh cho container thực thi câu lệnh đọc file và trả kết quả về màn hình của máy host ngay lập tức:

```bash
docker exec <tên-container> cat /app/app.py
```

### Cách C: Sao chép file từ container ra ngoài máy host để đọc

Sử dụng lệnh `docker cp` để copy file:

```bash
# Cú pháp: docker cp <tên-container>:<đường-dẫn-trong-container> <đường-dẫn-máy-host>
docker cp web-counter:/app/app.py ./app_copied.py
```

***

## 5. Các Biện Pháp Bảo Vệ Mã Nguồn

Để bảo vệ tài sản trí tuệ khi đóng gói ứng dụng bằng Docker, các DevOps Engineer thường áp dụng:

1. **Sử dụng Multi-stage Build:** Đảm bảo toàn bộ mã nguồn gốc, công cụ build (SDK, compiler) được loại bỏ hoàn toàn khỏi Image chạy cuối cùng (chỉ giữ lại file chạy hoặc build production).
2. **Làm mờ mã nguồn (Obfuscation):** Đối với các dự án Python, Node.js, sử dụng các công cụ làm mờ code trước khi đóng gói (ví dụ: `PyArmor ` cho Python, ` javascript-obfuscator` cho JS) để chuyển mã nguồn thành dạng không thể đọc/hiểu trực tiếp.
3. **Sử dụng Private Registry có phân quyền:** Không đẩy image lên public repository của Docker Hub nếu ứng dụng chứa thông tin nhạy cảm. Chỉ đẩy lên các Private Registry có bảo mật và phân quyền truy cập rõ ràng.
