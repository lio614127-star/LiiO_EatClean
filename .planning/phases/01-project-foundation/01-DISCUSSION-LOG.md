# Phase 1: Project Foundation & Data Layer — Discussion Log

**Date:** 2026-04-29
**Duration:** ~10 minutes
**Areas discussed:** 3 (all selected)

## Area 1: CoreData Schema Design

### Q1: ID strategy
- **Options:** UUID (recommended) / Auto-increment Int / Agent decides
- **Selected:** UUID
- **Rationale:** Multi-device sync (CloudKit) ready, avoids migration, Apple-recommended

### Q2: FoodItem data fields
- **Options:** Calories only / Calories + macros / Agent decides
- **Selected:** Calories + macros (protein/carbs/fat)
- **Rationale:** User elevated macros from "dự phòng" to **core feature**. Use Double for all numeric values. This unlocks pie charts, smart AI suggestions, daily macro breakdown
- **⚠️ Scope change:** Macro tracking moved from Out of Scope to core feature

### Q3: CoreData relationships
- **Options:** MealFood junction (recommended) / Direct relationship / Agent decides
- **Selected:** MealFood junction table
- **User addition:** **Snapshot pattern** — MealFood stores caloriesSnapshot, proteinSnapshot, carbsSnapshot, fatSnapshot. Prevents historical data corruption when FoodItem is edited
- **User addition:** Calculate daily totals from `sum(MealFood.xxxSnapshot)`, never from FoodItem directly

### Q4: User entity strategy
- **Options:** Single User entity (recommended) / UserDefaults / Agent decides
- **Selected:** Single User entity, auto-created at first launch
- **Rationale:** Prepares for sync, maintains clean architecture

### Extra decisions from user:
- FoodItem adds `isCustom: Bool` field
- All numeric fields use Double (not Int)

## Area 2: Repository Layer Scope

### Q1: Repository granularity
- **Options:** 1 per domain (recommended) / 1 per entity / Agent decides
- **Selected:** 1 per domain — 3 repos total
- **Repos:** MealRepository (Meal+MealFood), FoodRepository (FoodItem), UserRepository (User+DailyLog+WeightEntry)

### Q2: Protocol design
- **Options:** Specific protocols (recommended) / Generic base / Agent decides
- **Selected:** Specific protocols per repo

### Q3: Error handling
- **Options:** throws (recommended) / Result type / Agent decides
- **Selected:** async throws

### Q4: Async strategy
- **Options:** Background context + async/await (recommended) / @MainActor all / Agent decides
- **Selected:** Background context + async/await, return structs to main thread

## Area 3: Project Structure & Tab Skeleton

### Q1: Folder organization
- **Options:** Feature-based / Layer-based / Hybrid
- **Selected:** Hybrid — Features/ for UI, Data/ for shared data layer, Core/ for utilities

### Q2: Tab bar icons
- **Options:** Option A (house/fork.knife/chart/person) / Option B (house/leaf/chart.bar/gear) / Agent decides
- **Selected:** Option A — house.fill, fork.knife, chart.line.uptrend.xyaxis, person.fill

### Q3: Color theme implementation
- **Options:** Asset catalog (recommended) / Extension Color / Agent decides
- **Selected:** Asset catalog — Primary #4CAF50 in Assets.xcassets, auto dark mode

### Q4: Navigation approach
- **Options:** NavigationStack (recommended) / NavigationView / Agent decides
- **Selected:** NavigationStack — each tab has own stack, type-safe

## Deferred Ideas
- Macro pie chart → Phase 6 (Progress)
- AI suggestions using macro data → Phase 7
