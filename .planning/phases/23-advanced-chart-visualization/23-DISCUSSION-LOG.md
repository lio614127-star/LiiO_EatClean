# Phase 23: Advanced Chart Visualization & Custom Date Range - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-10
**Phase:** 23-Advanced Chart Visualization
**Areas discussed:** Custom Date Range Picker, Min/Max Overlay cho Calories, Weight Chart Aggregation, Swipe Navigation

---

## Giao diện Custom Date Range Picker

| Option | Description | Selected |
|--------|-------------|----------|
| A | Thêm Segment thứ 4 mở Bottom Sheet chứa Date Pickers | ✓ |
| B | Dùng Scrollable Chips ngang | |
| C | Long-press để mở Custom Picker | |

**User's choice:** A
**Notes:** User yêu cầu Bottom Sheet bao gồm các preset chọn nhanh và live preview text để giảm ma sát. Text trên segment sẽ đổi từ "Custom" thành "Từ - Đến".

---

## Min/Max Overlay cho Calories

| Option | Description | Selected |
|--------|-------------|----------|
| A | Dùng RangeMark mờ ở background cột Average | ✓ |
| B | Dùng Error Bar dọc nhỏ ở đỉnh cột | |

**User's choice:** A
**Notes:** Không nên dùng biểu đồ kiểu tài chính, cần focus vào wellness. RangeMark cần opacity thấp 15-20%. Chỉ dùng khi aggregate (Weekly/Monthly), không dùng cho view <= 31 ngày. Có highlight nếu anomaly.

---

## Weight Chart trong chế độ Aggregation

| Option | Description | Selected |
|--------|-------------|----------|
| A | Dùng LineMark mượt mà nối các điểm, kết hợp AreaMark | ✓ |
| B | Dùng PointMark rời rạc, không đường nối | |

**User's choice:** A
**Notes:** UX cần smooth, hiển thị Trend Badge ngay trên header kèm Goal Proximity text. Chart không được có min/max overlay để tránh tạo lo lắng về dao động cân nặng.

---

## Swipe Navigation giữa các khoảng thời gian

| Option | Description | Selected |
|--------|-------------|----------|
| A | Giữ nguyên free scroll (chartScrollableAxes) | |
| B | Phân trang (Pagination Swipe) như Apple Health | ✓ |

**User's choice:** B
**Notes:** User muốn có Pagination Swipe vuốt để nhảy qua lại các kỳ thời gian kế tiếp/trước đó. Chart view không tự scroll. Header cập nhật linh hoạt, có nút "Hôm nay".

---
