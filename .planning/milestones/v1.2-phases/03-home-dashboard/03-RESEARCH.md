# Phase 3: Home Dashboard — Research

**Gathered:** 2026-04-29

## 1. SwiftUI Circular Progress Ring

### Custom Ring using `Circle().trim()`
```swift
struct CalorieRingView: View {
    let consumed: Double
    let target: Double
    
    private var progress: Double { min(consumed / target, 1.5) }
    private var isOverTarget: Bool { consumed > target }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 16)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    isOverTarget ? Color.orange : Color.green,
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 1.0), value: progress)
            
            // Center text
            VStack(spacing: 2) {
                Text("\(Int(consumed))")
                    .font(.system(size: 32, weight: .bold))
                Text("/ \(Int(target)) kcal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
```

### Key Details
- `.trim(from:to:)` creates the arc effect
- `.rotationEffect(.degrees(-90))` starts from top (12 o'clock position)
- `lineCap: .round` gives smooth rounded ends
- Animation via `.animation(.easeOut, value:)` for smooth fill

## 2. Macro Progress Bars

### Horizontal ProgressView
```swift
struct MacroBarView: View {
    let label: String
    let consumed: Double
    let target: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(.caption).foregroundColor(.secondary)
                Spacer()
                Text("\(Int(consumed))/\(Int(target))g").font(.caption2)
            }
            ProgressView(value: min(consumed / target, 1.0))
                .tint(color)
        }
    }
}
```

### Color Suggestions
- Protein: `.blue` or custom blue (#4A90D9)
- Carbs: `.orange` or custom yellow (#F5A623)
- Fat: `.pink` or custom pink (#E91E63)

## 3. @Observable ViewModel Pattern (iOS 17+)

### HomeViewModel
```swift
@Observable
class HomeViewModel {
    var user: UserModel?
    var todayMeals: [MealModel] = []
    var isLoading = false
    
    private let mealRepository: MealRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    
    func loadDashboard() async {
        isLoading = true
        do {
            user = try await userRepository.fetchUser()
            todayMeals = try await mealRepository.fetchMeals(by: Date())
        } catch {
            print("Error: \(error)")
        }
        isLoading = false
    }
    
    var totalCalories: Double {
        todayMeals.flatMap { $0.mealFoods }.reduce(0) { $0 + $1.caloriesSnapshot }
    }
}
```

### Key Details
- `@Observable` macro replaces `ObservableObject` + `@Published` in iOS 17
- Views use `@State` to hold the ViewModel instance
- `.task { await viewModel.loadDashboard() }` for initial load

## 4. Meal Cards with Food Preview

### Card Design
Each card shows:
- Icon (SF Symbol) + Meal type name + Total calories for that meal
- If foods exist: list first 2-3 food names with their calories
- If empty: "Chưa có bữa ăn" + "+" icon

### Filtering Meals by Type
```swift
func meals(for type: String) -> [MealModel] {
    todayMeals.filter { $0.mealType == type }
}
```

## 5. Macro Targets

Since user only sets calorie target, macro targets need to be derived:
- Standard split: Protein 30%, Carbs 40%, Fat 30%
- Protein: target * 0.30 / 4 (4 cal per gram)
- Carbs: target * 0.40 / 4
- Fat: target * 0.30 / 9 (9 cal per gram)

---
*Research completed.*
