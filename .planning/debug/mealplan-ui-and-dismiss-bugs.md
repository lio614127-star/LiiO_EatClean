---
status: resolved
trigger: "MealPlanSheet UI spacing issues and auto-dismissal when selecting today"
created: 2026-05-12T05:34:00Z
updated: 2026-05-12T05:35:45Z
---

## Current Focus

[resolved]

## Symptoms

- **Issue 1 (UI)**: Large gaps between meal cards. Missing meals disappear. Card heights inconsistent.
- **Issue 2 (UX)**: Auto-dismissal and haptic feedback when selecting today's date in the strip.

## Evidence

- [2026-05-12T05:34:00Z] User provided screenshot showing 4 cards with large vertical spacing.
- [2026-05-12T05:34:00Z] User reported crash/dismissal behavior on date selection.
- [2026-05-12T05:35:10Z] Identified `minHeight: 180` and `if !foods.isEmpty` as causes for UI gaps/disappearance.
- [2026-05-12T05:35:23Z] Identified `onChange` logic without `oldValue` check as cause for auto-dismissal.

## Eliminated Hypotheses

- none

## Resolution

- root_cause: 
    1. `MealPlanSheet` had a fixed `minHeight: 180` on `ZStack` containers even when empty, and logic was hiding cards entirely if no food items were present.
    2. `onChange(of: viewModel.allMealsLogged)` was triggering whenever the property was true, even if it didn't just change from false (e.g. when loading an already-completed plan for today).
- fix: 
    1. Updated `MealPlanCard` to show "Không có món ăn cho bữa này" when empty.
    2. Removed `minHeight: 180` in `MealPlanSheet` to allow natural spacing.
    3. Refined `onChange` in `MealPlanSheet` to check `if newVal && !oldVal` to only dismiss on active completion.
- verification: UI now shows all 4 meal cards consistently. Sheet remains open when selecting a date with an already-completed plan.
- files_changed: ["LiiO_EatClean/Features/Meals/Components/MealPlanCard.swift", "LiiO_EatClean/Features/Meals/Components/MealPlanSheet.swift"]
