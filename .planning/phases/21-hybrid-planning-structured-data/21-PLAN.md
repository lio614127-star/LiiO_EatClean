# Phase Plan: Phase 21 — Next-Gen Nutrition & AI Planning Update

## Goal
Nâng cấp trải nghiệm lập kế hoạch và dữ liệu món ăn: Siêu tốc (Single-pass), Streaming UX, Nhận diện đơn vị thông minh (Smart Units), và tích hợp AI Cooking Coach chi tiết.

## Proposed Changes

### Wave 1: Turbo Daily Planning & All-in-one AI Orchestration
- [ ] [AIService] Thêm method `generateDayPlanStream` xử lý single-pass prompt.
- [ ] [AIOrchestrator] Implement partial JSON parser để yield kết quả từng bữa ăn.
- [ ] [MealPlanViewModel] Refactor `generateDayPlan` để sử dụng streaming API.
- [ ] [MealPlanView] UI: Thêm Skeleton loading + Model status indicator.

### Wave 2: Smart Unit Recognition & Composed Food Schema Updates
- [ ] [FoodItemModel] Thêm fields: `unit`, `weightInGrams`, `ingredients`, `instructions`.
- [ ] [ContextBuilder] Cập nhật prompt để AI trả về thông tin unit và bóc tách nguyên liệu.
- [ ] [MealPlanViewModel] Logic convert đơn vị realtime (unit <-> gram).

### Wave 3: Recipe Detail View & Ingredient Breakdown UI
- [ ] [MealDetailSheet] Design lại giao diện hiển thị nguyên liệu và thông số dinh dưỡng chi tiết.
- [ ] [MealDetailViewModel] Logic fetch/cache công thức nấu ăn (Ingredients/Instructions).

### Wave 4: AI Cooking Coach Deep-link & Instruction Flow
- [ ] [MealDetailSheet] Thêm nút "AI dạy nấu ăn".
- [ ] [Navigation] Implement Deep-link từ Meals sang Chat với payload Recipe context.
- [ ] [ChatViewModel] Xử lý context nấu ăn tự động khi nhận payload từ Meal Detail.

### Wave 5: Magic Swap & Interactive Plan Editor UI
- [ ] [PlanningEngine] [NEW] Module xử lý "Similarity Score" cho local swap.
- [ ] [MealPlanViewModel] Tích hợp Magic Swap UI (10 gợi ý tức thì).
- [ ] [MealPlanView] Cho phép sửa/thay thế/thêm món thủ công vào plan.

## Verification Plan

### Automated Tests
- `TestTurboPlanningStreaming`: Kiểm tra khả năng parse partial JSON của AIOrchestrator.
- `TestUnitConversion`: Kiểm tra tính toán macro khi đổi unit -> gram.
- `TestSimilarityScore`: Kiểm tra độ chính xác của local swap engine.

### Manual Verification
1. Mở Meal Plan, chọn "Lên kế hoạch ngày".
2. Kiểm tra Skeleton hiện đủ 4 bữa, sau đó fill dần từ Sáng -> Vặt.
3. Kiểm tra Model Indicator hiện đúng model đang chạy.
4. Mở chi tiết 1 món, kiểm tra danh sách nguyên liệu.
5. Bấm "AI dạy nấu ăn", kiểm tra app nhảy sang tab Chat và AI bắt đầu chào hỏi về món đó.
6. Thử thay đổi unit (chén -> gram) và kiểm tra calories update.
7. Thử dùng Magic Swap cho 1 bữa và kiểm tra tốc độ (<1s).
