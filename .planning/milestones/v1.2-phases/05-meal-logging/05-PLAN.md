---
wave: 1
depends_on: ["04-PLAN"]
files_modified: ["LiiO_EatClean/Data/Protocols/MealRepositoryProtocol.swift", "LiiO_EatClean/Data/Repositories/MealRepository.swift", "LiiO_EatClean/Features/Meals/AddMealViewModel.swift", "LiiO_EatClean/Features/Meals/AddMealView.swift", "LiiO_EatClean/Features/Meals/FoodSearchView.swift", "LiiO_EatClean/Features/Home/HomeViewModel.swift", "LiiO_EatClean/Features/Home/HomeView.swift", "LiiO_EatClean/Features/Home/Components/MealCardView.swift"]
autonomous: true
---

# Phase 5: Meal Logging (Core Loop)

## Objective
Implement the core functionality of logging meals. This involves creating a unified "Add Meal" sheet that incorporates the food search, allows inline quantity input, supports a multi-item cart, and saves everything to CoreData. Finally, enable swipe-to-delete on the Dashboard meal cards for rapid corrections.

## Requirements Covered
- **MEAL-01**: Add Meal screen with food search, choose meal type.
- **MEAL-02**: Inline portion/quantity input popup.
- **MEAL-03**: Save meal (Cart functionality) -> update DailyLog -> refresh Dashboard.
- **MEAL-06**: Inline delete from Dashboard.

---

## 1. Meal Repository Enhancements
<task>
<read_first>
- `LiiO_EatClean/Data/Repositories/MealRepository.swift`
- `LiiO_EatClean/Data/Protocols/MealRepositoryProtocol.swift`
</read_first>
<action>
Modify `MealRepositoryProtocol` and `MealRepository`:
- **Fetch Logic:** Update `fetchMeals(by date: Date)` to filter `Meal` entities where the date matches the given day (start of day to end of day). Map `mealFoods` and its nested `FoodItem` properties to `MealFoodModel`.
- **Save Logic:** Update `saveMeal(_ meal: MealModel, for date: Date)` to first check if a `Meal` of `mealType` already exists for `date`. If it does, append the `MealFood` entities to it. Otherwise, create a new `Meal`. Ensure `MealFood` snapshots are multiplied by `quantity` before saving (e.g., `caloriesSnapshot = food.calories * quantity`).
- **Delete Logic:** Add `func deleteMealFood(by id: UUID) async throws`. Find the `MealFood` by ID and delete it. If the parent `Meal` becomes empty, optionally delete the parent `Meal` as well.
</action>
<acceptance_criteria>
- `fetchMeals` correctly fetches and maps nested `MealFood` and `FoodItem`.
- `saveMeal` handles existing vs. new Meals and correctly computes snapshots.
- `deleteMealFood` successfully deletes a specific `MealFood`.
</acceptance_criteria>
</task>

## 2. AddMealViewModel (Cart State)
<task>
<read_first>
- `.planning/phases/05-meal-logging/05-CONTEXT.md` (D-05, D-06)
</read_first>
<action>
Create `LiiO_EatClean/Features/Meals/AddMealViewModel.swift`:
- Properties: `selectedMealType: String`, `cartItems: [MealFoodModel]`.
- Inject `MealRepositoryProtocol`.
- `func addToCart(food: FoodItemModel, quantity: Double)`: Calculate snapshot values (`food.calories * quantity`, etc.) and append to `cartItems`.
- `func saveCart(for date: Date) async`: Create a `MealModel` containing the `cartItems` and call `repository.saveMeal`.
- Note: This ViewModel will be passed as an Environment object or directly instantiated in the sheet.
</action>
<acceptance_criteria>
- `AddMealViewModel` tracks cart items.
- Correctly computes snapshots based on quantity.
- `saveCart()` correctly calls the repository.
</acceptance_criteria>
</task>

## 3. Add Meal UI and Flow
<task>
<read_first>
- `.planning/phases/05-meal-logging/05-CONTEXT.md` (D-01, D-02, D-03)
- `LiiO_EatClean/Features/Meals/FoodSearchView.swift`
</read_first>
<action>
Modify `FoodSearchView`:
- Update it to take a closure `onFoodSelected: (FoodItemModel) -> Void` instead of logging internally.

Create `LiiO_EatClean/Features/Meals/AddMealView.swift`:
- Embed `FoodSearchView`.
- Use an alert (`.alert("Khẩu phần", isPresented: ...)`) for inline quantity input. When a food is selected from `FoodSearchView`, trigger the alert with a `TextField` (default "1").
- **Cart UI:** A bottom bar showing "X món đã chọn" and a "Hoàn tất" (Done) button. Tapping Done calls `viewModel.saveCart()` and dismisses the view.
- **Header:** A Segmented Control or Text showing the `selectedMealType`.
</action>
<acceptance_criteria>
- `AddMealView` contains `FoodSearchView`.
- Inline quantity alert captures numeric input.
- Added items are displayed/tracked in a bottom cart bar.
- Save action works and dismisses sheet.
</acceptance_criteria>
</task>

## 4. Dashboard Integration (HomeView & MealCardView)
<task>
<read_first>
- `.planning/phases/05-meal-logging/05-CONTEXT.md` (D-07)
- `LiiO_EatClean/Features/Home/HomeView.swift`
- `LiiO_EatClean/Features/Home/Components/MealCardView.swift`
</read_first>
<action>
Update `HomeViewModel`:
- Add `func deleteMealFood(id: UUID) async` which calls `MealRepository.deleteMealFood(by:)` and then reloads the dashboard.

Update `MealCardView`:
- Refactor the food list (`ForEach`) to use a `List` structure or `swipeActions` if inside a list, or implement a simple swipe gesture for deletion.
- Add a closure `onDelete: (UUID) -> Void` to pass the deletion action back to `HomeView`.
- Ensure the individual `MealFood` items are identifiable and can trigger `onDelete(mealFood.id)`.

Update `HomeView`:
- Hook up the `isPresented` for `AddMealView` as a `.sheet`.
- Provide an "Add" button specifically in `MealCardView` or use the global "Thêm bữa ăn" button to trigger the sheet and pass the meal type.
- Refresh `loadDashboard()` after `AddMealView` is dismissed.
</action>
<acceptance_criteria>
- `AddMealView` opens as a sheet from `HomeView`.
- Dashboard refreshes upon sheet dismissal.
- User can swipe to delete individual items from `MealCardView`.
</acceptance_criteria>
</task>

---
## Verification Criteria
- Grep: `saveMeal` logic correctly multiplies `calories * quantity` in `MealRepository.swift`.
- Grep: `.alert` exists in `AddMealView.swift` for quantity input.
- Grep: `swipeActions` or deletion logic exists in `MealCardView.swift`.
- Grep: `.sheet(isPresented:)` exists in `HomeView.swift`.
