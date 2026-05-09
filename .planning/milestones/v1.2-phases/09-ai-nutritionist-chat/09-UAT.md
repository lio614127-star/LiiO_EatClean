---
status: testing
phase: 09-ai-nutritionist-chat
source: [09-SUMMARY.md]
started: 2026-05-03T13:22:31+07:00
updated: 2026-05-03T13:22:31+07:00
---

## Current Test
<!-- OVERWRITE each test - shows where we are -->

[All tests passed]

## Tests

### 1. Chat Tab Hiển Thị
expected: Mở app, nhìn thanh Tab Bar bên dưới. Phải thấy Tab thứ 5 tên "AI Coach" với icon tin nhắn. Tap vào tab → thấy màn hình chat với thanh nhập liệu phía dưới và tin nhắn chào mừng từ AI.
result: pass

### 2. Gửi Tin Nhắn Thường
expected: Trong tab AI Coach, gõ "Chào bác sĩ" và nhấn nút gửi. Typing indicator (3 chấm nhấp nháy) hiện ra trong lúc chờ. AI trả lời bằng giọng thân thiện, không có nút Log Meal nào xuất hiện (vì đây là câu chào thông thường).
result: pass

### 3. Gợi Ý Món Ăn Actionable
expected: Gõ "Tôi vừa ăn 1 bát phở bò". AI trả lời kèm theo một thẻ Action Card hiển thị tên món (Phở bò), lượng calo, macros (P/C/F), và nút "Log Ngay" màu xanh.
result: pass

### 4. Log Meal Trực Tiếp Từ Chat
expected: |
  Nhấn nút "Log Ngay" trên thẻ Action Card ở test 3. Hệ thống lưu món ăn vào trạng thái "Suggestion" (chưa tính calo). 
  Vào Home tab, bấm vào bữa ăn tương ứng, tick chọn món đó -> Calories Dashboard cập nhật đúng tỉ lệ.
  Đã sửa: Logic tính tỉ lệ calo/khẩu phần và tự động điền số lượng.
result: pass

### 5. Hybrid Context Injection (7 Ngày)
expected: Gõ "Dạo này tôi ăn thế nào?". AI trả lời có tham chiếu đến dữ liệu ăn uống gần đây (hoặc nói rằng chưa có dữ liệu nếu chưa log). Phản hồi mang tính nhận xét, đánh giá (không chỉ là câu chào chung chung).
result: pass

### 6. Markdown Rendering
expected: AI trả lời có chứa text in đậm (**bold**) hoặc danh sách (-). Text hiển thị đúng định dạng (in đậm thật sự, danh sách có bullet) chứ không hiển thị dấu ** hay dấu -.
result: pass

## Summary

total: 6
passed: 6
issues: 0
pending: 0
skipped: 0

## Gaps

[none]
