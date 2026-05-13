---
wave: 3
depends_on: ["02-01"]
files_modified:
  - LiiO_EatClean/Features/Meals/MealPlanViewModel.swift
autonomous: true
---

# Plan 03-01: ViewModel Refactoring

Mục tiêu: Chuyển đổi logic hiển thị của MealPlanViewModel sang dạng Journal.

<objective>
Tích hợp các service mới vào ViewModel để quản lý trạng thái nhật ký ngày và hỗ trợ các hành động liên kết/bỏ qua bữa ăn.
</objective>

<tasks>
<task id="1">
<title>Tích hợp DailyNutritionRecord vào ViewModel</title>
<read_first>
- LiiO_EatClean/Features/Meals/MealPlanViewModel.swift
</read_first>
<action>
- Thêm thuộc tính `@Published var dailyRecord: DailyNutritionRecord?`.
- Cập nhật hàm `loadDailyPlan` để fetch cả Actual Meals và build `dailyRecord`.
</action>
<acceptance_criteria>
- `dailyRecord` được cập nhật mỗi khi dữ liệu plan hoặc meals thay đổi.
</acceptance_criteria>
</task>

<task id="2">
<title>Triển khai logic Smart Linking trong ViewModel</title>
<action>
- Hàm `checkLinkingCandidates`: Gọi `MealPlanLinkingService` khi có MealLog mới.
- Quản lý danh sách `pendingLinks` để hiển thị UI gợi ý.
</action>
<acceptance_criteria>
- ViewModel nhận diện được các món cần link.
</acceptance_criteria>
</task>

<task id="3">
<title>Xử lý các hành động Mark As Eaten / Skip</title>
<action>
- `markPlannedMealAsEaten(id: UUID)`: Tạo MealLog thực tế và thực hiện link.
- `skipPlannedMeal(id: UUID)`: Cập nhật status thành skipped.
</action>
<acceptance_criteria>
- Trạng thái PlannedMeal cập nhật đúng.
- Không tạo double MealLog khi bấm "Đã ăn".
</acceptance_criteria>
</task>
</tasks>
