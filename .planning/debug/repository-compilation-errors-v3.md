---
status: resolved
trigger: "Compilation errors in WeeklyPlanView and Repositories (Part 3)"
created: 2026-05-12
updated: 2026-05-12
resolution: "Fixed ForEach inference error in WeeklyPlanView and refactored all repositories to use NSManagedObject/KVC for total stability."
---

# Debug Session: repository-compilation-errors-v3

## Symptoms
- **Expected:** Project compiles successfully.
- **Actual:** 
    1. `Generic parameter 'C' could not be inferred` in `WeeklyPlanView.swift`.
    2. Persistent indexing errors causing missing entity members.

## Resolution
- **Root Cause:** 
    1. SwiftUI's `ForEach` was confused by nested closure inference in `WeeklyDayDetailView`.
    2. Xcode's inability to see auto-generated CoreData classes for new/updated entities.
- **Fix:** 
    1. Added explicit type `(mealType: String)` and `[AISuggestedFood]` annotation in `WeeklyPlanView`.
    2. Refactored ALL repositories (`Meal`, `DailyPlan`, `Food`, `User`, `AIMemory`) to use `NSManagedObject` and KVC. This bypasses class generation issues entirely.
- **Verification:** `swiftc` checks pass for the modified files.
