# Phase 8: Water Tracking + Smart Reminders + Polish — Discussion Log

**Date:** 2026-04-29
**Areas discussed:** 4/4

## Discussion History

### Area 1: UI nhập nước (Water Logging UX)
- Options: (1) Nút nhanh trên Home, (2) Tách riêng Section/Card với popup
- **Selected: 1 — Nút nhanh trên Home**
- Reasoning: Nước log nhiều lần/ngày, phải 1-tap là xong. Dãy nút +100/+250/+500ml bấm phát cộng luôn. Nếu bắt mở popup, sau 2-3 ngày user sẽ lười log.

### Area 2: Water Visualization
- Options: (1) Trực tiếp trên Home Dashboard, (2) Trong tab Progress
- **Selected: 1 — Trực tiếp trên Home**
- Reasoning: Calories + Water = 2 chỉ số core mỗi ngày. User mở app phải thấy ngay cả hai. Đặt dưới calorie ring tạo "daily dashboard" hoàn chỉnh.

### Area 3: Reminder Strategy
- Options: (1) Nhắc cố định, (2) Interval-based
- **Selected: 2 — Interval-based**
- Reasoning: Linh hoạt hơn. Không ai nhớ set từng giờ cụ thể. Logic đơn giản: Start 8h, End 20h, Interval 2h → 7 lần nhắc tự động. Vẫn dễ code với UNUserNotificationCenter.

### Area 4: Polish Scope
- Options: (1) Tối thiểu — chỉ fix UX, (2) Animation + Micro-interactions
- **Selected: 2 — Animation + Micro-interactions**
- Reasoning: Đây là thứ phân biệt app "tự làm" vs "app xịn". Animation ít nhưng chất: water fill animation + haptic, meal item fade+slide, cart bump, calorie ring sweep. Đúng chỗ + mượt = premium feel.

## User Insight
App không chỉ là "tracker" mà là "daily health dashboard". Home screen = daily control center: user mở app là dùng ngay.

---
*Discussion completed: 2026-04-29*
