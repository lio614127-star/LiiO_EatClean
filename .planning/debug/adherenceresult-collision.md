---
status: resolved
trigger: "Redeclaration and ambiguity of AdherenceResult"
created: 2026-05-12
updated: 2026-05-12
resolution: "Renamed Phase 26 AdherenceResult to MealAdherenceResult to avoid collision with legacy Core/AI AdherenceResult."
---

# Debug Session: adherenceresult-collision

## Symptoms
- **Expected:** Project compiles successfully.
- **Actual:** Errors: `Invalid redeclaration of 'AdherenceResult'` and `'AdherenceResult' is ambiguous for type lookup`.
- **Location:** `AdherenceEngine.swift` (Core/AI) and `MealAdherenceCalculator.swift` (Features/Meals).

## Current Focus
- **Hypothesis:** Two different features (Phase 19 analytics and Phase 26 Journal) used the same name for their result models.
- **Next Action:** Rename the most recent one to `MealAdherenceResult`.

## Resolution
- **Root Cause:** Collision between the new `AdherenceResult` struct (introduced in Phase 26 for Journaling) and the legacy `AdherenceResult` in `Core/AI/AdherenceEngine.swift`.
- **Fix:** Renamed the new journaling-specific struct to `MealAdherenceResult` in `MealAdherenceCalculator.swift` and updated all its usages in `Features/Meals`.
- **Verification:** Ambiguity resolved. Code in `Core/AI` and `Features/Meals` now points to their respective unique types.
