---
status: complete
phase: 02-splash-onboarding
source: [02-PLAN.md]
started: 2026-05-03T02:18:07+07:00
updated: 2026-05-03T02:31:01+07:00
---

## Current Test

[testing complete]

## Tests

### 1. Splash Screen hiển thị và tự chuyển
expected: Xoá app trên Simulator rồi chạy lại. Thấy Splash "LiiO" + "EatClean" với animation, sau ~2s tự chuyển sang Onboarding.
result: pass

### 2. Onboarding 3 slides swipe được
expected: Sau Splash → vào Onboarding. Thấy 3 slides (swipe trái/phải): "Theo dõi Calories", "Xem tiến trình", "Đạt body mong muốn". Mỗi slide có icon lớn + tiêu đề + mô tả. Có nút "Tiếp tục" ở dưới và "Bỏ qua" ở trên.
result: pass

### 3. Goal Setup 3 bước với progress bar
expected: Bấm "Bắt đầu" hoặc "Bỏ qua" → vào Goal Setup. Thấy progress bar ở trên + chỉ số "Bước 1/3". Bước 1: nhập tên, tuổi, chọn giới tính. Bước 2: nhập chiều cao (cm), cân nặng (kg). Bước 3: chọn mục tiêu (Giảm/Giữ/Tăng cân). Có nút "Tiếp tục" và "Quay lại".
result: pass

### 4. Tính calories và chuyển về Home
expected: Ở bước 3, chọn mục tiêu → thấy preview calories hàng ngày (số lớn, ví dụ ~1861 kcal). Bấm "Bắt đầu ngay!" → app lưu thông tin và chuyển về Home Dashboard. Lần sau mở app sẽ vào thẳng Home (không hiện Onboarding nữa).
result: pass

## Summary

total: 4
passed: 4
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none]
