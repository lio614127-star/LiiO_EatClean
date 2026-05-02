---
wave: 1
depends_on: ["02-PLAN"]
files_modified: ["LiiO_EatClean/Features/Home/HomeView.swift", "LiiO_EatClean/Features/Home/HomeViewModel.swift", "LiiO_EatClean/Features/Home/Components/CalorieRingView.swift", "LiiO_EatClean/Features/Home/Components/MacroBarView.swift", "LiiO_EatClean/Features/Home/Components/MealCardView.swift"]
autonomous: true
---

# Phase 3: Home Dashboard

## Objective
Replace the HomeView placeholder with a fully functional dashboard: animated calorie ring with macro bars, greeting header with remaining calories, 4 detailed meal cards, and full-width Add Meal button.

## Requirements Covered
- **DASH-01**: Header "Hello, LiiO" with calories today summary
- **DASH-02**: Calories progress ring (animated) showing consumed/target
- **DASH-03**: Meals today section (Breakfast/Lunch/Dinner/Snack cards) with calories per meal
- **DASH-04**: "Add Meal" button prominent
- **DASH-05**: Dashboard auto-refresh when save new meal

---

## 1. HomeViewModel — @Observable Data Layer
<task>
<read_first>
- `.planning/phases/03-home-dashboard/03-CONTEXT.md` (D-17 through D-20: data flow)
- `LiiO_EatClean/Data/Repositories/MealRepository.swift` (fetchMeals method)
- `LiiO_EatClean/Data/Repositories/UserRepository.swift` (fetchUser method)
- `LiiO_EatClean/Data/Models/MealModel.swift` (MealModel struct)
- `LiiO_EatClean/Data/Models/MealFoodModel.swift` (snapshot fields)
</read_first>
<action>
Create `LiiO_EatClean/Features/Home/HomeViewModel.swift`:

```swift
@Observable
class HomeViewModel {
    var user: UserModel?
    var todayMeals: [MealModel] = []
    var isLoading = false
    
    private let mealRepository: MealRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    
    init(mealRepository: MealRepositoryProtocol = MealRepository(),
         userRepository: UserRepositoryProtocol = UserRepository()) {
        self.mealRepository = mealRepository
        self.userRepository = userRepository
    }
    
    func loadDashboard() async { ... }
    
    // Computed properties:
    var totalCalories: Double  // sum of all mealFoods caloriesSnapshot
    var totalProtein: Double   // sum of proteinSnapshot
    var totalCarbs: Double     // sum of carbsSnapshot
    var totalFat: Double       // sum of fatSnapshot
    var remainingCalories: Double  // target - consumed
    var isOverTarget: Bool     // consumed > target
    
    // Macro targets derived from calorie target:
    var proteinTarget: Double  // target * 0.30 / 4
    var carbsTarget: Double    // target * 0.40 / 4
    var fatTarget: Double      // target * 0.30 / 9
    
    func meals(for type: String) -> [MealModel]  // filter by mealType
}
```
</action>
<acceptance_criteria>
- File exists at `LiiO_EatClean/Features/Home/HomeViewModel.swift`
- Uses `@Observable` macro (not ObservableObject)
- Contains `func loadDashboard() async`
- Contains computed properties for totalCalories, totalProtein, totalCarbs, totalFat
- Contains macro target derivation (30/40/30 split)
- Uses MealRepositoryProtocol and UserRepositoryProtocol
</acceptance_criteria>
</task>

## 2. CalorieRingView — Animated Progress Ring
<task>
<read_first>
- `.planning/phases/03-home-dashboard/03-CONTEXT.md` (D-01 through D-05)
- `.planning/phases/03-home-dashboard/03-RESEARCH.md` (Section 1: ring implementation)
</read_first>
<action>
Create `LiiO_EatClean/Features/Home/Components/CalorieRingView.swift`:

- ZStack with background Circle().stroke (gray) + foreground Circle().trim().stroke (green/orange)
- Ring color: green (#4CAF50) normally, orange (#FF9800) when consumed > target
- Center content: consumed (large bold, 32pt) + "/ target kcal" (caption, secondary)
- Animation: `.easeOut(duration: 1.0)` on progress value
- `.rotationEffect(.degrees(-90))` to start from top
- `lineWidth: 16`, `lineCap: .round`
</action>
<acceptance_criteria>
- `CalorieRingView.swift` contains `Circle().trim(from: 0, to:`
- Contains `.rotationEffect(.degrees(-90))`
- Contains color logic switching between green and orange
- Contains `.animation(` for smooth ring fill
</acceptance_criteria>
</task>

## 3. MacroBarView — Protein/Carbs/Fat Bars
<task>
<read_first>
- `.planning/phases/03-home-dashboard/03-CONTEXT.md` (D-04)
- `.planning/phases/03-home-dashboard/03-RESEARCH.md` (Section 2: macro bars)
</read_first>
<action>
Create `LiiO_EatClean/Features/Home/Components/MacroBarView.swift`:

- Reusable component: label + consumed/target text + ProgressView
- Parameters: label (String), consumed (Double), target (Double), color (Color)
- Use `ProgressView(value: min(consumed/target, 1.0))` with `.tint(color)`
- Layout: HStack { label ... consumed/target_g } + ProgressView below
</action>
<acceptance_criteria>
- `MacroBarView.swift` exists with `label`, `consumed`, `target`, `color` parameters
- Contains `ProgressView(value:`
- Contains `.tint(color)`
</acceptance_criteria>
</task>

## 4. MealCardView — Detailed Meal Card
<task>
<read_first>
- `.planning/phases/03-home-dashboard/03-CONTEXT.md` (D-09 through D-13)
</read_first>
<action>
Create `LiiO_EatClean/Features/Home/Components/MealCardView.swift`:

- Parameters: mealType (String), icon (String), meals ([MealModel])
- If meals empty: show "Chưa có bữa ăn" + Image(systemName: "plus.circle") in light gray
- If meals exist: show meal type name + icon + total calories + list of first 2-3 food item names with their calories
- Card styling: RoundedRectangle background, padding, shadow
- Card icons: "sunrise.fill" (breakfast), "sun.max.fill" (lunch), "moon.fill" (dinner), "leaf.fill" (snack)
</action>
<acceptance_criteria>
- `MealCardView.swift` exists with `mealType`, `icon`, `meals` parameters
- Contains "Chưa có bữa ăn" empty state text
- Contains `prefix(3)` or similar to limit food preview to 2-3 items
- Contains `RoundedRectangle` for card background
</acceptance_criteria>
</task>

## 5. HomeView — Assemble Dashboard
<task>
<read_first>
- `LiiO_EatClean/Features/Home/HomeView.swift` (existing placeholder — will be replaced)
- `.planning/phases/03-home-dashboard/03-CONTEXT.md` (all decisions)
</read_first>
<action>
Replace `LiiO_EatClean/Features/Home/HomeView.swift` with full dashboard:

Layout (ScrollView > VStack):
1. Header: "Xin chào, [name]!" + remaining calories subtitle
2. CalorieRingView (consumed, target)
3. 3x MacroBarView (protein blue, carbs orange, fat pink)
4. 4x MealCardView (breakfast, lunch, dinner, snack)
5. "Thêm bữa ăn" full-width green button at bottom

- Use `@State private var viewModel = HomeViewModel()`
- Load data with `.task { await viewModel.loadDashboard() }`
- Refresh on `.onAppear` for auto-refresh when returning from other screens
- Subtitle: "Còn X kcal hôm nay" or "Đã vượt X kcal hôm nay" (orange) if over target
</action>
<acceptance_criteria>
- `HomeView.swift` contains `@State private var viewModel = HomeViewModel()`
- Contains `.task { await viewModel.loadDashboard() }`
- Contains `CalorieRingView`
- Contains `MacroBarView` (3 instances)
- Contains `MealCardView` (4 instances for breakfast/lunch/dinner/snack)
- Contains "Thêm bữa ăn" button text
- Contains "Xin chào" greeting
- Contains "Còn" and "Đã vượt" text for remaining calories logic
</acceptance_criteria>
</task>

---
## Verification Criteria
- Grep: `@Observable` exists in HomeViewModel.swift
- Grep: `CalorieRingView` referenced in HomeView.swift
- Grep: `MacroBarView` referenced in HomeView.swift (3 times)
- Grep: `MealCardView` referenced in HomeView.swift (4 times)
- Grep: `"Thêm bữa ăn"` exists in HomeView.swift
- Grep: `Circle().trim` exists in CalorieRingView.swift
- All files exist in correct directories under Features/Home/
