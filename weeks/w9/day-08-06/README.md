# Day 08/06: GitOps & CI/CD

Em đã hoàn thành xong phần lý thuyết và thực hành của ngày hôm nay rồi ạ:

- [x] **GitHub Actions (plan-on-PR & apply-on-merge):**
  * Em đã hiểu luồng hoạt động chuẩn IaC CI/CD.
  * Tự tạo thành công bài Lab 01 chạy thử trên GitHub Actions (sử dụng local provider).
- [x] **ArgoCD vs Flux, app-of-apps, sync waves:**
  * Em đã so sánh được ưu nhược điểm của 2 công cụ CD.
  * Cài đặt thành công Argo CD lên cụm minikube local (xử lý xong lỗi giới hạn dung lượng metadata của CRD bằng `--server-side`).
  * Hiểu cách dùng Sync Waves để điều khiển thứ tự deploy (cho Database lên trước, Frontend lên sau) và mô hình quản lý nhiều app (App of Apps).
- [x] **Rollback (`git revert` vs `kubectl rollout undo`):**
  * Em đã nắm được tại sao chạy lệnh `kubectl rollout undo` trực tiếp trên cluster là anti-pattern trong GitOps vì sẽ bị cơ chế self-healing của Argo CD ghi đè.
  * Đã thực hành rollback an toàn bằng `git revert` để đồng bộ đúng trạng thái trên Git.

Em cũng đã viết chi tiết các ghi chú lý thuyết và tạo 3 bài Lab mẫu tương ứng trong thư mục `practice/gitops-cicd/` để tiện xem lại sau này.
