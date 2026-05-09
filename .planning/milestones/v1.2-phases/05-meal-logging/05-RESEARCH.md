# Phase 5: Meal Logging (Core Loop) — Research

**Gathered:** 2026-04-29

## 1. Add Meal UX Flow
The Add Meal flow consists of:
1.  **Entry Point:** `HomeView` (Dashboard) has "Add Meal" buttons. Instead of just one generic button, each `MealCardView` should ideally have an "Add" button, or tapping the generic "Add" button opens a sheet where the meal type is selected. Based on Context (D-02), the meal type should be passed down. For now, since `HomeView` has a generic `Add Meal` button at the bottom, we'll pass a default type or let the user choose in the sheet header.
2.  **Add Meal Sheet (`AddMealView`):**
    *   **Header:** Shows the currently selected meal type (Breakfast/Lunch/Dinner/Snack).
    *   **Content:** Embeds `FoodSearchView` (from Phase 4).
    *   **Cart/Footer:** A sticky bottom bar showing the current items in the cart and a "Hoàn tất" (Done) button.
3.  **Quantity Popup:** When tapping a food item in `FoodSearchView`, a small popup/alert appears to enter the quantity (e.g., number of servings or multiplier).
    *   SwiftUI's `.alert("Quantity", isPresented: ...)` with a `TextField` is the fastest way to implement this inline popup without breaking the flow.

## 2. Meal Repository Enhancements
Currently, `MealRepository.swift` is a stub. We need to implement:
*   `fetchMeals(by date: Date)`: Needs to fetch all `Meal` entities where the date falls within the start and end of the given day. It must also eagerly load (or map) the `MealFood` relationship and the underlying `FoodItem` relationship to populate `MealFoodModel`.
*   `saveMeal(_ meal: MealModel)`: 
    *   If a `Meal` for the given type and date already exists, we should probably append the new `MealFood`s to it rather than creating a duplicate `Meal` entity for the same meal type on the same day.
    *   The `MealFood` entities must snapshot the `FoodItem`'s macros multiplied by the `quantity`.
*   `deleteMealFood(by id: UUID)`: Required for the swipe-to-delete functionality on the Dashboard.

## 3. Integrating with Dashboard (`HomeViewModel`)
The `HomeViewModel` currently loads meals once on `loadDashboard()`.
To make it reactive:
*   When a meal is saved from `AddMealView`, we can either:
    *   Refresh `HomeViewModel` (e.g., via a callback or notification).
    *   Or have `HomeViewModel` observe CoreData directly (using `NSFetchedResultsController` or similar, but since we are using async/await and `@Observable`, a simple `loadDashboard()` trigger is easiest).
*   Swipe-to-delete in `MealCardView`: We need to pass a deletion action to `MealCardView` so it can call `HomeViewModel.deleteMealFood(id:)` which updates the repository and refreshes the data.

## 4. State Management for Cart (`AddMealViewModel`)
We need a view model dedicated to the Add Meal flow to manage the cart.
*   `cartItems: [MealFoodModel]`
*   `func addToCart(food: FoodItemModel, quantity: Double)`: Creates a `MealFoodModel` taking snapshots of the calories and macros.
*   `func saveCart() async`: Calls `MealRepository` to save the cart items into the corresponding `Meal`.
