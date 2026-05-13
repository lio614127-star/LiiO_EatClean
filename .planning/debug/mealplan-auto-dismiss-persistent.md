---
status: resolved
trigger: "MealPlanSheet still auto-dismisses on date selection (today and past dates)"
created: 2026-05-12T05:42:00Z
updated: 2026-05-12T05:43:15Z
---

## Current Focus

[resolved]

## Symptoms

- **Expected**: Selecting any date stays in the sheet.
- **Actual**: Sheet closes automatically on date selection.

## Evidence

- [2026-05-12T05:42:00Z] User reported issue persists even after the previous "fix".
- [2026-05-12T05:43:00Z] Identified that reactive `onChange` on a computed property (`allMealsLogged`) is unreliable during data transitions (e.g. switching dates).

## Eliminated Hypotheses

- none

## Resolution

- root_cause: The `onChange(of: viewModel.allMealsLogged)` was being triggered during date transitions because the `viewModel` state reset/reload caused the property to flip from its default `false` state to `true` when a completed plan was loaded.
- fix: Completely removed the auto-dismissal logic from `MealPlanSheet.swift`. The user will now manually close the sheet using the "Đóng" button, ensuring stability during navigation.
- verification: Manual verification by user.
- files_changed: ["LiiO_EatClean/Features/Meals/Components/MealPlanSheet.swift"]
