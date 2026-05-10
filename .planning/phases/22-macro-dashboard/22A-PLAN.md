---
phase: 22
plan_id: 22A
title: "Macro Aggregation Service & Progress Integration"
wave: 1
depends_on: []
files_modified:
  - LiiO_EatClean/Features/Progress/ProgressViewModel.swift
  - LiiO_EatClean/Features/Progress/ProgressTabView.swift
  - LiiO_EatClean/Features/Progress/Components/MacroDashboardView.swift
  - LiiO_EatClean/Features/Progress/Models/MacroAggregateModel.swift
requirements:
  - DATA-03
autonomous: true
---

# Plan 22A: Macro Aggregation Service & Progress Integration

## Objective
Xây dựng lớp dữ liệu Macro Aggregation trong ProgressViewModel và tạo component MacroDashboardView hiển thị bên dưới Calories Chart. Đây là nền tảng để Wave 2 thêm Goal Rings và Insights.

## Tasks

### Task 1: Macro Aggregate Data Model

<read_first>
- LiiO_EatClean/Features/Progress/ProgressViewModel.swift
- LiiO_EatClean/Data/Models/MealFoodModel.swift
- LiiO_EatClean/Data/Models/MealModel.swift
</read_first>

<action>
Tạo file mới: `LiiO_EatClean/Features/Progress/Models/MacroAggregateModel.swift`

Định nghĩa struct:

```swift
import Foundation

struct MacroAggregate: Identifiable {
    let id = UUID()
    let totalProtein: Double    // grams
    let totalCarbs: Double      // grams
    let totalFat: Double        // grams
    let totalCalories: Double   // kcal
    let daysCount: Int          // number of days in range
    
    var proteinPercentage: Double {
        let proteinCals = totalProtein * 4
        guard totalCalories > 0 else { return 0 }
        return (proteinCals / totalCalories) * 100
    }
    
    var carbsPercentage: Double {
        let carbsCals = totalCarbs * 4
        guard totalCalories > 0 else { return 0 }
        return (carbsCals / totalCalories) * 100
    }
    
    var fatPercentage: Double {
        let fatCals = totalFat * 9
        guard totalCalories > 0 else { return 0 }
        return (fatCals / totalCalories) * 100
    }
    
    var avgDailyProtein: Double { daysCount > 0 ? totalProtein / Double(daysCount) : 0 }
    var avgDailyCarbs: Double { daysCount > 0 ? totalCarbs / Double(daysCount) : 0 }
    var avgDailyFat: Double { daysCount > 0 ? totalFat / Double(daysCount) : 0 }
}

struct MacroTarget {
    let proteinRatio: Double  // 0.30 = 30%
    let carbsRatio: Double    // 0.40 = 40%
    let fatRatio: Double      // 0.30 = 30%
    let dailyCalories: Double
    
    static func `default`(calories: Double) -> MacroTarget {
        MacroTarget(proteinRatio: 0.30, carbsRatio: 0.40, fatRatio: 0.30, dailyCalories: calories)
    }
    
    var proteinGrams: Double { (dailyCalories * proteinRatio) / 4 }
    var carbsGrams: Double { (dailyCalories * carbsRatio) / 4 }
    var fatGrams: Double { (dailyCalories * fatRatio) / 9 }
}
```
</action>

<acceptance_criteria>
- File `LiiO_EatClean/Features/Progress/Models/MacroAggregateModel.swift` exists
- File contains `struct MacroAggregate: Identifiable`
- File contains `var proteinPercentage: Double`
- File contains `struct MacroTarget`
- File contains `static func `default``
</acceptance_criteria>

### Task 2: Macro Aggregation Logic in ProgressViewModel

<read_first>
- LiiO_EatClean/Features/Progress/ProgressViewModel.swift
- LiiO_EatClean/Features/Progress/Models/MacroAggregateModel.swift
</read_first>

<action>
Chỉnh sửa `ProgressViewModel.swift`:

1. Thêm 2 properties:
```swift
var macroAggregate: MacroAggregate?
var macroTarget: MacroTarget?
```

2. Trong hàm `loadData()`, sau khi tính `dailyCalories` dictionary (dòng ~86), thêm đoạn tính macro aggregation:

```swift
// Aggregate Macros
var totalProtein: Double = 0
var totalCarbs: Double = 0
var totalFat: Double = 0
var totalCalsForMacro: Double = 0

for meal in meals {
    for food in meal.mealFoods {
        totalProtein += food.proteinSnapshot * food.quantity
        totalCarbs += food.carbsSnapshot * food.quantity
        totalFat += food.fatSnapshot * food.quantity
        totalCalsForMacro += food.caloriesSnapshot * food.quantity
    }
}

let activeDays = dailyCalories.values.filter { $0 > 0 }.count
macroAggregate = MacroAggregate(
    totalProtein: totalProtein,
    totalCarbs: totalCarbs,
    totalFat: totalFat,
    totalCalories: totalCalsForMacro,
    daysCount: max(activeDays, 1)
)

macroTarget = MacroTarget.default(calories: dailyTarget)
```
</action>

<acceptance_criteria>
- `ProgressViewModel.swift` contains `var macroAggregate: MacroAggregate?`
- `ProgressViewModel.swift` contains `var macroTarget: MacroTarget?`
- `ProgressViewModel.swift` contains `totalProtein += food.proteinSnapshot`
- Macro aggregation uses `.quantity` multiplier for accurate values
</acceptance_criteria>

### Task 3: MacroDashboardView Component

<read_first>
- LiiO_EatClean/Features/Home/Components/DailySummaryCardView.swift (reference for MacroMiniBar pattern)
- LiiO_EatClean/Features/Progress/Models/MacroAggregateModel.swift
- LiiO_EatClean/Features/Progress/ProgressViewModel.swift
</read_first>

<action>
Tạo file mới: `LiiO_EatClean/Features/Progress/Components/MacroDashboardView.swift`

Component hiển thị Macro Breakdown bên dưới Calories Chart. Layout:
- Header: "Tỉ lệ Dinh dưỡng" + time range label
- 3 horizontal progress bars (P/C/F) với percentage labels
- Compact, tổng chiều cao ~120pt

```swift
import SwiftUI

struct MacroDashboardView: View {
    let aggregate: MacroAggregate
    let target: MacroTarget
    let timeRange: TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(.green)
                    .font(.subheadline)
                Text("Tỉ lệ Dinh dưỡng")
                    .font(.headline)
                Spacer()
                Text(timeRangeLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .cornerRadius(6)
            }
            
            // Macro Bars
            VStack(spacing: 12) {
                MacroProgressBar(
                    label: "Protein",
                    shortLabel: "P",
                    currentGrams: aggregate.avgDailyProtein,
                    targetGrams: target.proteinGrams,
                    percentage: aggregate.proteinPercentage,
                    color: .blue
                )
                
                MacroProgressBar(
                    label: "Carbs",
                    shortLabel: "C",
                    currentGrams: aggregate.avgDailyCarbs,
                    targetGrams: target.carbsGrams,
                    percentage: aggregate.carbsPercentage,
                    color: .purple
                )
                
                MacroProgressBar(
                    label: "Fat",
                    shortLabel: "F",
                    currentGrams: aggregate.avgDailyFat,
                    targetGrams: target.fatGrams,
                    percentage: aggregate.fatPercentage,
                    color: .orange
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private var timeRangeLabel: String {
        switch timeRange {
        case .week: return "TB 7 ngày"
        case .month: return "TB 30 ngày"
        case .quarter: return "TB 3 tháng"
        }
    }
}

struct MacroProgressBar: View {
    let label: String
    let shortLabel: String
    let currentGrams: Double
    let targetGrams: Double
    let percentage: Double
    let color: Color
    
    private var progress: Double {
        guard targetGrams > 0 else { return 0 }
        return min(currentGrams / targetGrams, 1.5) // Cap at 150% for display
    }
    
    var body: some View {
        HStack(spacing: 10) {
            // Label
            Text(shortLabel)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .frame(width: 18)
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.7), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: min(CGFloat(progress) * geo.size.width, geo.size.width))
                        .animation(.spring(response: 0.5), value: progress)
                }
            }
            .frame(height: 8)
            
            // Values
            HStack(spacing: 4) {
                Text("\(Int(currentGrams))g")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                Text("/ \(Int(targetGrams))g")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .frame(width: 80, alignment: .trailing)
            
            // Percentage badge
            Text("\(Int(percentage))%")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .frame(width: 32)
        }
    }
}
```
</action>

<acceptance_criteria>
- File `LiiO_EatClean/Features/Progress/Components/MacroDashboardView.swift` exists
- File contains `struct MacroDashboardView: View`
- File contains `struct MacroProgressBar: View`
- MacroProgressBar has `LinearGradient` for premium feel
- Each bar shows `currentGrams`, `targetGrams`, and `percentage`
- Header shows time range label (TB 7 ngày / TB 30 ngày / TB 3 tháng)
</acceptance_criteria>

### Task 4: Integrate MacroDashboardView into ProgressTabView

<read_first>
- LiiO_EatClean/Features/Progress/ProgressTabView.swift
- LiiO_EatClean/Features/Progress/Components/MacroDashboardView.swift
</read_first>

<action>
Chỉnh sửa `ProgressTabView.swift`:

Trong ScrollView > VStack, ngay sau ZStack chứa chart (khoảng dòng 51), TRƯỚC time range Picker, thêm Macro Dashboard CHỈ khi đang ở tab Calories:

```swift
// ZStack chart ... .frame(minHeight: 250) <-- already here

// Macro Dashboard (only visible on Calories tab)
if viewModel.selectedTab == .calories,
   let aggregate = viewModel.macroAggregate,
   let target = viewModel.macroTarget {
    MacroDashboardView(
        aggregate: aggregate,
        target: target,
        timeRange: viewModel.selectedTimeRange
    )
    .padding(.horizontal)
    .transition(.opacity.combined(with: .move(edge: .top)))
    .animation(.easeInOut(duration: 0.3), value: viewModel.selectedTab)
}

// Time Range Toggle ... <-- already here
```

Macro section chỉ hiện khi có dữ liệu và đang ở tab Calories.
</action>

<acceptance_criteria>
- `ProgressTabView.swift` contains `MacroDashboardView(`
- Macro dashboard is conditionally shown only when `selectedTab == .calories`
- Macro dashboard has `.transition(.opacity` for smooth appearance
- Macro dashboard is placed BETWEEN chart ZStack and time range Picker
</acceptance_criteria>

## Verification

```bash
# Check all new files exist
test -f LiiO_EatClean/Features/Progress/Models/MacroAggregateModel.swift
test -f LiiO_EatClean/Features/Progress/Components/MacroDashboardView.swift

# Check integration
grep -q "MacroDashboardView" LiiO_EatClean/Features/Progress/ProgressTabView.swift
grep -q "macroAggregate" LiiO_EatClean/Features/Progress/ProgressViewModel.swift
```

## must_haves
- [ ] MacroAggregate model correctly calculates P/C/F percentages
- [ ] ProgressViewModel loads macro data from existing meal repository
- [ ] MacroDashboardView renders compact bars with gradient fill
- [ ] Dashboard only visible on Calories tab (not Weight tab)
- [ ] Data refreshes when time range changes
