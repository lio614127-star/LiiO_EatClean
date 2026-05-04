---
status: investigating
trigger: "MealDetailSheet does not show items immediately after logging, requires multiple opens/closes to refresh."
created: 2026-05-04
updated: 2026-05-04
symptoms:
  expected: "MealDetailSheet should show logged items immediately."
  actual: "Sheet shows 'Chưa có món ăn nào' initially. Items only appear after toggling the sheet multiple times."
  repro: "Log a meal using AI suggestion, then immediately tap the meal to open detail sheet."
---

## Current Focus
- **hypothesis**: "Race condition between background context save and UI context fetch, or MealDetailSheet is not correctly observing data changes."
- **next_action**: "Check MealRepository saveMeal implementation and MealDetailSheet data fetching logic."

## Evidence
- timestamp: 2026-05-04
  observation: "User reported items are missing in DetailSheet but eventually appear. This suggests persistence succeeded but UI sync failed."

## Eliminated Hypotheses
(None yet)

## Resolution
- root_cause: 
- fix: 
- verification: 
- files_changed: 
