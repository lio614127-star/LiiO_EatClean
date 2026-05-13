# Phase 26: Planned vs Actual UI Engine (Smart Daily Journal)

Biến tab Planning thành "Nhật ký thông minh" - tổng hợp cả kế hoạch AI và thực tế ăn uống từ Home/Meals.

## User Review Required

> [!IMPORTANT]
> Thay đổi này yêu cầu cập nhật CoreData Schema để hỗ trợ liên kết giữa Kế hoạch (PlannedMeal) và Thực tế (MealLog).

## Proposed Changes

### 1. Data Layer (CoreData)
- [ ] Thêm `linkedPlannedMealId` (UUID) vào entity `MealLog`.
- [ ] Thêm `status` (String) và `actualMealLogId` (UUID) vào entity `PlannedMeal`.
- [ ] Cập nhật `DailyPlanRepository` để hỗ trợ lưu vết liên kết.

### 2. Business Logic (ViewModel)
- [ ] Tạo `DailyNutritionRecord` struct để gom dữ liệu Plan và Actual theo ngày.
- [ ] Implement logic `smartLink`: Gợi ý gắn MealLog với PlannedMeal dựa trên `mealType` và độ tương đồng tên món.
- [ ] Tính toán `Adherence Score` sơ bộ dựa trên độ lệch Calo/Protein.

### 3. UI Components (SwiftUI)
- [ ] **Timeline View**: Hiển thị xen kẽ các bữa ăn trong kế hoạch và các bữa ăn thực tế (ngoài kế hoạch).
- [ ] **Summary Card**: Hiển thị Progress Ring so sánh Planned vs Actual.
- [ ] **Action Buttons**: 
    - Nút "Đã ăn" trong Plan -> Tạo MealLog và Link.
    - Nút "Gắn với kế hoạch" trong Actual Log -> Link với PlannedMeal.

## Verification Plan

### Automated Tests
- [ ] Unit test cho logic `DailyNutritionRecord` aggregator.
- [ ] Unit test cho logic `smartLink` matching.

### Manual Verification (UAT)
1. Log một món từ Home -> Kiểm tra tab Planning thấy món đó ở phần "Ngoài kế hoạch".
2. Tick "Đã ăn" một món trong Plan -> Kiểm tra Home tab thấy calo tăng lên và Planning tab hiển thị trạng thái "Đã ăn".
3. Log một món từ Meals trùng tên với Plan -> Kiểm tra có hiện gợi ý "Gắn với kế hoạch" không.
