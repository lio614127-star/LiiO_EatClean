---
wave: 4
depends_on: ["03-01"]
files_modified:
  - LiiO_EatClean/Features/Meals/Components/MealPlanSheet.swift
  - LiiO_EatClean/Features/Meals/Components/DailySummaryCardView.swift
autonomous: true
---

# Plan 04-01: UI Upgrade (Smart Journal View)

Mục tiêu: Nâng cấp giao diện Unified Timeline và Summary Card.

<objective>
Tạo giao diện nhật ký ngày trực quan, phân biệt rõ Kế hoạch và Thực tế, kèm theo các chỉ số Adherence.
</objective>

<tasks>
<task id="1">
<title>Nâng cấp Daily Summary Card</title>
<read_first>
- LiiO_EatClean/Features/Meals/Components/DailySummaryCardView.swift
</read_first>
<action>
- Hiển thị song song Planned vs Actual Totals.
- Thêm vòng tròn tiến độ hoặc thanh bar so sánh.
- Hiển thị Adherence Score và nhãn trạng thái (Tuyệt vời, Cần điều chỉnh...).
</action>
<acceptance_criteria>
- UI hiển thị rõ sự khác biệt giữa Plan và Actual.
</acceptance_criteria>
</task>

<task id="2">
<title>Triển khai Unified Timeline trong MealPlanSheet</title>
<read_first>
- LiiO_EatClean/Features/Meals/Components/MealPlanSheet.swift
</read_first>
<action>
- Thay đổi cấu trúc list thành các block theo `MealType`.
- Trong mỗi block, hiển thị:
    - Planned items (với nút Check/Skip).
    - Linked items (Xanh lá).
    - Unplanned items (Vàng/Cam).
- Sử dụng màu sắc và icon theo Specs.
</action>
<acceptance_criteria>
- Timeline hiển thị đúng thứ tự thời gian và trạng thái.
</acceptance_criteria>
</task>

<task id="3">
<title>Thêm Inline Chip gợi ý Smart Linking</title>
<action>
- Hiển thị chip "Gắn vào Plan?" dưới các món Unplanned nếu có candidate link từ ViewModel.
- Bấm nút xác nhận để thực hiện link.
</action>
<acceptance_criteria>
- Giao diện gợi ý xuất hiện đúng lúc, đúng chỗ.
</acceptance_criteria>
</task>
</tasks>
