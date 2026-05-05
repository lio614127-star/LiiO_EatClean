# Phase 14: AI Meal Planning Engine — Research

**Date:** 2026-05-05
**Phase:** 14 — AI Meal Planning Engine
**Requirements:** PLAN-01, PLAN-02

## Codebase Analysis

### Existing AI Infrastructure (MUST reuse)

| Asset | Location | Reuse Strategy |
|-------|----------|---------------|
| `ContextBuilder` | `Features/AI/ContextBuilder.swift` | Add `.mealPlan` case to `ContextStrategy` enum + new `buildMealPlanContext()` method |
| `AIService` | `Features/AI/AIService.swift` | Reuse `generateText()` for plan generation. Reuse `parseJSONResponse()` for flat array parsing |
| `AISuggestedFood` | `Features/AI/AIService.swift` (L28-83) | Reuse 100% — flat array items with `mealType` field |
| `InsightDetector` | `Services/InsightDetector.swift` | Call `detectInsights()` to inject patterns into `.mealPlan` prompt |
| `MemoryManager` | `Services/MemoryManager.swift` | Call `fetchMemory()` for likes/dislikes/healthConditions |
| `MealRepository` | `Data/Repositories/MealRepository.swift` | `saveMeal()` for logging, `fetchMeals(from:to:)` for history |
| `MealSuggestionViewModel` | `Features/Meals/MealSuggestionViewModel.swift` | Reference pattern for `logSuggestion()` — copy to `MealPlanViewModel` |
| `HapticManager` | `Core/Utils/HapticManager.swift` | `.success()` for per-meal log, `.interaction()` for completion |

### Vietnamese mealType Mapping (Critical)

App uses Vietnamese everywhere:
- `MealsView.swift` L35: `["Bữa sáng", "Bữa trưa", "Bữa tối", "Ăn vặt"]`
- `MealsViewModel.swift` L50: `validMealTypes`
- `HomeViewModel.swift` L127: `validMealTypes`
- `ContextBuilder.autoDetectMealType()` L370-378: Returns Vietnamese
- `MealSuggestionViewModel.suggestedMealType` L23-31: Returns Vietnamese

**Decision:** Use Vietnamese in AI prompt (`mealType: "Bữa sáng"`) for consistency. Add normalizer function to handle edge cases (AI sometimes returns "Sáng" or "breakfast").

### Calorie Validation Algorithm

From CONTEXT.md D-02: AI phân bổ + app validate ±5%.

**Implementation approach:**
```
totalPlanCalories = sum(all items calories)
if totalPlanCalories > targetCalories * 1.05:
  overageRatio = targetCalories / totalPlanCalories
  for each item: item.calories *= overageRatio (proportional trim)
  // Prefer trimming snack items first if overage > 10%
```

### Sheet Presentation Pattern

App uses `.sheet(item:)` pattern (iOS 17 fix from Phase 10 debugging):
- `MealsView.swift` L62-76: Uses `MealSheetItem` + `.sheet(item:)`
- For full-screen: Use `.fullScreenCover(isPresented:)` — simpler since plan has single state (shown/hidden)

### Existing Card Design Patterns

| Component | Style | Relevant for |
|-----------|-------|-------------|
| `StreakCardView` | `.secondarySystemGroupedBackground`, cornerRadius 16, shadow 0.05 | Meal plan card base style |
| `DailySummaryCardView` | Same bg, compact/expand with `.spring(response: 0.3)` | Card state transition animation |
| `SuggestionCard` | `.systemGroupedBackground`, cornerRadius 12, no shadow | Inner food item card style |
| `MacroMini` | Inline P/C/F display | Food item macro display |

## Technical Approach

### New Files Required

1. **`Features/Meals/MealPlanViewModel.swift`** [NEW]
   - `@Observable` class
   - Properties: `planItems: [AISuggestedFood]`, `isLoading`, `isGenerating`, `loggedMealTypes: Set<String>`, `weeklyPlan: [[AISuggestedFood]]?`
   - Methods: `generateDayPlan()`, `generateWeekPlan()`, `logMeal(type:)`, `logAllMeals()`, `validateCalories()`
   - Uses: `ContextBuilder(.mealPlan)`, `AIService.generateText()`, `MealRepository.saveMeal()`

2. **`Features/Meals/Components/MealPlanSheet.swift`** [NEW]
   - Full-screen sheet with ScrollView of MealPlanCards
   - Header: "Kế hoạch hôm nay" + total kcal
   - 4 `MealPlanCard` views (one per meal type)
   - Bottom button: "📋 Áp dụng toàn bộ kế hoạch"
   - Weekly toggle: "Lên kế hoạch tuần" button

3. **`Features/Meals/Components/MealPlanCard.swift`** [NEW]
   - Single meal card (Sáng/Trưa/Tối/Vặt)
   - Shows: icon + meal type + food list + total kcal
   - CTA: "Log bữa này" button
   - Logged state: fade + ✅ icon + disabled CTA
   - Reuses `MacroMini` for P/C/F display

4. **`Features/Meals/Components/WeeklyPlanView.swift`** [NEW]
   - List of 7 compact rows (T2-CN)
   - Each row: day name + total kcal + 2-3 highlight foods
   - Tap → opens day detail (reuses MealPlanSheet)

### Modified Files

5. **`Features/AI/ContextBuilder.swift`** [MODIFY]
   - Add `.mealPlan` to `ContextStrategy` enum
   - Add `buildMealPlanContext()` method with adaptive injection

6. **`Features/Meals/MealsView.swift`** [MODIFY]
   - Add "✨ Lên kế hoạch" button
   - Add `.fullScreenCover` for MealPlanSheet

## Prompt Engineering

### Daily Plan Prompt Structure

```
Bạn là chuyên gia dinh dưỡng chuyên về ẩm thực Việt Nam.
Lên thực đơn 1 ngày (4 bữa) với tổng khoảng {targetCalories} kcal.

[Phân bổ gợi ý]
- Bữa sáng: ~25% ({breakfastCal} kcal)
- Bữa trưa: ~35% ({lunchCal} kcal)
- Bữa tối: ~30% ({dinnerCal} kcal)
- Ăn vặt: ~10% ({snackCal} kcal)

[⛔ CẤM — tránh] {avoidFoods}
[Sở thích] {likes/dislikes}
[Lịch sử gần đây — tránh lặp] {recentFoods} (conditional)
[Insight] {insights} (conditional)

Trả JSON: {"action":"meal_plan","items":[...]}
Mỗi item: {name, calories, protein, carbs, fat, servingSize:1.0, mealType:"Bữa sáng|Bữa trưa|Bữa tối|Ăn vặt"}
```

### Weekly Plan Approach
- Generate 7 daily plans in 1 API call (cost-efficient)
- Wrap JSON: `{"action":"weekly_plan","days":[{"day":"T2","items":[...]}, ...]}`
- If response too large, fall back to 7 individual calls

## Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| AI returns wrong mealType strings | Normalizer function: map variations to canonical 4 types |
| Token overflow on weekly plan | Limit to 2 items/meal for weekly (compact mode) |
| Calorie overshoot | App-side validation + proportional trim |
| Duplicate meal log | Disable CTA after log + track `loggedMealTypes` set |
| Slow AI response | Loading state + skeleton cards + timeout (30s) |

## Validation Architecture

### Automated Verification
- Build succeeds with no errors
- `MealPlanViewModel` compiles with `@Observable`
- `ContextBuilder.mealPlan` case exists in enum
- `MealPlanSheet` renders without runtime crashes
- "Log bữa này" saves to CoreData successfully
- Calorie validation trims to ±5% of target

### UAT Criteria
1. Generate day plan → 4 bữa cards hiển thị
2. Total kcal ≤ target ±5%
3. Log từng bữa → card chuyển ✅
4. Log tất cả → confirm dialog → auto-dismiss
5. Memory inject → plan respects avoidFoods
6. History inject (≥3 days) → plan avoids recent foods
7. Generate week plan → 7 rows hiển thị
8. Tap weekly row → detail view shows
9. Empty state / error handling works
