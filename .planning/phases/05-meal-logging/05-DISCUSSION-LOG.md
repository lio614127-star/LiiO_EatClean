# Phase 5: Meal Logging (Core Loop) - Discussion Log

**Date:** 2026-04-29
**Areas discussed:** 4/4

## Discussion History

### Area 1: Luồng Thêm bữa ăn (Add Meal Flow UX)

**Q1: Cách hiển thị màn hình Add Meal**
- Options: (1) Modal/Sheet, (2) Push Navigation
- **Selected: 1 — Modal / Sheet**
- Reasoning: Đúng chuẩn Apple, tạo cảm giác "làm nhanh rồi quay lại". Vuốt xuống để thoát cực tiện. Push navigation làm flow nặng nề và mất cảm giác quick action.

**Q2: Chọn loại bữa ăn**
- Options: (1) Chọn trước rồi mở Search, (2) Search xong mới chọn bữa
- **Selected: 1 — Chọn bữa trước**
- Reasoning: User luôn biết mình đang log cho bữa nào. Hỏi ở cuối dễ gây bực bội và phá flow.

### Area 2: Nhập số lượng (Quantity Input)

**Q3: Giao diện nhập số lượng**
- Options: (1) Popup nhỏ gọn tại chỗ, (2) Màn hình Food Detail riêng
- **Selected: 1 — Popup nhập số lượng**
- Reasoning: Tối ưu cho tốc độ và thao tác 1 tay (Tap món -> Nhập -> Add -> Xong). Food detail screen quá nặng cho hành động lặp lại hàng ngày.

### Area 3: Cơ chế lưu (Cart vs Single)

**Q4: Log một hay nhiều món**
- Options: (1) Single Log, (2) Cart / Multi-Log
- **Selected: 2 — Cart / Multi-log**
- Reasoning: Rất quan trọng vì người Việt ăn nhiều món cùng lúc (cơm + thịt + canh). Single log bắt user search nhiều lần gây mệt mỏi. Cart pattern đúng với hành vi thực tế.

### Area 4: Quản lý sửa/xóa bữa ăn (Edit/Delete)

**Q5: Vị trí sửa/xóa**
- Options: (1) Tab "Meals", (2) Trực tiếp ở Dashboard
- **Selected: 2 — Sửa/xoá ngay Dashboard**
- Reasoning: Swipe to delete là pattern quen thuộc. Sửa sai nhanh không cần qua tab khác. Tab Meals sẽ chỉ dùng cho xem lịch sử và chỉnh sửa sâu.

## User Insight
Định hướng cốt lõi: **"Log càng nhanh càng tốt"**, không phải "xem thông tin đẹp". Flow hoàn chỉnh đã chốt:
Tap Add trên Dashboard -> Sheet mở -> Search -> Tap món -> Popup nhập -> Add to cart -> ... -> Bấm Hoàn tất -> Save -> Đóng sheet.

---
*Discussion completed: 2026-04-29*
