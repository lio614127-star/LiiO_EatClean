# Phase 5: Meal Logging (Core Loop) - Context

**Gathered:** 2026-04-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Build the core user flow for logging meals. This spans from clicking "Add Meal" on the Dashboard, to opening the Food Search (built in Phase 4), adding quantities in a cart-style workflow, saving the transaction to CoreData, and enabling in-line deletion from the Dashboard. It optimizes for speed, reducing friction for daily repetitive logging.

</domain>

<decisions>
## Implementation Decisions

### Add Meal Flow UX
- **D-01:** UI Presentation: Use a bottom-up `Sheet` (Modal) for the Add Meal flow. This aligns with Apple's standard for quick actions and lets the user swipe down to dismiss without losing their context on the Dashboard.
- **D-02:** Context Selection: The user selects the meal type (Breakfast, Lunch, Dinner, Snack) *before* or *at the moment* they open the search sheet. They should not be asked at the very end. The Dashboard "Add" button should ideally pass the meal type context into the sheet.

### Quantity Input
- **D-03:** Inline Quantity Input: When a user taps a search result, display a lightweight popup or bottom sheet *immediately* to input the quantity/portion (e.g., multiplier or exact weight).
- **D-04:** No dedicated "Food Detail" screen in the critical path to maximize logging speed.

### Save Mechanism
- **D-05:** Cart / Multi-Log Pattern: The user can select a food, enter quantity, and add it to a temporary "Cart". They can continue searching and adding more foods.
- **D-06:** Batch Save: The user taps "Hoàn tất" (Done) to save the entire cart as a single `Meal` containing multiple `MealFood` entities in one CoreData transaction. This accurately reflects real-world eating behavior (e.g., rice + meat + soup).

### Edit/Delete Management
- **D-07:** Inline Dashboard Deletion: Implement "Swipe to delete" directly on the meal items (`MealCardView` elements) on the Dashboard for immediate corrections.
- **D-08:** The dedicated "Meals" Tab (Tab 2) will serve as a historical timeline / detailed log rather than the only place to edit.

### Agent's Discretion
- The UI design of the temporary "Cart" inside the Add Meal sheet (e.g., a floating bar at the bottom showing "X items selected").
- The UI of the quantity input popup (stepper vs text field).
- Logic for recalculating the daily total accurately when an item is deleted from the Dashboard.

</decisions>

<canonical_refs>
## Canonical References

### Prior Phase Context
- `.planning/phases/01-project-foundation/01-CONTEXT.md` — CoreData schema (Meal, MealFood snapshot pattern)
- `.planning/phases/03-home-dashboard/03-CONTEXT.md` — Home Dashboard UI
- `.planning/phases/04-food-database/04-CONTEXT.md` — Food Search logic and caching

### Project Context
- `.planning/REQUIREMENTS.md` — MEAL-01 through MEAL-06
- `.planning/ROADMAP.md` — Phase 5 success criteria

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `FoodSearchView` and `FoodSearchViewModel` (Phase 4) — Needs to be integrated into the new `AddMealView` sheet, likely refactored slightly to emit selected foods instead of just printing them.
- `MealRepository` (Phase 1 Stub) — Needs full implementation for `saveMeal`, `deleteMealFood`, etc.
- `HomeViewModel` (Phase 3) — Needs a refresh trigger or automatic propagation when CoreData updates.

### Integration Points
- Dashboard `HomeView` needs a `sheet(isPresented:)` modifier for the `AddMealView`.
- Dashboard `MealCardView` needs `.swipeActions` or similar for deletion, which means the card's internal layout might need adjustments (using `List` or `ForEach` inside a `List` structure instead of a plain `VStack` if we want native swipe actions, or a custom swipe gesture).

</code_context>

<specifics>
## Specific Ideas

- The entire flow must be optimized for "log as fast as possible."
- The `MealFood` entity must capture `caloriesSnapshot`, `proteinSnapshot`, etc., at the moment of saving the cart, multiplying the `FoodItem` base values by the user's selected quantity.

</specifics>

<deferred>
## Deferred Ideas

- A complex Food Detail screen with macro pie charts (Deferred).
- Editing an already logged meal's quantity (for v1, deleting and re-adding is acceptable if inline editing is too complex, but inline delete is mandatory).

</deferred>

---

*Phase: 05-Meal Logging*
*Context gathered: 2026-04-29*
