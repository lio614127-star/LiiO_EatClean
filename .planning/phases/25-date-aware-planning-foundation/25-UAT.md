---
status: in-progress
phase: 25-date-aware-planning-foundation
source: [25-VALIDATION.md]
started: 2026-05-12T04:46:00Z
updated: 2026-05-12T06:05:00Z
---

## Current Test
<!-- OVERWRITE each test - shows where we are -->

number: 3
name: Save Drafts correctly
expected: |
  Tạo kế hoạch cho hôm nay, đóng màn hình, mở lại.
  Đảm bảo kế hoạch "nháp" được tải ngay lập tức từ bộ nhớ mà không cần tạo lại từ AI.
result: pass

## Tests

### 1. Create new DailyPlan for selected date
expected: Mở Kế hoạch ngày, chọn ngày mai. Đảm bảo màn hình hiển thị đúng ngày đã chọn và không tự động thoát.
result: pass

### 2. Retrieve old DailyPlan
expected: Chọn một ngày trong quá khứ. Đảm bảo kế hoạch cũ được tải lên và các nút "Thêm/Log" được ẩn đi (View Only).
result: pass

### 3. Save Drafts correctly
expected: Tạo kế hoạch cho hôm nay, đóng màn hình, mở lại. Đảm bảo kế hoạch "nháp" được tải ngay lập tức từ bộ nhớ mà không cần tạo lại từ AI.
result: pass

## Summary

total: 3
passed: 3
issues: 0
pending: 0
skipped: 0

## Gaps

- none yet
