---
status: resolved
trigger: "MealPlanCard initialization errors in WeeklyPlanView"
created: 2026-05-12
updated: 2026-05-12
resolution: "Updated WeeklyDayPlan to produce TimelineItem objects and refactored WeeklyPlanView to use the new MealPlanCard initializer."
---

# Debug Session: weekly-plan-view-sync

## Symptoms
- **Expected:** WeeklyPlanView renders meal cards for the generated week.
- **Actual:** Compilation errors due to mismatched MealPlanCard initializer (missing TimelineItem, pendingLinks, etc.).

## Resolution
- **Root Cause:** MealPlanCard was refactored in Phase 26 to support the Smart Daily Journal (TimelineItem pattern), but WeeklyPlanView was still using the old simple initializer.
- **Fix:** 
    1. Added `timelineItems` computed property to `WeeklyDayPlan` in `MealPlanViewModel.swift`.
    2. Updated `WeeklyDayDetailView` in `WeeklyPlanView.swift` to use the new `MealPlanCard` initializer with `TimelineItem` and empty handlers for journal actions.
- **Verification:** Logical fix applied to match the new component API.
