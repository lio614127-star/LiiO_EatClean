---
status: investigating
trigger: "Meal logging (Log Ngay) is inconsistent/flaky."
created: 2026-05-04
updated: 2026-05-04
symptoms:
  expected: "Clicking 'Log Ngay' should always persist the meal and update the UI."
  actual: "Sometimes it works, sometimes it doesn't (flaky behavior)."
  repro: "Use AI suggestions and try to log multiple items or log items in quick succession."
---

## Current Focus
- **hypothesis**: "Potential ID collision if AI returns multiple items with same name, or CoreData unique constraint violation, or race condition in background context saving."
- **next_action**: "Check MealRepository.saveMeal logic for potential failures and add detailed logging."

## Evidence
- timestamp: 2026-05-04
  observation: "User reported inconsistent logging. Persistence might be failing silently or the UI refresh might be missing the update."

## Eliminated Hypotheses
(None yet)

## Resolution
- root_cause: 
- fix: 
- verification: 
- files_changed: 
