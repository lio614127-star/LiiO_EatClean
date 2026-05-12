---
milestone: v1.5
status: planning
progress:
  phases_completed: 0
  phases_total: 7
---

# Project State

## Current Position

Phase: 25 - Date-Aware Planning Foundation
Plan: 25-PLAN.md
Status: Plan created
Last activity: Phase 25 plan generated
Resume file: .planning/phases/25-date-aware-planning-foundation/25-PLAN.md

## Active Context

### Memory (Decisions & Workarounds)
- `MealFoodModel.isEaten` is currently handled by `MealFoodStatusManager` (UserDefaults) rather than a persistent CoreData attribute. This needs to be synced carefully when we upgrade the UI to Planned vs Actual.
- `MealType` string matching must be strictly adhered to across UI ("Sáng", "Trưa", "Tối", "Ăn vặt").
- Calorie target updates reactively on weight logging via `UserRepository`.

### Known Blockers
- CoreData currently lacks `DailyPlan`, `WeeklyPlan`, `ChatSession`, and `ChatMessage` entities. A lightweight migration/addition is required for Phase 25 and Phase 29.
- Audio permissions must be requested before initializing the global Wake Phrase detector in Phase 30.

## Implementation Notes
- **Local-first focus:** All new entities (`DailyPlan`, `ChatMessage`) MUST be added to CoreData.
- **Do not overwrite plans:** We must check for existing plans via `startOfDay` normalized dates.
- **Rebalance boundary:** Rebalance logic must strictly filter out meals where `isEaten == true`.
