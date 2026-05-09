---
title: "Custom Date Range Filter & Smart Axis Scaling"
type: feature_request
status: new
tags: [ui/ux, charts, v1.2]
created: 2026-05-08
---

## Ý tưởng / Mô tả
Tối ưu lại bộ lọc thời gian của Progress Chart với Custom Date Range Picker và Auto Adaptive Axis.

## Thiết kế UI/UX (được đề xuất bởi User)
- **Header filter:** `7N | 30N | 3T | Tùy chọn`
- Khi bấm "Tùy chọn": Mở compact date range sheet hoặc calendar picker (Ví dụ: Từ 01/05 -> 31/05).
- Segment đổi tên hiển thị thành: `01/05 -> 31/05` và chart render data tương ứng.

## Smart Rendering Logic
- Nếu range <= 7 ngày: Hiện T2 T3 T4...
- Nếu range 8 -> 31 ngày: Hiện 1 5 10 15 20 25 30
- Nếu range > 31 ngày: Auto aggregate theo tuần (W1 W2 W3) hoặc theo tháng (Th1 Th2 Th3).

## Tương tác nâng cao (Apple Health style)
- Bổ sung presets: `7N | 30N | 90N | 1N | Tùy chọn`
- Swipe trên biểu đồ để sang tháng kế tiếp/trước đó.
