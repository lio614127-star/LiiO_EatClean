---
wave: 1
depends_on: []
files_modified:
  - LiiO_EatClean/Data/Models/DailyPlanModel.swift
  - LiiO_EatClean/Data/Models/MealModel.swift
  - LiiO_EatClean/Data/Repositories/DailyPlanRepository.swift
  - LiiO_EatClean/Data/Repositories/MealRepository.swift
autonomous: true
---

# Plan 01-01: Data Layer & Repository Foundation

Mục tiêu: Cập nhật cấu trúc dữ liệu để hỗ trợ liên kết giữa Thực tế (MealLog) và Kế hoạch (PlannedMeal).

<objective>
Cập nhật các Model và Repository để lưu trữ thông tin liên kết, trạng thái bữa ăn (eaten/skipped) và nguồn gốc bữa ăn.
</objective>

<tasks>
<task id="1">
<title>Cập nhật DailyPlanModel</title>
<read_first>
- LiiO_EatClean/Data/Models/DailyPlanModel.swift
</read_first>
<action>
Thêm các thuộc tính sau vào `PlannedMealModel`:
- `var status: String` (mặc định "planned")
- `var actualMealLogId: UUID?`
- `var eatenAt: Date?`
</action>
<acceptance_criteria>
- `PlannedMealModel` có đầy đủ 3 thuộc tính mới.
- Code compile thành công.
</acceptance_criteria>
</task>

<task id="2">
<title>Cập nhật MealModel</title>
<read_first>
- LiiO_EatClean/Data/Models/MealModel.swift
</read_first>
<action>
Thêm các thuộc tính sau vào `MealModel`:
- `var linkedPlannedMealId: UUID?`
- `var source: String` (mặc định "manual")
</action>
<acceptance_criteria>
- `MealModel` có đầy đủ 2 thuộc tính mới.
- Code compile thành công.
</acceptance_criteria>
</task>

<task id="3">
<title>Cập nhật DailyPlanRepository mapping</title>
<read_first>
- LiiO_EatClean/Data/Repositories/DailyPlanRepository.swift
</read_first>
<action>
Cập nhật logic `mapPlannedMeal` và `savePlan` để xử lý các field `status`, `actualMealLogId`, `eatenAt`.
Note: Vì CoreData entity chưa cập nhật attribute, hiện tại chỉ cần cập nhật ở mức Model và Repository mapping logic (sử dụng placeholder hoặc chuẩn bị sẵn code migration).
</action>
<acceptance_criteria>
- Repository mapping xử lý đúng các field mới.
</acceptance_criteria>
</task>

<task id="4">
<title>Cập nhật MealRepository mapping</title>
<read_first>
- LiiO_EatClean/Data/Repositories/MealRepository.swift
</read_first>
<action>
Cập nhật logic `saveMeal` và `fetchMeals` để xử lý `linkedPlannedMealId` và `source`.
</action>
<acceptance_criteria>
- MealRepository mapping xử lý đúng các field mới.
</acceptance_criteria>
</task>
</tasks>
