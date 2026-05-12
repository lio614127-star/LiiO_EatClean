# Phase 21 Gap Fixes: Nutrition Reactivity & Ingredient Sorting

## Goals
- Ensure meal suggestions reactively update based on the selected meal type.
- Improve readability of recipe details by sorting main ingredients before seasonings.

## Tasks

### 1. [FIX] Meal Suggestion Reactivity
- **File:** `LiiO_EatClean/Features/Meals/MealSuggestionViewModel.swift`
- **Action:** Add `mealType` as a published property or parameter to `fetchSuggestions` and ensure it uses this type instead of calculating it from the current hour when provided.
- **Acceptance Criteria:** `fetchSuggestions` respects the passed meal category.

### 2. [FIX] AddMealView Integration
- **File:** `LiiO_EatClean/Features/Meals/AddMealView.swift`
- **Action:** Trigger `viewModel.fetchSuggestions` whenever the `selectedMealType` changes or the view appears.
- **Acceptance Criteria:** Suggestions update in real-time when switching meal categories in the picker.

### 3. [IMPROVE] AI Prompt Sorting Logic
- **File:** `LiiO_EatClean/Features/AI/AIService.swift`
- **Action:** Update prompts in `generateDayPlanStream`, `quickReaskForFood`, and `suggestMeals` to include: "Sắp xếp nguyên liệu: các nguyên liệu chính (thịt, cá, rau, gạo...) lên đầu, các gia vị (muối, đường, mắm, dầu ăn...) xuống cuối danh sách."
- **Acceptance Criteria:** AI-generated ingredient lists follow the new order.

### 4. [IMPROVE] Background Enrichment Sorting
- **File:** `LiiO_EatClean/Services/BackgroundEnrichmentManager.swift`
- **Action:** Update the enrichment prompt with the same sorting instruction.
- **Acceptance Criteria:** Background hydration also follows the logical sorting.

## Verification
- Manual verification of "Add Meal" suggestions for different categories.
- Verification of ingredient order in the "Meal Detail Sheet" for newly generated/enriched items.
