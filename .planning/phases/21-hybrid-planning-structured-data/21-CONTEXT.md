# Phase 21: Hybrid Planning & Structured Data Layer - Context

**Gathered:** 2026-05-09
**Status:** Ready for planning
**Requirements:** PLAN-01, PLAN-02, PLAN-03, PLAN-04, UNIT-01, UNIT-02, UNIT-03, MEAL-01, MEAL-02, MEAL-03

<domain>
## Phase Boundary

Tái cấu trúc toàn bộ hệ thống lập kế hoạch bữa ăn và lớp dữ liệu thực phẩm. Chuyển từ "AI-generated everything" sang "Hybrid Planning" (App tính toán framework, AI lựa chọn nội dung) để đạt tốc độ <10s. Nâng cấp dữ liệu thực phẩm từ chuỗi văn bản sang cấu trúc thành phần (MealComponent) hỗ trợ đơn vị Việt Nam thông minh và hệ thống quy đổi Gram thực tế.

</domain>

<decisions>
## Implementation Decisions

### 1. Hybrid Planning & Candidate Pool (PLAN-01, 02, 03)

- **D-01: Slot-based Pool Sizes:** Giới hạn số lượng ứng viên theo bữa để tối ưu context:
  - Bữa sáng: 12–15 món
  - Bữa trưa/tối: 18–25 món
  - Ăn vặt: 8–12 món
- **D-02: Diversity Engine Rules:** Trước khi gửi sang AI, app thực hiện lọc Diversity:
  - Max 2 món cùng nguyên liệu chính (main ingredient).
  - Max 2 món cùng phương pháp chế biến (cooking style).
  - Max 2 món cùng nhóm tinh bột (carb base).
- **D-03: Scoring System:** Áp dụng bộ 3 trọng số để ưu tiên món ăn:
  - `VietnamesePriorityScore`: Ưu tiên món Việt phổ biến.
  - `AvailabilityScore`: Ưu tiên nguyên liệu dễ kiếm.
  - `PrepTimeScore`: Ưu tiên món phù hợp thời gian nấu nướng thực tế.
- **D-04: Single-pass AI Prompt:** AI chỉ nhận Candidate Pool và Kcal Split do App tính sẵn. AI chỉ đóng vai trò "người lựa chọn và phối hợp" (Matchmaker).

### 2. Structured Meal & MealComponent (MEAL-01, 02, 03)

- **D-05: New Entity `MealComponent`:** Phân rã `FoodItem` thành danh sách các thành phần.
- **D-06: Schema Fields:** Mỗi component bao gồm: `id`, `name`, `grams`, `calories`, `protein`, `carbs`, `fat`, `quantity`, `unit`, `category`, `cookingMethod`, `isOptional`, `substituteGroup`.
- **D-07: Substitute Groups:** Định nghĩa các nhóm thay thế (vd: `fish_lean`, `green_leafy`). Cho phép App tự động swap thành phần cùng nhóm mà không cần AI call.
- **D-08: Auto Recalc:** Khi thay đổi component, tổng macro của món ăn được tính toán lại realtime tại Local.

### 3. Smart Units & FoodPortionProfile (UNIT-01, 02, 03)

- **D-09: Pair-Unit Display:** Hiển thị song song đơn vị dân dã và gram quy đổi: "1 chén (~200g)".
- **D-10: Portion Confidence:** Chấp nhận sai số lâm sàng thay vì cố gắng đạt con số tuyệt đối (vd: Phở ±15%, Cơm ±5%).
- **D-11: Auto-suggest Unit:** Tự động gợi ý đơn vị mặc định theo loại món (Cơm -> chén, Phở -> tô, Trứng -> quả).

### 4. 3-Level Swap & Memory (SWAP-01, 02)

- **D-12: Swap Hierarchy:**
  - **Level 1 (Instant Local Swap <0.3s):** Đổi món trong Candidate Pool cùng loại, kcal ±10-15%.
  - **Level 2 (Smart Refresh 2-5s):** Gọi AI nhẹ sinh thêm 5-10 món mới.
  - **Level 3 (Full AI Rebuild 10s+):** Sinh lại toàn bộ kế hoạch ngày.
- **D-13: Recency Penalty Score:** Lưu `RecentMealUsage` (7 ngày/30 ngày). 
  - Món đã ăn hôm qua hoặc lặp lại nhiều lần sẽ bị giảm mạnh priority trong Candidate Pool (Blacklist tạm thời).
  - Ngoại trừ: Món Favorites hoặc Pinned Meals.

</decisions>

<canonical_refs>
## Canonical References

### Project Context
- `.planning/PROJECT.md` — Hybrid Architecture vision v1.3
- `.planning/REQUIREMENTS.md` — Plan, Unit, Meal requirements

### Code Targets
- `LiiO_EatClean/Features/Meals/MealPlanViewModel.swift` — Cần refactor để hỗ trợ kcal split và candidate selection.
- `LiiO_EatClean/Features/AI/AIService.swift` — Cập nhật prompt single-pass.
- `LiiO_EatClean/Data/Models/FoodItemModel.swift` — Cấu trúc `MealComponent`.
- `LiiO_EatClean/Data/Repositories/MealRepository.swift` — Hỗ trợ lưu trữ structured meals.
- `LiiO_EatClean/Data/Repositories/FoodRepository.swift` — Implement Candidate Selection logic & Scoring.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `FoodRepository.seedDatabaseIfNeeded()`: Nguồn dữ liệu ban đầu cho VietnamesePriorityScore.
- `MealFoodModel` / `MealFood` entity: Sẽ được nâng cấp hoặc thay thế bởi cấu trúc `MealComponent`.
- `ContextBuilder`: Cần sửa đổi để không build full context rườm rà cho planning, chỉ build candidate list.

### Established Patterns
- Repository Pattern cho data access.
- `@Observable` cho ViewModel state.

</code_context>

<specifics>
## Specific Ideas

- **Diversity Implementation:** Sử dụng `Set` các nguyên liệu/style đã có trong pool để lọc nhanh.
- **Penalty Logic:** `priority = (isFavorite ? 2.0 : 1.0) * (1.0 / (frequency7d + 1))`.
- **Unit Conversion Map:** `[FoodCategory: PrimaryUnit]`.

</specifics>

<deferred>
## Deferred Ideas

- Grocery List generation (Phase 22+)
- Social Sharing của structured recipes (Phase 22+)
- Cloud sync cho custom portion profiles (v2.0)

</deferred>

---

*Phase: 21-hybrid-planning-structured-data*
*Context gathered: 2026-05-09*
