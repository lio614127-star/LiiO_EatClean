---
wave: 2
depends_on: ["01-01"]
files_modified:
  - LiiO_EatClean/Features/Meals/Services/MealPlanLinkingService.swift
  - LiiO_EatClean/Features/Meals/Services/MealAdherenceCalculator.swift
  - LiiO_EatClean/Features/Meals/Models/DailyNutritionRecord.swift
autonomous: true
---

# Plan 02-01: Business Logic & Services

Mục tiêu: Triển khai engine so khớp (Matching) và tính điểm kỷ luật (Adherence).

<objective>
Tạo các service xử lý logic nghiệp vụ cho việc liên kết bữa ăn, tính điểm kỷ luật và tổng hợp dữ liệu nhật ký ngày.
</objective>

<tasks>
<task id="1">
<title>Tạo MealPlanLinkingService</title>
<action>
Tạo file mới `LiiO_EatClean/Features/Meals/Services/MealPlanLinkingService.swift` với:
- `findCandidateLinks`: Tính similarity giữa MealLog và PlannedMeal.
- `link/unlink`: Hàm tiện ích để thực hiện gán ID chéo.
</action>
<acceptance_criteria>
- File được tạo đúng vị trí.
- Logic so khớp hoạt động với các test case cơ bản (tên món, mealType).
</acceptance_criteria>
</task>

<task id="2">
<title>Tạo MealAdherenceCalculator</title>
<action>
Tạo file mới `LiiO_EatClean/Features/Meals/Services/MealAdherenceCalculator.swift` triển khai công thức:
- 50% Calo (±10% tolerance).
- 25% Protein (trọng tâm).
- 15% Completion (số bữa hoàn thành).
- 10% Fidelity (ăn đúng món).
</action>
<acceptance_criteria>
- Điểm số trả về trong khoảng 0-100.
- Xử lý đúng các trường hợp thiếu dữ liệu.
</acceptance_criteria>
</task>

<task id="3">
<title>Tạo DailyNutritionRecord struct</title>
<action>
Tạo file mới `LiiO_EatClean/Features/Meals/Models/DailyNutritionRecord.swift` để gom:
- `DailyPlan?`
- `[MealModel]` (Actual)
- Tính toán `plannedTotals`, `actualTotals`, `delta`, `adherenceScore`.
</action>
<acceptance_criteria>
- Struct cung cấp đủ dữ liệu cho UI Timeline.
</acceptance_criteria>
</task>
</tasks>
