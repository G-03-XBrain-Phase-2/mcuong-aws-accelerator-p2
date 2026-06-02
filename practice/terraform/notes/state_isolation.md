# Nguyên Lý Cô Lập Trạng Thái (State Isolation) & Ranh Giới Quản Lý Trong Terraform

Trong thiết kế hệ thống IaC (Infrastructure as Code) chuyên nghiệp, **Cô lập trạng thái (State Isolation)** là một trong những nguyên lý kiến trúc cốt lõi nhất. Việc hiểu rõ ranh giới hoạt động của file State giúp bạn vận hành hạ tầng an toàn, tránh lỗi dây chuyền và tự tin thực hành song song nhiều bài lab.

---

## 1. Ranh Giới Quản Lý Của State (State Boundary)

Nguyên lý cơ bản nhất của Terraform là: **"Terraform chỉ tác động lên những tài nguyên được đăng ký trong file State hiện tại của thư mục đang thực thi."**

```
 [ Tài nguyên thực tế trên AWS ]
 ├── EC2 Instance (Do Lab 01 tạo)   <--->  [ State file Lab 01 ]  <--- Lệnh `apply/destroy` ở Lab 01 chỉ quản lý vùng này!
 ├── GitHub Repo (Do Lab 02 tạo)    <--->  [ State file Lab 02 ]  <--- Lệnh `apply/destroy` ở Lab 02 chỉ quản lý vùng này!
 └── RDS Database (Tạo tay trên Web) <--->  [ Không có State ]     <--- Hoàn toàn vô hình đối với cả hai Lab!
```

* **Tính vô hình:** Bất kỳ tài nguyên nào đang chạy trên Cloud nhưng **không có mã ID được lưu trong file `terraform.tfstate` hiện tại** của bạn đều là "người lạ". Terraform sẽ hoàn toàn bỏ qua chúng khi bạn chạy lệnh `plan`, `apply` hay `destroy`.
* **Tính độc lập:** Mỗi thư mục lab con (ví dụ `lab-01-first-ec2` và `lab-02-github-repo`) sở hữu một file state riêng. Vì vậy, các hành động xóa/sửa ở lab này hoàn toàn không thể ảnh hưởng hay phá hủy tài nguyên của lab kia.

---

## 2. Case Study: Mô Hình "Bootstrap" Lưu Trữ State Từ Xa (Remote Backend)

Mô hình này giải thích tại sao dự án chính sử dụng S3 và DynamoDB để lưu state nhưng không bao giờ xóa chúng khi chạy lệnh hủy hạ tầng.

### Sơ đồ hoạt động của Ranh giới State:

```
┌──────────────────────────────────────┐      ┌──────────────────────────────────────┐
│  THẾ GIỚI 1: Thư mục "Bootstrap"      │      │  THẾ GIỚI 2: Thư mục "Dự án chính"   │
│  - Code: Tạo S3 & DynamoDB           │      │  - Code: Tạo EC2 Instance            │
│  - State: Lưu tại local máy của bạn  │      │  - State: Gửi nhờ trên S3 của TG 1   │
├──────────────────────────────────────┤      ├──────────────────────────────────────┤
│ => Quản lý: S3 Bucket & DynamoDB     │      │ => Quản lý: Chỉ con EC2 Instance     │
└──────────────────────────────────────┘      └──────────────────────────────────────┘
```

* **Tại sao không bị xóa?** 
  Khi bạn đứng ở **Thư mục dự án chính** và chạy `terraform destroy`, Terraform quét file state (đang gửi nhờ trên S3) và thấy nó chỉ quản lý con EC2. Nó chỉ tiến hành xóa con EC2. Chiếc S3 và DynamoDB đóng vai trò là "nơi gửi nhờ" chứ không thuộc danh mục tài nguyên bị quản lý của thư mục này, nên chúng **an toàn tuyệt đối**.
* **Khi nào S3 và DynamoDB mới bị xóa?**
  Chỉ khi bạn quay trở lại **Thư mục Bootstrap** và chạy lệnh `terraform destroy` tại đó, Terraform của môi trường đó mới đọc file local state và tiến hành xóa S3/DynamoDB trên AWS.

---

## 3. Tương Tác Giữa Terraform Và Các Tài Nguyên Tạo Thủ Công (Manual Resources)

Khi bạn tự lên AWS Web Console để tạo tay một tài nguyên (ví dụ một EC2 Instance hoặc S3 Bucket riêng), Terraform của dự án hiện tại sẽ đối xử với nó như thế nào?

### Quy tắc hoạt động:
* **Không xâm phạm:** Terraform sẽ **không chỉnh sửa, không cấu hình lại và không xóa** tài nguyên tạo tay của bạn khi chạy `apply` hay `destroy`.
* **Trường hợp ngoại lệ (Xung đột gián tiếp):** Dù không trực tiếp đụng vào, hệ thống vẫn có thể xảy ra lỗi trong 2 kịch bản sau:

#### Kịch bản A: Trùng định danh duy nhất (Unique Naming Conflict)
AWS yêu cầu một số tài nguyên phải có tên duy nhất toàn cầu (như S3 Bucket).
* Nếu bạn tạo tay một S3 Bucket tên là `cuong-data-storage`.
* Trong code Terraform của bạn, bạn cũng viết code tạo một S3 Bucket trùng tên `cuong-data-storage`.
* **Kết quả:** Khi chạy `apply`, Terraform sẽ báo lỗi `BucketAlreadyExists` từ AWS API chứ không tự động đè hay xóa cái bucket tạo tay trước đó.

#### Kịch bản B: Ràng buộc phụ thuộc chéo (Dependency Block)
* Bạn dùng Terraform để tạo một mạng chung (VPC) và một nhóm bảo mật (Security Group).
* Bạn lên AWS Web Console tạo tay một EC2 và **gán nó vào Security Group do Terraform quản lý**.
* **Kết quả:** Khi bạn chạy `terraform destroy` trong dự án Terraform, nó sẽ cố gắng xóa Security Group. Nhưng AWS API sẽ trả về lỗi chặn lại vì: *"Security Group này đang được sử dụng bởi một máy chủ khác (con EC2 bạn tạo tay)"*. Lệnh destroy sẽ bị thất bại một phần.

---

## 4. Lợi Ích Của State Isolation Trong Thực Tế Doanh Nghiệp

Trong các tập đoàn lớn, hạ tầng không bao giờ được quản lý chung một file state duy nhất, mà bắt buộc phải áp dụng State Isolation theo 2 chiều:

1. **Cô lập theo Môi trường (Environment Isolation):**
   * Tách biệt hoàn toàn giữa `Dev`, `Staging`, và `Production`. 
   * Lỗi cấu hình lỡ tay chạy `destroy` ở môi trường `Dev` không bao giờ có thể ảnh hưởng đến các máy chủ đang chạy thực tế của khách hàng ở `Production`.
2. **Cô lập theo Nhóm hạ tầng (Layered Isolation):**
   * Chia nhỏ hạ tầng thành các lớp riêng biệt: Lớp Mạng (`VPC, Subnets`), Lớp Cơ sở dữ liệu (`RDS`), và Lớp Ứng dụng (`EC2, ECS`).
   * Thay đổi nhỏ ở code deploy ứng dụng không sợ làm ảnh hưởng hay sập toàn bộ hệ thống mạng cốt lõi của doanh nghiệp (giảm thiểu **Blast Radius** - Bán kính ảnh hưởng khi có sự cố).
