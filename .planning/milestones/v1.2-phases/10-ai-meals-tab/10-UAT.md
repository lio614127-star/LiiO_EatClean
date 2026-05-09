# Phase 10: AI-Powered Meals Tab UAT

## Objective
Xác nhận tab Meals mới (với danh sách chi tiết, gợi ý tự động, và hệ thống Learning System) hoạt động chính xác từ góc nhìn của user.

## Test Cases

### 1. Meals Tab Layout & Detailed List
- [x] Mở tab Meals.
- [x] Xác nhận có 4 nhóm bữa ăn (Bữa sáng, Bữa trưa, Bữa tối, Ăn vặt).
- [x] Thêm thử 1 món, vuốt trái để hiện nút Xóa. (Nút Sửa đã được gỡ bỏ vì bấm vào món ăn đã mở bảng chi tiết).
- [x] Xác nhận mỗi món ăn có hiển thị đủ thanh mini-macros P/C/F.

### 2. AI Proactive Suggestions & "Log Ngay"
- [x] Kéo xuống dưới cùng tab Meals. Xác nhận thấy phần "AI Gợi ý" đang tự động load (hoặc báo lỗi nếu chưa có API key).
- [x] Chờ AI hiện gợi ý 2 món. Xác nhận loại bữa ăn (mealType) hiển thị đúng theo giờ hiện tại (VD: đang buổi chiều thì hiện "Ăn vặt" hoặc "Bữa tối").
- [x] Bấm nút "Log Ngay" trên 1 món gợi ý. Xác nhận có animation "Đã log món ăn! ✓" hiện lên và món đó chui lên danh sách bên trên.

### 3. Learning System & Memory Confirmation
- [x] Sang tab Chat (AI Coach).
- [x] Nhắn tin: "Tôi không ăn được hải sản và rất ghét hành tây".
- [x] Xác nhận một Bottom Sheet (Popup) hiện lên: "💡 Phát hiện thông tin mới", hỏi xác nhận lưu "Không thích: hải sản" và "hành tây". Chọn "Lưu".
- [x] Nhắn tin: "Hôm nay tôi ăn bánh mì". Xác nhận KHÔNG có popup nào hiện lên (AI phân biệt được thông tin ngắn hạn và dài hạn).

### 4. Memory Summary Card
- [x] Quay lại tab Meals.
- [x] Xác nhận thấy card "AI nhớ về bạn" hiển thị các tag đỏ/xanh/xám cho sở thích vừa lưu.
- [x] (Tùy chọn) Bấm "Chỉnh sửa" để vào MemoryEditorView và thử xóa 1 sở thích.

---
## Test Log
- **2026-05-04:** Tất cả các test cases đã được xác nhận (Passed) bởi user thông qua gsd-verify-work. Tab Meals và Learning System đã hoạt động ổn định. Ghi nhận lỗi nhỏ về hiển thị lần đầu của danh sách món ăn (đã được khắc phục trong phiên gsd-debug). Phase 10 hoàn thành xuất sắc.
