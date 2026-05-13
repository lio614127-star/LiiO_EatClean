---
status: complete
phase: 26-planned-vs-actual-journal
source: [26-PLAN.md]
started: 2026-05-12T16:23:00Z
updated: 2026-05-13T00:46:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Unified Timeline Display
expected: |
  Navigate to the Planning tab (MealPlanSheet). 
  Verify that the UI displays a unified timeline containing:
  - Planned Meals (with tick/skip buttons)
  - Actual Logs (meals logged from Home/Meals)
  - Items should be grouped by meal type (Sáng, Trưa, Tối, Ăn vặt).
result: pass

### 2. Smart Linking Suggestion
expected: |
  Log a meal from the Home tab that matches a planned meal's name or type.
  Open the Planning tab.
  Verify that an inline chip/suggestion "Gắn vào kế hoạch?" appears under the unplanned meal.
result: pass

### 3. Log from Plan
expected: |
  In the Planning tab, tap "Đã ăn" on a planned item.
  Verify that:
  - A MealLog is created in CoreData.
  - The item status updates to "Đã ăn" with a green checkmark.
  - The calories are added to the daily total in Home tab.
result: pass

### 4. Adherence Score Calculation
expected: |
  Log several meals (some planned, some unplanned).
  Verify that the Daily Summary Card displays:
  - Comparison of Planned vs Actual calories.
  - An Adherence Score (0-100%) based on accuracy.
  - A status label (e.g., "Tuyệt vời", "Cần điều chỉnh").
result: pass

## Summary

total: 4
passed: 4
issues: 0
pending: 0
skipped: 0

## Gaps

[none yet]
