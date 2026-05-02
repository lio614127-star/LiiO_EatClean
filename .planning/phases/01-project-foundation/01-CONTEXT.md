# Phase 1: Project Foundation & Data Layer - Context

**Gathered:** 2026-04-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Set up the Xcode project skeleton with SwiftUI (iOS 17+), CoreData data model with 7 entities, Repository pattern with 3 domain repositories, and 4-tab navigation structure. This phase delivers the foundation everything else builds on — no UI features, just the working skeleton.

</domain>

<decisions>
## Implementation Decisions

### CoreData Schema Design
- **D-01:** UUID for all entity IDs — prepares for CloudKit/multi-device sync, avoids migration later
- **D-02:** Macros (protein/carbs/fat) are **core feature**, not deferred — FoodItem stores calories + protein + carbs + fat as Double values
- **D-03:** MealFood junction table with **snapshot pattern** — caloriesSnapshot, proteinSnapshot, carbsSnapshot, fatSnapshot. Historical data stays accurate even if FoodItem is edited later
- **D-04:** All numeric values use Double (not Int) — supports decimal values like 23.5g protein
- **D-05:** Single User entity auto-created at first launch — prepares for multi-user/sync without overcomplicating v1
- **D-06:** FoodItem includes `isCustom: Bool` field — distinguishes user-created foods from system/API foods

### CoreData Schema (Final)
```
User: id(UUID), name(String), age(Int16), height(Double cm), weight(Double kg), 
      goalType(String), dailyCalorieTarget(Double), createdAt(Date), updatedAt(Date)

Meal: id(UUID), date(Date), mealType(String: breakfast/lunch/dinner/snack), 
      createdAt(Date) — relationship: user(User), mealFoods([MealFood])

FoodItem: id(UUID), name(String), calories(Double), protein(Double g), 
          carbs(Double g), fat(Double g), servingSize(Double?), 
          source(String?: local/api), apiId(String?), isCustom(Bool), 
          lastUsed(Date?)

MealFood: id(UUID), quantity(Double), caloriesSnapshot(Double), 
          proteinSnapshot(Double), carbsSnapshot(Double), fatSnapshot(Double)
          — relationships: meal(Meal), foodItem(FoodItem)

DailyLog: id(UUID), date(Date), totalCalories(Double), totalProtein(Double),
          totalCarbs(Double), totalFat(Double), waterIntake(Double ml), 
          weight(Double?) — relationship: user(User)

WeightEntry: id(UUID), date(Date), weight(Double kg) — relationship: user(User)

APIKey: id(UUID), provider(String: openai/gemini), key(String), 
        isActive(Bool), createdAt(Date)
```

### Repository Layer
- **D-07:** 3 domain repositories (not 7 per-entity): MealRepository (Meal + MealFood), FoodRepository (FoodItem), UserRepository (User + DailyLog + WeightEntry)
- **D-08:** Specific protocol per repo (MealRepositoryProtocol, FoodRepositoryProtocol, UserRepositoryProtocol) — no generic base
- **D-09:** `async throws` for all repo methods — native Swift, clean with async/await
- **D-10:** Background NSManagedObjectContext for operations, map NSManagedObject to structs, return to main thread

### Project Structure
- **D-11:** Hybrid folder structure — Feature-based for UI (`Features/Home/`, `Features/Meals/`), shared for data (`Data/Repositories/`, `Data/Models/`), utilities in `Core/`
```
LiiO_EatClean/
├── App/
│   └── LiiO_EatCleanApp.swift
├── Features/
│   ├── Home/
│   ├── Meals/
│   ├── Progress/
│   └── Profile/
├── Data/
│   ├── Models/
│   ├── Repositories/
│   ├── Protocols/
│   └── Persistence/
├── Core/
│   ├── Extensions/
│   └── Utils/
├── Services/
└── Resources/
```
- **D-12:** Tab icons: house.fill / fork.knife / chart.line.uptrend.xyaxis / person.fill
- **D-13:** Colors in Asset catalog (Assets.xcassets) — Primary #4CAF50, auto dark mode support
- **D-14:** NavigationStack (not NavigationView) — each tab has own NavigationStack, type-safe

### Agent's Discretion
- APIKey entity encryption approach (Keychain vs CoreData encrypted field)
- Exact dark mode color variants for Primary/Background/Text
- CoreData migration strategy setup (lightweight vs manual)
- In-memory CoreData store configuration for SwiftUI Previews

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Context
- `.planning/PROJECT.md` — Project decisions, constraints, core value
- `.planning/REQUIREMENTS.md` — FOUND-01 through FOUND-04 requirements for this phase
- `.planning/ROADMAP.md` — Phase 1 success criteria (5 items)

### Research
- `.planning/research/STACK.md` — Tech stack decisions, project structure template
- `.planning/research/ARCHITECTURE.md` — System architecture layers, data schema, build order
- `.planning/research/PITFALLS.md` — CoreData threading pitfalls, date/timezone gotchas

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None — greenfield project, no existing code

### Established Patterns
- None yet — this phase establishes the foundational patterns

### Integration Points
- CoreData stack will be injected via SwiftUI Environment
- Repository protocols will be the single integration point for all data access

</code_context>

<specifics>
## Specific Ideas

- Daily totals MUST be calculated from `sum(MealFood.xxxSnapshot)`, never directly from FoodItem — snapshot pattern is critical
- Tab labels in Vietnamese would be nice but English is fine for v1
- SF Pro font is the default on iOS — no custom font needed

</specifics>

<deferred>
## Deferred Ideas

- Macro tracking was elevated from Out of Scope to core — REQUIREMENTS.md needs updating
- Pie chart for macro breakdown — belongs in Phase 6 (Progress)
- AI-powered meal suggestions using macro data — belongs in Phase 7

None else — discussion stayed within phase scope

</deferred>

---

*Phase: 1-Project Foundation & Data Layer*
*Context gathered: 2026-04-29*
