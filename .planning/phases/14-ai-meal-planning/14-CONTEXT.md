# Phase 14: AI Meal Planning Engine — Context

**Gathered:** 2026-05-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Build an AI Meal Planning Engine — cho phép AI sinh thực đơn ăn uống theo ngày (core) với option preview tuần. AI tạo kế hoạch 4 bữa cân bằng dinh dưỡng dựa trên memory (sở thích, bệnh lý, thói quen), calo mục tiêu, và insights. User review kế hoạch trong full-screen sheet và log nhanh từng bữa hoặc toàn bộ.

**Không phải:** meal planner phức tạp. **Đúng là:** daily decision assistant + optional weekly planning.

</domain>

<decisions>
## Implementation Decisions

### Phạm vi kế hoạch (PLAN-01)

- **D-01:** Kế hoạch ngày = core, kế hoạch tuần = optional. Default = đơn giản, Advanced = khi user yêu cầu.
  - **Ngày:** AI sinh 4 bữa (Sáng/Trưa/Tối/Vặt) cho hôm nay hoặc ngày mai.
  - **Tuần:** Nút "Lên kế hoạch tuần" sinh 7 ngày. Hiển thị overview → tap vào ngày → xem chi tiết (reuse day plan UI).
- **D-02:** AI phân bổ calorie budget + app validate.
  - 1 API call → AI tự chia tỷ lệ.
  - App kiểm tra tổng ≤ target hoặc ±5%.
  - Nếu vượt → trim snack trước → sau đó trim dinner.
  - Nguyên tắc: AI đề xuất, App kiểm soát.

### UI & Layout thực đơn (PLAN-01, PLAN-02)

- **D-03:** Full-screen sheet riêng cho meal plan. Tách biệt planning flow vs tracking flow.
  - Entry point: Nút "✨ Lên kế hoạch" trong Meals tab.
  - Dùng `.fullScreenCover` presentation.
  - Planning ≠ Tracking → không nhét vào Meals tab list.
- **D-04:** Layout bên trong sheet = Cards xếp dọc (ScrollView).
  - Mỗi bữa = 1 card (icon + tên bữa + danh sách món + tổng kcal).
  - Max 2-3 món / card.
  - Mỗi card có CTA "Log bữa này".
  - Reuse card style pattern từ StreakCardView/DailySummaryCardView.
- **D-05:** Weekly overview = List compact 7 dòng.
  - Mỗi dòng: `T2 — 1850 kcal — Phở bò • Cơm gà • Salad`.
  - Tap vào dòng → mở full day plan (reuse sheet cards layout).
  - Overview = nhanh + đủ info. Detail = màn riêng.

### Hành động "Áp dụng" (PLAN-02)

- **D-06:** Log từng bữa + nút "📋 Áp dụng toàn bộ kế hoạch".
  - Mỗi card: nút "Log bữa này".
  - Cuối sheet: nút "Áp dụng toàn bộ kế hoạch" → confirmation dialog trước khi log.
  - Nhanh khi cần, linh hoạt khi muốn.
- **D-07:** Source tracking — logged meals from plan marked `source = "meal_plan"` cho AI learning.
- **D-08:** Card đổi trạng thái + auto-dismiss khi log hết.
  - Log từng bữa → card chuyển visual (màu nhạt + icon ✅ + disable CTA). User vẫn ở sheet.
  - Log hết 4 bữa (hoặc "Áp dụng tất cả") → auto-dismiss sheet (~0.8-1.2s) + celebration feedback.
  - Animation: fade + scale nhẹ khi card chuyển trạng thái.
  - Haptic: `.success` khi log từng bữa, mạnh hơn khi hoàn thành toàn bộ.
  - Nút "Áp dụng tất cả" disable khi đã log hết — tránh duplicate log.

### AI Generation & Prompt Strategy

- **D-09:** ContextBuilder thêm strategy mới `.mealPlan`.
  - **Adaptive context:** Base (kcal + memory) luôn inject. Conditional inject khi có data:
    - History (≥3 ngày data) → inject 3-5 items gần nhất (tránh lặp món).
    - Insights (khi InsightDetector phát hiện pattern) → inject 1-2 insights (vd: thiếu protein → ưu tiên).
  - Nguyên tắc: Chỉ gửi những gì cần thiết, không gửi tất cả những gì có.
- **D-10:** AI output format = flat array + mealType field.
  - Reuse 100% `AISuggestedFood` model hiện tại.
  - Action = `"meal_plan"` (phân biệt với `"suggest_meal"`).
  - App group items theo `mealType` để render cards.
  - Parse bằng `parseJSONResponse()` / `parseChatResponse()` đã có.
- **D-11:** mealType trong AI output cần mapping layer.
  - App hiện dùng Vietnamese (`"Bữa sáng"`, `"Bữa trưa"`, `"Bữa tối"`, `"Ăn vặt"`) everywhere.
  - Learning từ STATE.md: "AI mealType mapping must strictly match UI categories".
  - Planner quyết định: dùng Vietnamese matching trong prompt hoặc English enum + mapping.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Context
- `.planning/REQUIREMENTS.md` — PLAN-01, PLAN-02 requirements
- `.planning/ROADMAP.md` — Phase 14 scope
- `.planning/PROJECT.md` — Core value and constraints

### Prior Phase Context (AI System)
- `.planning/phases/10-ai-meals-tab/10-CONTEXT.md` — Memory architecture, ContextBuilder strategy pattern, Actionable AI, Learning System decisions
- `.planning/phases/13-proactive-ai/13-CONTEXT.md` — Daily Summary card pattern, InsightDetector integration, ContextBuilder `.dailySummary` strategy

### AI Infrastructure
- `LiiO_EatClean/Features/AI/ContextBuilder.swift` — Strategy pattern (5 strategies: chat, mealSuggestion, healthAdvice, progressAnalysis, dailySummary). Add `.mealPlan` strategy.
- `LiiO_EatClean/Features/AI/AIService.swift` — `AISuggestedFood` model (reuse for plan items), `generateText()`, `suggestMeals()`, `parseJSONResponse()`, `parseChatResponse()`
- `LiiO_EatClean/Services/InsightDetector.swift` — 4 pattern detection (lowProtein, skippedMeal, calorieOverrun, lowWater). Inject results into `.mealPlan` prompt.
- `LiiO_EatClean/Services/MemoryManager.swift` — Memory persistence (UserDefaults)
- `LiiO_EatClean/Data/Models/UserProfileMemory.swift` — Memory data model (likes, dislikes, healthConditions, avoidFoods)

### Meals Tab (Integration Points)
- `LiiO_EatClean/Features/Meals/MealsView.swift` — Entry point for "Lên kế hoạch" button. Has existing `MealSheetItem` pattern for `.sheet(item:)`.
- `LiiO_EatClean/Features/Meals/MealsViewModel.swift` — `remainingCalories`, `loadTodayMeals()` — calorie budget source
- `LiiO_EatClean/Features/Meals/Components/AISuggestionSectionView.swift` — Existing AI suggestion pattern, "Log Ngay" button reference
- `LiiO_EatClean/Data/Repositories/MealRepository.swift` — `saveMeal()`, `fetchMeals(from:to:)` — data persistence for logged plans

### UI Pattern References
- `LiiO_EatClean/Features/Home/Components/StreakCardView.swift` — Card style reference (bo góc, shadow)
- `LiiO_EatClean/Features/Home/Components/DailySummaryCardView.swift` — Expandable card pattern, compact ↔ expand animation
- `LiiO_EatClean/Core/Utils/HapticManager.swift` — `.success()`, `.interaction()` feedback patterns

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets (MUST reuse, not duplicate)
- `AISuggestedFood` — Reuse for plan items. Add `action: "meal_plan"` parsing.
- `ContextBuilder` — Add `.mealPlan` strategy. Adaptive: base (kcal + memory) + conditional (history, insights).
- `AIService.generateText()` — Raw text generation for meal plan prompt.
- `InsightDetector.detectInsights()` — Feed results into `.mealPlan` context for smart planning.
- `MealRepository.saveMeal()` — Save planned meals to CoreData.
- `HapticManager` — `.success` for per-meal log, stronger for full plan completion.
- `MealSheetItem` — Pattern for `.sheet(item:)` presentation.

### Established Patterns
- `@Observable` macro for ViewModels (not ObservableObject)
- Repository pattern — never access CoreData directly from ViewModels
- `.sheet(item:)` for sheet presentation (fixes iOS 17 state capture bug)
- `MealFoodStatusManager` — Ephemeral state (UserDefaults) for isEaten tracking
- AI data normalization — servingSize 1.0 + quantity multiplier

### Integration Points
- `MealsView` — Add "✨ Lên kế hoạch" button → open MealPlanSheet
- `ContextBuilder` — Add `.mealPlan` case to enum + strategy method
- `AIService` — Reuse `parseJSONResponse()` for flat array parsing; may need `parseMealPlanResponse()` for `"meal_plan"` action wrapper
- `MealRepository.saveMeal()` — Bulk save for "Áp dụng tất cả" (loop 4 bữa)

</code_context>

<specifics>
## Specific Ideas

- **UX Flow chính:** Meals tab → "✨ Lên kế hoạch" → Full-screen sheet → 4 meal cards → Log từng bữa / Áp dụng tất cả
- **Card visual khi logged:** Màu nhạt + icon ✅ + disable CTA — progress feedback loop
- **Weekly overview structure:** `T2 — 1850 kcal — Phở bò • Cơm gà • Salad` — scan nhanh, tap chi tiết
- **Validate rule:** ≤ target ±5%, trim snack → dinner nếu vượt
- **Prompt constraint:** Max 3-5 history items, 1-2 insights. Không gửi tất cả data.

</specifics>

<deferred>
## Deferred Ideas

- Weekly plan persistence (lưu kế hoạch tuần để xem lại) — v2 nếu user cần
- Meal plan sharing (chia sẻ thực đơn) — out of scope
- Meal plan editing (chỉnh sửa từng món trong plan trước khi log) — v2 nice-to-have
- Meal plan templates (save plans làm template tái sử dụng) — phase riêng
- AI regenerate specific meal (chỉ gen lại 1 bữa thay vì cả ngày) — v2 enhancement
- Grocery list from meal plan (danh sách đi chợ) — feature mới hoàn toàn

</deferred>

---

*Phase: 14-ai-meal-planning*
*Context gathered: 2026-05-05*
