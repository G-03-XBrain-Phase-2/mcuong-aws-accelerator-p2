# Hướng Dẫn Về Các File Tự Động Sinh Ra Trong Terraform & Sự Nguy Hiểm Khi Xóa State

Khi bạn làm việc với Terraform, ngoài các file cấu hình `.tf` do bạn tự viết, hệ thống sẽ tự động sinh ra một số file quan trọng khác. Tài liệu này giải thích ý nghĩa của từng file và lý do tại sao bạn **tuyệt đối không được tùy ý xóa hoặc sửa đổi** các file trạng thái (`state`).

---

## I. Ý Nghĩa Của Các File Được Sinh Ra

### 1. File `.terraform.lock.hcl` (Dependency Lock File)
* **Ý nghĩa:** Đây là file khóa phiên bản của các **Providers** (ví dụ: AWS, Azure, Google Cloud) mà dự án của bạn sử dụng.
* **Thời điểm sinh ra:** Khi bạn chạy lệnh `terraform init`.
* **Cơ chế hoạt động:** Ghi lại chính xác phiên bản provider đã tải xuống cùng mã băm bảo mật (hashes).
* **Tác dụng:** Đảm bảo tất cả các thành viên trong nhóm (hoặc khi chạy trên môi trường khác) đều tải về **cùng một phiên bản provider** giống hệt nhau, tránh lỗi không tương thích (tương tự `package-lock.json` trong Node.js).

### 2. File `terraform.tfstate` (State File)
* **Ý nghĩa:** Đây là **trái tim** và là file quan trọng nhất của Terraform. Nó lưu trữ toàn bộ bản đồ ánh xạ (mapping) giữa các tài nguyên khai báo trong code HCL (`.tf`) và các tài nguyên thực tế được tạo ra trên Cloud (ví dụ: ID của EC2 instance, VPC, Subnet...).
* **Thời điểm sinh ra:** Khi bạn chạy thành công lệnh `terraform apply` lần đầu tiên.
* **Tác dụng:** Giúp Terraform theo dõi trạng thái hiện tại của hạ tầng. Khi bạn thay đổi code và chạy `apply` lần tiếp theo, Terraform sẽ đọc file này để biết cần phải tạo mới, chỉnh sửa hay xóa tài nguyên nào, thay vì phải tạo lại toàn bộ từ đầu.

> [!WARNING]
> **Cảnh báo bảo mật:** File này chứa rất nhiều thông tin nhạy cảm ở dạng plain-text (chữ thường), bao gồm các khóa truy cập, địa chỉ IP bảo mật, mật khẩu cơ sở dữ liệu... **Tuyệt đối không bao giờ commit file này lên GitHub public**. Hãy thêm nó vào file `.gitignore`.

### 3. File `terraform.tfstate.backup` (State Backup File)
* **Ý nghĩa:** Là bản sao lưu dự phòng của file `terraform.tfstate`.
* **Thời điểm sinh ra:** Mỗi khi bạn chạy một lệnh làm thay đổi trạng thái hạ tầng (như `terraform apply` hoặc `terraform destroy`).
* **Cơ chế hoạt động:** Trước khi ghi đè dữ liệu mới vào `terraform.tfstate`, Terraform sẽ copy toàn bộ dữ liệu trạng thái cũ liền trước đó và lưu vào file `.backup` này.
* **Tác dụng:** Giúp bạn phục hồi hoặc đối chiếu lại hạ tầng cũ nếu quá trình thay đổi mới gặp lỗi nghiêm trọng hoặc làm hỏng file state chính.

---

## II. Sự Nguy Hiểm Khi Xóa File `tfstate` và `tfstate.backup`

Nhiều người mới bắt đầu thường nghĩ rằng xóa các file state đi thì Terraform sẽ chỉ đơn giản là "reset" dự án và tạo lại từ đầu. Nhưng thực tế, điều này dẫn đến những **hậu quả cực kỳ nghiêm trọng**:

```
[ Máy tính của bạn ]                      [ AWS Cloud ]
 ❌ Mất file tfstate                     ⚠️ Tài nguyên cũ
(Terraform mất trí nhớ)  --------->   (Vẫn đang chạy & tính tiền)
```

### 1. Gây Trùng Lặp Tài Nguyên & Tốn Tiền (Duplicate Resources)
Vì không còn file state, Terraform hoàn toàn "mất trí nhớ" và nghĩ rằng chưa có gì được tạo ra. Khi bạn chạy `terraform apply`, Terraform sẽ gửi yêu cầu tạo mới toàn bộ. 
* *Ví dụ:* Một EC2 instance mới sẽ được tạo ra chạy song song với EC2 instance cũ. Bạn sẽ phải **trả tiền gấp đôi** cho cả 2 instance này trong khi chỉ thực sự cần 1 cái.

### 2. Lỗi Xung Đột Hạ Tầng (Resource Conflicts)
Với một số tài nguyên yêu cầu định danh duy nhất trên AWS (như S3 Bucket, IAM Role, Security Group, Route Table...):
* Khi Terraform cố gắng tạo lại từ đầu, AWS sẽ chặn lại và báo lỗi dạng: `BucketAlreadyExists` hoặc `EntityAlreadyExists` (vì tài nguyên cũ vẫn đang chiếm dụng tên đó).
* Kết quả là lệnh `terraform apply` của bạn sẽ **thất bại giữa chừng** và gây lỗi hệ thống.

### 3. Tạo Ra Hạ Tầng "Mồ Côi" (Orphaned / Shadow Resources)
Tất cả tài nguyên cũ đã tạo trước đó sẽ trở thành tài nguyên "mồ côi" trên Cloud. 
* Do mất file state, bạn **không thể** dùng lệnh `terraform destroy` để tự động xóa chúng đi nữa.
* Bạn buộc phải đăng nhập vào AWS Web Console bằng tay, tự tìm kiếm từng tài nguyên một để xóa thủ công. Nếu hệ thống lớn có hàng trăm tài nguyên, việc này sẽ là một thảm họa và rất dễ xóa sót dẫn đến hóa đơn AWS tăng vọt.

---

## III. Hướng Dẫn Quy Trình Làm Việc Đúng Chuẩn

Để tránh các rủi ro mất mát dữ liệu và mất kiểm soát hạ tầng, bạn cần tuân thủ các nguyên tắc sau:

1. **Muốn xóa mọi thứ để làm lại từ đầu?**
   * *Không được xóa file state.*
   * Hãy chạy lệnh:
     ```bash
     terraform destroy
     ```
     Sau khi Terraform dọn dẹp sạch sẽ tài nguyên trên AWS và cập nhật file state về trạng thái trống, lúc này bạn mới chạy lại `terraform apply`.

2. **Luôn cấu hình `.gitignore` cho dự án Terraform:**
   Tạo file `.gitignore` ở thư mục gốc của dự án và thêm các dòng sau để tránh đẩy file state lên Git:
   ```gitignore
   # Loại bỏ các file trạng thái của Terraform
   *.tfstate
   *.tfstate.backup
   
   # Loại bỏ thư mục ẩn chứa provider đã tải về
   .terraform/
   
   # Loại bỏ các file log và crash
   *.log
   crash.log
   ```

3. **Lỡ tay xóa mất file state nhưng tài nguyên vẫn còn trên AWS?**
   * Hãy cố gắng khôi phục file `terraform.tfstate.backup` bằng cách đổi tên nó thành `terraform.tfstate`.
   * Nếu mất cả hai, bạn sẽ phải viết lại code HCL và sử dụng lệnh `terraform import <tên_tài_nguyên> <id_trên_aws>` để liên kết thủ công từng tài nguyên trở lại hệ thống quản lý của Terraform.
