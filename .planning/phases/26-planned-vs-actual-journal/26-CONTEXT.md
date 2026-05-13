# Phase 26: Planned vs Actual UI Engine (Smart Daily Journal) - Context

**Gathered:** 2026-05-12
**Status:** Ready for planning

<domain>
## Phase Boundary
Tab "Lên kế hoạch ngày" trở thành Smart Daily Journal: tổng hợp kế hoạch AI, thực tế đã ăn, món ngoài kế hoạch và trạng thái adherence.

</domain>

<decisions>
## Implementation Decisions

### 1. Smart Linking (Passive Logging, Active Linking)
- **Cơ chế:** MealLog luôn được tạo trước như actual intake. Linking với PlannedMeal là hành động riêng.
- **Auto-link:** KHÔNG silent auto-link mặc định. Chỉ auto-link khi user bấm trực tiếp "Đã ăn" từ PlannedMeal.
- **Giao diện:** 
    - Nếu match >= 80%: Hiện inline chip "Gắn vào Plan?" dưới món vừa log.
    - Trong Planning Tab: Mọi MealLog chưa link hiện trong nhóm "Ngoài kế hoạch" kèm nút Link 🔗.
- **Rule chống double count:** Calo thực tế chỉ tính từ MealLog. PlannedFoodItem không được cộng vào actual totals.

### 2. Unified Timeline (Smart Daily Journal)
- **Cấu trúc:** Sử dụng Unified Timeline theo mealType/time.
- **Vị trí:** Món ngoài kế hoạch xuất hiện đúng bữa/thời điểm log (không gom xuống cuối).
- **Trình bày:**
    - Bữa đúng plan: Xanh nhẹ, icon ✅.
    - Bữa chưa ăn: Xám/mờ, icon ⏳.
    - Bữa ngoài kế hoạch: Vàng/cam nhẹ, có tag "Ngoài kế hoạch".
    - Expandable group cho nhiều món ngoài kế hoạch trong cùng một bữa.

### 3. Adherence Score (Điểm bám kế hoạch)
- **Trọng số:**
    - 50% Calorie adherence (Tolerance ±5-10%).
    - 25% Protein adherence (Trọng tâm EatClean, thiếu bị trừ nặng).
    - 15% Meal completion/rhythm (Hoàn thành các bữa planned).
    - 10% Plan fidelity (Ăn đúng món đã plan - chỉ là bonus nhẹ).
- **Phân loại:** 90-100 (Tuyệt vời), 75-89 (Tốt), 60-74 (Lệch nhẹ), < 40 (Lệch nhiều).

### 4. Skip & AI Rebalance
- **Skip:** PlannedMeal.status = skipped. Không tạo MealLog. Gợi ý rebalance sau khi skip.
- **Rebalance Trigger:** Hiện CTA "Tái cấu trúc bữa còn lại" khi lệch > 150 kcal hoặc > 10% calo, hoặc thiếu > 15g protein.
- **AI Rebalance Rules:** Chỉ được sửa các PlannedMeal CHƯA ĂN. Phải có preview Before/After trước khi user chốt lưu.

</decisions>

<canonical_refs>
## Canonical References

### Data Models
- [DailyPlanModel.swift](file:///Users/liio/TooL_LiiO/LiiO_EatClean/LiiO_EatClean/Data/Models/DailyPlanModel.swift) — Schema cho Plan.
- [MealModel.swift](file:///Users/liio/TooL_LiiO/LiiO_EatClean/LiiO_EatClean/Data/Models/MealModel.swift) — Schema cho Actual Meals.

### Repositories
- [DailyPlanRepository.swift](file:///Users/liio/TooL_LiiO/LiiO_EatClean/LiiO_EatClean/Data/Repositories/DailyPlanRepository.swift)
- [MealRepository.swift](file:///Users/liio/TooL_LiiO/LiiO_EatClean/LiiO_EatClean/Data/Repositories/MealRepository.swift)

</canonical_refs>

<specifics>
## Specific Ideas
- `MealPlanLinkingService`: Service riêng để xử lý matching logic (name similarity, mealType, time, calories).
- `MealAdherenceCalculator`: Service tính điểm kỷ luật.
- `DailyNutritionRecord`: Struct tổng hợp dữ liệu cho UI Timeline.

</specifics>

<deferred>
## Deferred Ideas
- Setting "Tự động gắn món khi độ khớp > 95%": Để dành cho v1.6.
- HealthKit Integration: Out of scope.

</deferred>

---

*Phase: 26-planned-vs-actual-journal*
*Context gathered: 2026-05-12 via Discussion*
