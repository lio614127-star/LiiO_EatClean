---
status: resolved
trigger: "Extra arguments at positions #1, #2 in call (FoodSearchView)"
created: 2026-05-12
updated: 2026-05-12
resolution: "Corrected FoodSearchView initialization by providing the required onFoodSelected closure and removing incorrect arguments. Added logMeal logic inside the closure."
---

# Debug Session: food-search-view-params

## Symptoms
- **Expected:** FoodSearchView initializes correctly in MealPlanSheet.
- **Actual:** Compilation fails with "Extra arguments at positions #1, #2 in call" and "Missing argument for parameter 'onFoodSelected'".

## Investigation
- Checked `FoodSearchView.swift` and confirmed it only takes an `onFoodSelected` closure.
- The previous implementation incorrectly tried to pass `mealType` and `targetDate` directly to the view.

## Resolution
- Updated `MealPlanSheet.swift` to use the correct `FoodSearchView` initializer.
- Wrapped it in a `NavigationStack` for a better UX.
- Implemented the save logic (`viewModel.logMeal`) inside the selection closure.
