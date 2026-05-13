---
status: resolved
trigger: "Cannot find 'FoodDetailView' in scope"
created: 2026-05-12
updated: 2026-05-12
resolution: "Renamed the non-existent FoodDetailView to the correct MealDetailSheet component."
---

# Debug Session: food-detail-view-missing

## Symptoms
- **Expected:** App compiles after adding detail view logic.
- **Actual:** Compilation fails with `Cannot find 'FoodDetailView' in scope`.

## Investigation
- Searched for `FoodDetailView` and found no files.
- Searched for `Detail` in the meals feature and found `MealDetailSheet.swift`.
- Verified `MealDetailSheet` takes a `FoodItemModel` as input.

## Resolution
- Updated `MealPlanCard.swift` to use `MealDetailSheet` instead of `FoodDetailView`.
