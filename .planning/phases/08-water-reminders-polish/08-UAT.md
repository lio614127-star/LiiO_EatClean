---
status: complete
phase: 08-water-reminders-polish
source: [08-SUMMARY.md]
started: 2026-05-03T11:01:14+07:00
updated: 2026-05-03T11:25:25+07:00
---

## Current Test

[testing complete]

## Tests

### 1. Water Card hiển thị trên Home
expected: Mở app, vào tab Home. Cuộn xuống dưới Calorie Ring. Thấy thẻ Water Card với lượng nước uống hôm nay, thanh progress bar, và 3 nút "+100ml", "+250ml", "+500ml".
result: pass

### 2. Thêm nước uống 1 chạm
expected: Bấm nút "+250ml" trên Water Card. Lượng nước uống tăng thêm 250ml ngay lập tức. Thanh progress bar cập nhật animation mượt mà. Có rung nhẹ (haptic feedback) khi bấm.
result: pass

### 3. Calorie Ring Animation
expected: Quay lại đầu trang Home. Vòng tròn Calorie Ring hiển thị lượng calo đã ăn hôm nay với animation quét mượt mà khi view xuất hiện. Nếu vượt mục tiêu, vòng tròn đổi sang màu cam.
result: pass

### 4. Cài đặt Nhắc nhở uống nước (Reminder)
expected: Vào tab Profile. Cuộn xuống mục "Nhắc nhở". Bật toggle nhắc nhở uống nước. Điều chỉnh khoảng thời gian (ví dụ mỗi 2 giờ). Hệ thống hỏi quyền thông báo (notification permission) nếu chưa cấp.
result: pass

### 5. Nhắc nhở bữa ăn (Meal Prompts)
expected: Trong cùng mục Nhắc nhở ở Profile, bật toggle nhắc nhở bữa ăn. Các thông báo nhắc ăn Sáng, Trưa, Tối sẽ được lên lịch.
result: pass

## Summary

total: 5
passed: 5
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none]
