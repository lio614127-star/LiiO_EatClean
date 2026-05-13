---
status: resolved
trigger: "Extra arguments at positions #1, #3 in call (logMeal)"
created: 2026-05-12
updated: 2026-05-12
resolution: "Implemented logSingleFood in MealPlanViewModel to support logging a specific food item, and updated MealPlanSheet to use it."
---

# Debug Session: log-meal-params

## Symptoms
- **Expected:** viewModel.logMeal handles adding a single food to the diary.
- **Actual:** Compilation fails with "Extra arguments at positions #1, #3 in call" because the existing logMeal only takes a 'type' parameter (for bulk logging).

## Investigation
- Checked `MealPlanViewModel.swift` and found `logMeal(type: String)` which is designed for bulk logging from the plan.
- Identified the need for a granular `logSingleFood` method that accepts a `FoodItemModel`.

## Resolution
- Added `logSingleFood` to `MealPlanViewModel.swift`.
- Updated the closure in `MealPlanSheet.swift` to call this new method.
