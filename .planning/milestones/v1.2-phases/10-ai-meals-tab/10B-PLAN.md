# Plan 10B: Meals Tab — Today's Meals Detailed List

**Wave:** 2 (depends on Plan 10A for MemoryManager)
**Requirements:** AIMEAL-03, AIMEAL-04
**Depends on:** Plan 10A

## Objective

Xây dựng phần "Today's Meals" của Meals tab: detailed list grouped by meal type, swipe actions, macro display, full CRUD — biến placeholder hiện tại thành workspace quản lý bữa ăn.

## Task 1: Create MealsViewModel

<read_first>
- LiiO_EatClean/Features/Meals/MealsView.swift (current placeholder)
- LiiO_EatClean/Features/Home/HomeViewModel.swift (reference for loading meals)
- LiiO_EatClean/Data/Repositories/MealRepository.swift
- LiiO_EatClean/Data/Protocols/MealRepositoryProtocol.swift
- LiiO_EatClean/Data/Protocols/UserRepositoryProtocol.swift
</read_first>

<action>
Create `LiiO_EatClean/Features/Meals/MealsViewModel.swift`:

```swift
@Observable
class MealsViewModel {
    var todayMeals: [MealModel] = []
    var dailyTarget: Double = 2000
    var totalCalories: Double = 0
    var remainingCalories: Double { max(0, dailyTarget - totalCalories) }
    var isLoading = false
    
    private let mealRepository: MealRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    
    // Group meals by type
    func meals(for type: String) -> [MealModel] { ... }
    
    // CRUD operations
    func loadTodayMeals() async { ... }
    func deleteMealFood(id: UUID) async { ... }
    
    // Computed stats
    var totalProtein: Double { ... }
    var totalCarbs: Double { ... }
    var totalFat: Double { ... }
}
```

Reuse patterns from `HomeViewModel` for loading meals. Must use Repository protocols per project rules.
</action>

<acceptance_criteria>
- File `Features/Meals/MealsViewModel.swift` exists
- Class uses `@Observable` macro (not ObservableObject)
- Contains `func meals(for type: String) -> [MealModel]`
- Contains `var remainingCalories: Double` computed property
- Uses `MealRepositoryProtocol` and `UserRepositoryProtocol` (not direct CoreData access)
</acceptance_criteria>

## Task 2: Rebuild MealsView with Detailed List

<read_first>
- LiiO_EatClean/Features/Meals/MealsView.swift
- LiiO_EatClean/Features/Home/HomeView.swift (reference for meal sections)
- LiiO_EatClean/Features/Home/Components/MealCardView.swift (reference style)
- LiiO_EatClean/Features/Meals/AddMealView.swift
</read_first>

<action>
Replace the MealsView placeholder with full implementation:

**Layout structure (ScrollView):**
```
NavigationStack {
  ScrollView {
    // Header: "Hôm nay" + date + remaining calories summary
    VStack {
      Text("Hôm nay")
      Text("Còn X kcal") 
    }
    
    // Meal Sections (4 groups)
    ForEach(["Bữa sáng", "Bữa trưa", "Bữa tối", "Ăn vặt"]) { type in
      MealSection(type: type, meals: viewModel.meals(for: type))
    }
    
    // AI Section placeholder (will be filled by Plan 10C)
    Spacer(minLength: 200) // Reserve space for AI section
  }
}
```

**MealSection component:**
- Section header: meal type icon + name + total calories for this meal
- Each food item shows: name + kcal + P/C/F mini macros
- Swipe left → delete (`.swipeActions(edge: .trailing)`)
- Swipe right → edit (`.swipeActions(edge: .leading)`)  
- Tap item → sheet to edit quantity/meal type
- Empty state: "Chưa có bữa ăn — nhấn + để thêm"
- "+" button per section → opens AddMealView with pre-selected meal type

**Macro mini display per item:**
```swift
HStack(spacing: 8) {
    Text("P: \(Int(food.proteinSnapshot))g").font(.caption2).foregroundColor(.blue)
    Text("C: \(Int(food.carbsSnapshot))g").font(.caption2).foregroundColor(.orange)
    Text("F: \(Int(food.fatSnapshot))g").font(.caption2).foregroundColor(.pink)
}
```

**Integration:** Wire sheet for AddMealView. Refresh on dismiss.
</action>

<acceptance_criteria>
- MealsView.swift contains `@State private var viewModel = MealsViewModel()`
- MealsView shows 4 meal type sections (Bữa sáng, Bữa trưa, Bữa tối, Ăn vặt)
- Each food item displays name, kcal, and P/C/F macro values
- `.swipeActions(edge: .trailing)` exists with delete action
- `.swipeActions(edge: .leading)` exists with edit action
- Each section has a "+" button that opens AddMealView with pre-selected meal type
- Empty state text "Chưa có bữa ăn" visible when no meals for a type
- Sheet for AddMealView is wired and refreshes on dismiss
</acceptance_criteria>

## Task 3: Create MealItemRow Component

<read_first>
- LiiO_EatClean/Features/Home/Components/MealCardView.swift (existing pattern reference)
- LiiO_EatClean/Data/Models/MealFoodModel.swift
</read_first>

<action>
Create `LiiO_EatClean/Features/Meals/Components/MealItemRow.swift`:

A reusable row component for individual food items in the detailed list.

```swift
struct MealItemRow: View {
    let mealFood: MealFoodModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(mealFood.foodItem?.name ?? "Unknown")
                    .font(.body)
                
                // Macro mini display
                HStack(spacing: 8) {
                    MacroMini(label: "P", value: mealFood.proteinSnapshot, color: .blue)
                    MacroMini(label: "C", value: mealFood.carbsSnapshot, color: .orange)
                    MacroMini(label: "F", value: mealFood.fatSnapshot, color: .pink)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(Int(mealFood.caloriesSnapshot)) kcal")
                    .font(.subheadline.bold())
                    .foregroundColor(.green)
                
                if mealFood.quantity != 1.0 {
                    Text("x\(String(format: "%.1f", mealFood.quantity))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
```

Style: clean, readable, consistent with app's Apple-style design (#4CAF50 green, SF Pro, rounded corners).
</action>

<acceptance_criteria>
- File `Features/Meals/Components/MealItemRow.swift` exists
- Shows food name, calories, and P/C/F macro mini values
- Uses app's green color for calorie display
- Shows quantity multiplier when != 1.0
</acceptance_criteria>

## Verification

### Manual Verification
1. Build project — no compile errors.
2. Open Meals tab — see 4 meal sections with headers.
3. Log a meal from Home → verify it appears in the Meals tab under correct section.
4. Swipe left on an item → delete button appears → tap → item deleted.
5. Swipe right on an item → edit action appears.
6. Tap "+" on a section → AddMealView opens with correct meal type pre-selected.
7. Verify macro P/C/F mini display shows for each food item.
8. Empty section shows "Chưa có bữa ăn" text.
