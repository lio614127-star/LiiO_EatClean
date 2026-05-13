---
status: resolved
trigger: "Compilation errors in MealRepository and MetabolicRepository (Part 2)"
created: 2026-05-12
updated: 2026-05-12
resolution: "Removed accidental image literal and fully adopted KVC pattern in Repositories to handle missing entity types."
---

# Debug Session: repository-compilation-errors-v2

## Symptoms
- **Expected:** Project compiles successfully.
- **Actual:** 
    1. `Value of type 'Meal' has no member 'mealFoods'` in `MealRepository.swift`.
    2. `Trailing closure passed to parameter of type 'Selector'` in `context.perform`.
    3. Accidental image literal found in code.

## Current Focus
- **Hypothesis:** An accidental paste of an image literal broke the compiler's ability to index the file, and missing CoreData classes are causing type errors.
- **Next Action:** Clean up the file and use KVC consistently.

## Resolution
- **Root Cause:** 
    1. An accidental paste of `#imageLiteral(...)` on line 53 of `MealRepository.swift` broke the file.
    2. Missing auto-generated CoreData classes for some entities (MetabolicProfile, GoalHistory) led to scope errors.
- **Fix:** 
    1. Removed the image literal.
    2. Fully adopted `NSManagedObject` and KVC (`value(forKey:)`) in both `MealRepository` and `MetabolicRepository` to bypass indexing/generation issues.
- **Verification:** Fixed and verified.
