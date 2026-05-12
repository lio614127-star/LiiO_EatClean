---
wave: 1
depends_on: []
files_modified:
  - "LiiO_EatClean/LiiO_EatClean.xcdatamodeld"
  - "LiiO_EatClean/Models/CoreData/DailyPlan+CoreDataClass.swift"
  - "LiiO_EatClean/Models/CoreData/DailyPlan+CoreDataProperties.swift"
  - "LiiO_EatClean/Models/CoreData/PlannedMeal+CoreDataClass.swift"
  - "LiiO_EatClean/Models/CoreData/PlannedMeal+CoreDataProperties.swift"
  - "LiiO_EatClean/Models/CoreData/PlannedFoodItem+CoreDataClass.swift"
  - "LiiO_EatClean/Models/CoreData/PlannedFoodItem+CoreDataProperties.swift"
  - "LiiO_EatClean/Repositories/DailyPlanRepository.swift"
  - "LiiO_EatClean/ViewModels/MealPlanViewModel.swift"
  - "LiiO_EatClean/Views/MealPlan/HorizontalDateStrip.swift"
  - "LiiO_EatClean/Views/MealPlan/MealPlanView.swift"
autonomous: true
---

# Phase 25 Plan: Date-Aware Planning Foundation

## Verification Criteria
- CoreData successfully persists `DailyPlan`, `PlannedMeal`, `PlannedFoodItem` entities.
- Selecting a different date in the UI fetches the `DailyPlan` for that specific date.
- Returning from background handles draft state (status == "draft") by prompting the user.

## Must Haves
- `DailyPlan` is strictly mapped to `startOfDay` (UTC normalized).
- Dates fetched correctly using `Calendar.current.startOfDay`.
- Avoid overwriting existing plans for past dates.

## Tasks

<task id="25-01-01">
<title>CoreData Schema Migration</title>
<read_first>
- LiiO_EatClean/Models/CoreData/CoreDataManager.swift
</read_first>
<action>
1. Open Xcode and add a new model version to `LiiO_EatClean.xcdatamodeld` (e.g. `LiiO_EatClean 5`).
2. Add `DailyPlan` entity: `id` (UUID), `date` (Date), `status` (String), `targetCalories` (Double), `targetProtein` (Double), `targetCarbs` (Double), `targetFat` (Double). 
3. Add `PlannedMeal` entity: `id` (UUID), `type` (String), `convertedMealId` (UUID, optional). 
4. Add `PlannedFoodItem` entity: `id` (UUID), `name` (String), `calories` (Double), `protein` (Double), `carbs` (Double), `fat` (Double), `servingSize` (Double). 
5. Create Relationships:
   - `DailyPlan` -> To Many `plannedMeals` (Destination: `PlannedMeal`, Inverse: `dailyPlan`)
   - `PlannedMeal` -> To Many `foodItems` (Destination: `PlannedFoodItem`, Inverse: `plannedMeal`)
6. Set Codegen to Class Definition or generate the files manually into `LiiO_EatClean/Models/CoreData/`.
</action>
<acceptance_criteria>
- The CoreData model has 3 new entities with correct attributes and relationships.
- Schema push is simulated or Xcode model updated without breaking existing `Meal`/`MealFood` entities.
</acceptance_criteria>
</task>

<task id="25-01-02">
<title>DailyPlan Repository</title>
<read_first>
- LiiO_EatClean/Repositories/DailyPlanRepository.swift
</read_first>
<action>
1. Create `DailyPlanRepository.swift`.
2. Define protocol `DailyPlanRepositoryProtocol` and class `DailyPlanRepository`.
3. Implement `fetchPlan(for date: Date) -> DailyPlan?`. It MUST normalize the date: `let normalized = Calendar.current.startOfDay(for: date)` and query `date == normalized`.
4. Implement `savePlan(_ plan: DailyPlan, status: String)` mapping to CoreData.
5. Implement `cleanupOldDrafts()` to delete any plans where `status == "draft"` and date is older than 24 hours.
</action>
<acceptance_criteria>
- `DailyPlanRepository.swift` contains the protocol and class.
- Methods correctly use `startOfDay` and CoreData context logic.
- Repository compiles without errors.
</acceptance_criteria>
</task>

<task id="25-01-03">
<title>Horizontal Date Strip UI</title>
<read_first>
- LiiO_EatClean/Views/MealPlan/HorizontalDateStrip.swift
</read_first>
<action>
1. Create SwiftUI component `HorizontalDateStrip`.
2. Accept `@Binding var selectedDate: Date`.
3. Render a horizontally scrolling list of dates (e.g., past 7 days to future 7 days).
4. Highlight the currently selected date using the app's primary color.
5. Include a calendar icon button at the trailing edge that opens a native `.sheet` with `DatePicker("", selection: $selectedDate, displayedComponents: .date)`.
</action>
<acceptance_criteria>
- `HorizontalDateStrip.swift` exists and compiles.
- The view scrolls horizontally and updates the `selectedDate` binding.
- Selected date styling is visually distinct.
</acceptance_criteria>
</task>

<task id="25-01-04">
<title>MealPlanViewModel Integration & Draft Handling</title>
<read_first>
- LiiO_EatClean/ViewModels/MealPlanViewModel.swift
- LiiO_EatClean/Views/MealPlan/MealPlanView.swift
</read_first>
<action>
1. Inject `DailyPlanRepositoryProtocol` into `MealPlanViewModel`.
2. Add `@Published var selectedDate: Date = Calendar.current.startOfDay(for: Date())`.
3. Add `onChange(of: selectedDate)` to fetch the plan from the repository.
4. If fetched plan has `status == "draft"`, set `@Published var showDraftAlert = true`.
5. Implement functions `continueDraft()` (load data) and `deleteDraft()` (delete from repository and refresh).
6. Update `MealPlanView.swift` to include `HorizontalDateStrip` at the top and handle the draft alert.
</action>
<acceptance_criteria>
- `MealPlanViewModel` uses `DailyPlanRepository`.
- Changing `selectedDate` fetches the corresponding plan.
- Draft handling logic correctly toggles `showDraftAlert`.
- `MealPlanView` displays the `HorizontalDateStrip`.
</acceptance_criteria>
</task>
