---
title: "Custom Date Range Filter & Smart Axis Scaling"
type: feature_request
status: spec_ready
tags: [ui/ux, charts, v1.4]
created: 2026-05-08
updated: 2026-05-10
---

## Ý tưởng / Mô tả
Tối ưu lại bộ lọc thời gian của Progress Chart với Custom Date Range Picker và thiết kế chuẩn Data Visualization tách biệt giữa Calories và Weight.

## Thiết kế UI/UX & Tương tác
- **Header filter:** `7N | 30N | 90N | 1N | Tùy chọn`
- Khi bấm "Tùy chọn": Mở compact date range sheet hoặc calendar picker (Ví dụ: Từ 01/05 -> 31/05).
- Segment đổi tên hiển thị thành: `01/05 -> 31/05` và chart render data tương ứng.
- Swipe trên biểu đồ để sang tháng kế tiếp/trước đó.

## Smart Aggregation Rules (Quan trọng: Average/Day)
Sử dụng Average/Day thay vì Tổng để giữ Visual Scale ổn định và giúp user dễ theo dõi.

- **<= 31 ngày:** Daily bars (Ví dụ: 1, 2, 3...)
- **32 - 120 ngày:** Weekly aggregation (Ví dụ: W1, W2, W3). Tooltip hiển thị: `May 1-7 | Avg: 1980 kcal/day`.
- **> 120 ngày:** Monthly aggregation (Ví dụ: Jan, Feb, Mar).

**Adaptive Axis Density:** Tự động điều chỉnh khoảng cách nhãn trục X. Ví dụ nếu chart nhỏ thì giãn cách label (1, 5, 10), chart rộng thì hiện chi tiết hơn để tránh việc các số bị dính vào nhau.

## Chuyên biệt Visualization: Calories vs Weight

### 1. Calories Chart (Behavior & Volatility)
- **Loại biểu đồ:** Bar chart (Biểu đồ cột).
- **Gom nhóm:** Average aggregation.
- **Min/Max Overlay:** Rất quan trọng! Dùng đường mờ (RangeMark) phía sau cột chính (BarMark) để thể hiện sự chênh lệch lớn (ví dụ: ngày ăn thả ga 4000 kcal). Điều này đảm bảo average không che lấp mất các "peak anomaly".
- **Goal line:** Đường mục tiêu tĩnh.

### 2. Weight Chart (Trend & Progression)
- **Loại biểu đồ:** Smooth Line chart (Biểu đồ đường mượt). KHÔNG dùng Min/Max overlay để tránh gây nhiễu và stress cho user.
- **Gom nhóm:** Average aggregation.
- **Tính năng nổi bật:** Hiển thị Trend direction (Ví dụ: `↓ -1.2kg / 30 ngày`) và Goal proximity (Ví dụ: `Còn 2.4kg tới mục tiêu`).

## [SEED] Tính năng tương lai
- **Trend Smoothing Mode:** Thêm toggle chuyển đổi giữa Raw data và Smoothed data (ví dụ như thuật toán của MacroFactor) để người dùng xem tiến độ thật sự mà không bị stress bởi biến động nước/glycogen hàng ngày.
