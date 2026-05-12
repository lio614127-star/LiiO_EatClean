# Phase 25 Research: Date-Aware Planning Foundation

## 1. CoreData Schema Architecture
To separate planned meals from actual logged intake, three new entities are required in `LiiO_EatClean.xcdatamodeld`:

### `DailyPlan` Entity
- `id` (UUID)
- `date` (Date) - Must always be normalized to `startOfDay`
- `status` (String) - Use values like "draft" or "active"
- `targetCalories` (Double)
- `targetProtein` (Double), `targetCarbs` (Double), `targetFat` (Double)
- **Relationships:** `plannedMeals` (To-many, Destination: `PlannedMeal`)

### `PlannedMeal` Entity
- `id` (UUID)
- `type` (String) - "Sáng", "Trưa", "Tối", "Ăn vặt"
- `convertedMealId` (UUID) - Optional link to the actual `Meal` created when user marks it as eaten
- **Relationships:** `dailyPlan` (To-one, Destination: `DailyPlan`), `foodItems` (To-many, Destination: `PlannedFoodItem`)

### `PlannedFoodItem` Entity
- `id` (UUID)
- `name` (String)
- `calories` (Double)
- `protein` (Double), `carbs` (Double), `fat` (Double)
- `servingSize` (Double)
- **Relationships:** `plannedMeal` (To-one, Destination: `PlannedMeal`)

## 2. Repositories and Logic
We need a `DailyPlanRepositoryProtocol` and `DailyPlanRepository` focusing on:
- `fetchPlan(for date: Date) -> DailyPlanModel?` - Normalizes the provided date to `startOfDay` and fetches.
- `savePlan(_ plan: DailyPlanModel)` - Inserts or updates the daily plan. Drafts will have `status = "draft"`.
- `cleanupOldDrafts()` - A background function to delete any "draft" `DailyPlan` older than 24 hours.

## 3. UI/UX Implementations
- **HorizontalDateStrip Component**: A new component showing current day centered, past days to the left, and future days to the right. Includes an icon to open a full Calendar Sheet for further dates.
- **Draft Interaction View**: In the planning view model, on load we query `fetchPlan(for: today)`. If it returns a draft, trigger an Alert or Custom Sheet presenting three actions:
  - "Tiếp tục draft" (Load draft into view)
  - "Xóa draft" (Delete from CoreData, start fresh)
  - "Tạo mới" (Same as delete and start fresh)

## 4. Key Constraints and Blockers
- **No Overwriting Past Data**: The requirement states that selecting past days loads the old plan. The logic must not generate new plans for past dates unless explicitly asked.
- **Date Normalization**: All CoreData fetches MUST use `Calendar.current.startOfDay(for: date)` to avoid 11:59 PM vs 12:01 AM drift.
- **Schema Migration**: A new CoreData model version (e.g., `LiiO_EatClean 5`) must be created to safely add these entities without crashing existing installations. Old UserDefaults plans will be ignored.
