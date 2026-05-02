# Phase 6: Progress & Weight Tracking - Discussion Log

**Date:** 2026-04-29
**Areas discussed:** 4/4

## Discussion History

### Area 1: Trải nghiệm nhập cân nặng (Weight Logging Flow)

**Q1: Giao diện nhập cân nặng**
- Options: (1) Quick Input Card tĩnh, (2) Nút Floating / Modal
- **Selected: 2 — Nút Floating / Modal**
- Reasoning: Giữ không gian sạch cho biểu đồ (rất quan trọng ở tab Progress). Khi cần mới nhập là đúng hành vi thực tế. Bottom sheet nhanh, tập trung, không chiếm chỗ cố định như Input Card.

### Area 2: Tổ chức biểu đồ (Chart Layout)

**Q2: Layout các biểu đồ**
- Options: (1) Tất cả trên 1 cuộn, (2) Phân trang (Segmented Control)
- **Selected: 2 — Phân trang**
- Reasoning: Tách rõ Intake (Calo) và Outcome (Cân nặng). Tránh 2 chart hiện cùng lúc gây quá tải thông tin (overload). Dùng Segmented Control rõ ràng, dễ hiểu, chuẩn style Apple.

### Area 3: Lịch sử Calo hiển thị gì? (Calorie History)

**Q3: Loại biểu đồ Calo**
- Options: (1) Tổng Calo (Bar Chart), (2) Stacked Macro (Bar Chart chia 3 màu)
- **Selected: 1 — Chỉ hiện tổng calo**
- Reasoning: Dễ đọc ngay lập tức hôm nay ăn nhiều hay ít. Kèm theo đường Goal là đủ insight. Biểu đồ Stacked đẹp nhưng quá tải cho v1, hơn nữa Macro đã được tập trung hiển thị chi tiết ở trang Home rồi.

### Area 4: Chuyển đổi thời gian (Time Range Toggle)

**Q4: Nút filter thời gian**
- Options: (1) Toggle dùng chung (Tuần/Tháng), (2) Toggle riêng từng chart
- **Selected: 1 — Toggle dùng chung**
- Reasoning: Tránh việc mỗi chart một kiểu thời gian gây rối não. User nghĩ đơn giản: "Xem tuần này" hoặc "Xem tháng này".

## User Insight
Định hướng cốt lõi: **Progress tab không phải để show nhiều data, mà để user hiểu xu hướng trong 2 giây.**

Layout chốt:
```text
[ Segmented: Calo | Cân nặng ]

[ Biểu đồ chính ]

[ Toggle: Tuần | Tháng ]

[ (Floating button) + Log Weight ]
```

---
*Discussion completed: 2026-04-29*
