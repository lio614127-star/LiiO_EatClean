---
wave: 1
depends_on: []
files_modified: ["LiiO_EatClean.xcdatamodeld/LiiO_EatClean.xcdatamodel/contents", "LiiO_EatClean/App/LiiO_EatCleanApp.swift", "LiiO_EatClean/Data/Persistence/Persistence.swift", "LiiO_EatClean/Data/Models/*.swift", "LiiO_EatClean/Data/Protocols/*.swift", "LiiO_EatClean/Data/Repositories/*.swift", "LiiO_EatClean/Features/**/*.swift"]
autonomous: true
---

# Phase 1: Project Foundation & Data Layer

## Objective
Set up the Xcode project directory skeleton, the CoreData schema with snapshot pattern, the domain model mapping, 3 repository protocols and implementations, and the 4-tab SwiftUI navigation structure.

## Requirements Covered
- **FOUND-01**: Xcode project with SwiftUI, iOS 17+ target, CoreData stack
- **FOUND-02**: CoreData schema (User, Meal, FoodItem, MealFood, DailyLog, WeightEntry, APIKey)
- **FOUND-03**: Repository pattern (MealRepository, FoodRepository, UserRepository)
- **FOUND-04**: App navigation structure with TabView (Home/Meals/Progress/Profile)

---

## 1. Directory Skeleton & CoreData Schema
<task>
<read_first>
- `.planning/phases/01-project-foundation/01-CONTEXT.md` (to see the exact entity relationships and properties)
</read_first>
<action>
Create the directory structure inside `LiiO_EatClean/`:
- `App/`
- `Features/Home/`, `Features/Meals/`, `Features/Progress/`, `Features/Profile/`
- `Data/Models/`, `Data/Repositories/`, `Data/Protocols/`, `Data/Persistence/`
- `Core/Extensions/`, `Core/Utils/`
- `Resources/`

Create `LiiO_EatClean/LiiO_EatClean.xcdatamodeld/LiiO_EatClean.xcdatamodel/contents` with the raw CoreData XML defining the 7 entities and their relationships exactly as specified in the context (UUIDs, Double types for all numeric metrics, Snapshot pattern in MealFood).

Create `LiiO_EatClean/Data/Persistence/Persistence.swift` containing a `PersistenceController` singleton configured for the `LiiO_EatClean` container.
</action>
<acceptance_criteria>
- `LiiO_EatClean/Data/Persistence/Persistence.swift` contains `struct PersistenceController`
- `LiiO_EatClean.xcdatamodeld/LiiO_EatClean.xcdatamodel/contents` exists and contains `<entity name="MealFood">` and `<attribute name="caloriesSnapshot" attributeType="Double"/>`
</acceptance_criteria>
</task>

## 2. Domain Models Mapping
<task>
<read_first>
- `.planning/phases/01-project-foundation/01-CONTEXT.md` (for the struct layouts)
</read_first>
<action>
Create plain Swift structs in `LiiO_EatClean/Data/Models/` to decouple the UI from CoreData:
1. `UserModel.swift`: `id`, `name`, `age`, `height`, `weight`, `goalType`, `dailyCalorieTarget`
2. `MealModel.swift`: `id`, `date`, `mealType`, `mealFoods` (array)
3. `FoodItemModel.swift`: `id`, `name`, `calories`, `protein`, `carbs`, `fat`, `servingSize`, `source`, `apiId`, `isCustom`, `lastUsed`
4. `MealFoodModel.swift`: `id`, `quantity`, `caloriesSnapshot`, `proteinSnapshot`, `carbsSnapshot`, `fatSnapshot`, `foodItem`
5. `DailyLogModel.swift`
6. `WeightEntryModel.swift`
7. `APIKeyModel.swift`

Ensure all numeric types are `Double` and all IDs are `UUID`.
</action>
<acceptance_criteria>
- `LiiO_EatClean/Data/Models/MealFoodModel.swift` contains `let proteinSnapshot: Double`
- `LiiO_EatClean/Data/Models/FoodItemModel.swift` contains `let isCustom: Bool`
</acceptance_criteria>
</task>

## 3. Repository Layer
<task>
<read_first>
- `.planning/phases/01-project-foundation/01-CONTEXT.md` (for the 3 domain repos and specific protocols)
</read_first>
<action>
Create the protocols in `LiiO_EatClean/Data/Protocols/`:
1. `MealRepositoryProtocol.swift`: fetch, add, update, delete methods using `async throws`.
2. `FoodRepositoryProtocol.swift`: fetch, add, update methods.
3. `UserRepositoryProtocol.swift`: fetch, update, and methods for DailyLog/WeightEntry.

Create the implementations in `LiiO_EatClean/Data/Repositories/`:
1. `MealRepository.swift`
2. `FoodRepository.swift`
3. `UserRepository.swift`

Implementations must initialize with an `NSManagedObjectContext` (usually the background context via `PersistenceController.shared.container.newBackgroundContext()`).
They must use `context.perform { ... }` internally and return the mapped plain Swift `Model` structs.
</action>
<acceptance_criteria>
- `LiiO_EatClean/Data/Protocols/MealRepositoryProtocol.swift` contains `func fetchMeals(by date: Date) async throws -> [MealModel]`
- `LiiO_EatClean/Data/Repositories/UserRepository.swift` implements the protocol and uses `perform` or `performAndWait` context blocks.
</acceptance_criteria>
</task>

## 4. Tab Navigation Skeleton
<task>
<read_first>
- `.planning/phases/01-project-foundation/01-UI-SPEC.md` (for tab icons)
</read_first>
<action>
Create the placeholder views in `LiiO_EatClean/Features/`:
1. `Home/HomeView.swift`
2. `Meals/MealsView.swift`
3. `Progress/ProgressView.swift`
4. `Profile/ProfileView.swift`

Create `LiiO_EatClean/App/ContentView.swift` containing a `TabView`:
- Home (house.fill)
- Meals (fork.knife)
- Progress (chart.line.uptrend.xyaxis)
- Profile (person.fill)
Ensure each tab uses a `NavigationStack`.

Create `LiiO_EatClean/App/LiiO_EatCleanApp.swift` with `@main`, injecting the `PersistenceController.shared.container.viewContext` into the environment.
</action>
<acceptance_criteria>
- `ContentView.swift` contains `TabView` and `NavigationStack` for each tab.
- `ContentView.swift` uses `systemImage: "fork.knife"` for the Meals tab.
</acceptance_criteria>
</task>

---
## Verification Criteria
- Run a basic syntax check on all `.swift` files (if swift is installed on Windows, else grep checks).
- Grep to ensure `NSManagedObject` is NOT leaked into the public signatures of `Protocols`.
- Ensure all 4 tab icons match the UI-SPEC exactly.
