---
status: resolved
trigger: "Compilation errors in MealRepository and MetabolicRepository"
created: 2026-05-12
updated: 2026-05-12
resolution: "Fixed context.perform return ambiguity and used KVC/NSManagedObject to bypass missing entity types."
---

# Debug Session: repository-compilation-errors

## Symptoms
- **Expected:** Project compiles successfully.
- **Actual:** Errors in `MealRepository.swift` and `MetabolicRepository.swift` regarding `context.perform` return types and missing entity types (`MetabolicProfile`, `GoalHistory`).

## Current Focus
- **Hypothesis:** Compiler ambiguity with async `perform` and missing auto-generated CoreData classes.
- **Next Action:** Use explicit return types and KVC.

## Resolution
- **Root Cause:** 
    1. Swift compiler was picking the wrong overload for `context.perform` when returning values from inside the block, leading to `Unmanaged<AnyObject>?` errors.
    2. Xcode indexing issues or build configuration caused `MetabolicProfile` and `GoalHistory` entity classes to be missing from the scope.
- **Fix:** 
    1. Explicitly typed the return values inside `context.perform` closures.
    2. Switched to `NSManagedObject` and KVC (`value(forKey:)`) for `MetabolicProfile` and `GoalHistory` to bypass the missing type issues while maintaining functionality.
- **Verification:** Ambiguity and missing type errors are resolved.
