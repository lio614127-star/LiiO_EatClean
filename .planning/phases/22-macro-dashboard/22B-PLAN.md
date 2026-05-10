---
phase: 22
plan_id: 22B
title: "Macro Goal Rings, Trend Indicators & Coaching Insights"
wave: 2
depends_on: [22A]
files_modified:
  - LiiO_EatClean/Features/Progress/Components/MacroDashboardView.swift
  - LiiO_EatClean/Features/Progress/Components/MacroGoalRingView.swift
  - LiiO_EatClean/Features/Progress/Components/MacroInsightsView.swift
  - LiiO_EatClean/Features/Progress/ProgressViewModel.swift
  - LiiO_EatClean/Features/Progress/Models/MacroAggregateModel.swift
requirements:
  - DATA-03
autonomous: true
---

# Plan 22B: Macro Goal Rings, Trend Indicators & Coaching Insights

## Objective
Thêm Macro Goal Rings (% đạt mục tiêu), Trend Indicators cho 30N/3T (↑↓), và Coaching Insights (cảnh báo nhẹ nhàng kiểu coach). Hoàn thiện trải nghiệm Macro Dashboard premium.

## Tasks

### Task 1: MacroGoalRingView Component

<read_first>
- LiiO_EatClean/Features/Progress/Components/MacroDashboardView.swift
- LiiO_EatClean/Features/Home/Components/CalorieRingView.swift (reference for ring pattern)
- LiiO_EatClean/Features/Progress/Models/MacroAggregateModel.swift
</read_first>

<action>
Tạo file mới: `LiiO_EatClean/Features/Progress/Components/MacroGoalRingView.swift`

3 mini rings hiển thị % đạt mục tiêu (P/C/F). Layout ngang, mỗi ring ~50pt.

```swift
import SwiftUI

struct MacroGoalRingsRow: View {
    let aggregate: MacroAggregate
    let target: MacroTarget
    
    var body: some View {
        HStack(spacing: 0) {
            MacroGoalRing(
                label: "Protein",
                current: aggregate.avgDailyProtein,
                target: target.proteinGrams,
                color: .blue
            )
            MacroGoalRing(
                label: "Carbs",
                current: aggregate.avgDailyCarbs,
                target: target.carbsGrams,
                color: .purple
            )
            MacroGoalRing(
                label: "Fat",
                current: aggregate.avgDailyFat,
                target: target.fatGrams,
                color: .orange
            )
        }
    }
}

struct MacroGoalRing: View {
    let label: String
    let current: Double
    let target: Double
    let color: Color
    
    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(current / target, 1.0)
    }
    
    private var percentage: Int {
        guard target > 0 else { return 0 }
        return Int((current / target) * 100)
    }
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 5)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6), value: progress)
                
                // Center text
                Text("\(percentage)%")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }
            .frame(width: 48, height: 48)
            
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            
            Text("\(Int(current))g")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
    }
}
```
</action>

<acceptance_criteria>
- File `LiiO_EatClean/Features/Progress/Components/MacroGoalRingView.swift` exists
- File contains `struct MacroGoalRingsRow: View`
- File contains `struct MacroGoalRing: View`
- Ring uses `Circle().trim(from: 0, to: progress)` pattern
- Ring has `.animation(.spring` for smooth animation
- Ring size is 48x48 (compact)
</acceptance_criteria>

### Task 2: Macro Trend Model & ViewModel Extension

<read_first>
- LiiO_EatClean/Features/Progress/ProgressViewModel.swift
- LiiO_EatClean/Features/Progress/Models/MacroAggregateModel.swift
</read_first>

<action>
1. Thêm vào `MacroAggregateModel.swift` struct mới cho trend:

```swift
struct MacroTrend {
    let proteinTrend: TrendDirection
    let carbsTrend: TrendDirection
    let fatTrend: TrendDirection
    
    enum TrendDirection: String {
        case up = "↑"
        case down = "↓"
        case stable = "→"
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .stable: return "arrow.right"
            }
        }
        
        var color: (protein: Color, carbs: Color, fat: Color) {
            // Context-dependent: up protein = good, up fat = caution
            return (.blue, .purple, .orange)
        }
    }
}
```

2. Thêm vào `ProgressViewModel.swift`:

```swift
var macroTrend: MacroTrend?
```

3. Trong `loadData()`, sau khi tính macroAggregate, thêm logic trend (chỉ cho 30N/3T):

```swift
// Calculate Macro Trend (30N and 3T only)
if selectedTimeRange != .week && meals.count > 7 {
    let calendar = Calendar.current
    let midPoint = calendar.date(byAdding: .day, value: -daysToSubtract / 2, to: today)!
    
    let firstHalfMeals = meals.filter { $0.date < midPoint }
    let secondHalfMeals = meals.filter { $0.date >= midPoint }
    
    func avgMacro(_ mealList: [MealModel], _ keyPath: KeyPath<MealFoodModel, Double>) -> Double {
        let total = mealList.flatMap { $0.mealFoods }.reduce(0.0) { $0 + $1[keyPath: keyPath] * $1.quantity }
        let days = max(Set(mealList.map { calendar.startOfDay(for: $0.date) }).count, 1)
        return total / Double(days)
    }
    
    func trend(_ first: Double, _ second: Double) -> MacroTrend.TrendDirection {
        let change = second - first
        let threshold = max(first * 0.1, 3.0) // 10% or 3g minimum threshold
        if change > threshold { return .up }
        if change < -threshold { return .down }
        return .stable
    }
    
    let pFirst = avgMacro(firstHalfMeals, \.proteinSnapshot)
    let pSecond = avgMacro(secondHalfMeals, \.proteinSnapshot)
    let cFirst = avgMacro(firstHalfMeals, \.carbsSnapshot)
    let cSecond = avgMacro(secondHalfMeals, \.carbsSnapshot)
    let fFirst = avgMacro(firstHalfMeals, \.fatSnapshot)
    let fSecond = avgMacro(secondHalfMeals, \.fatSnapshot)
    
    macroTrend = MacroTrend(
        proteinTrend: trend(pFirst, pSecond),
        carbsTrend: trend(cFirst, cSecond),
        fatTrend: trend(fFirst, fSecond)
    )
} else {
    macroTrend = nil
}
```
</action>

<acceptance_criteria>
- `MacroAggregateModel.swift` contains `struct MacroTrend`
- `MacroTrend` contains `enum TrendDirection` with `up`, `down`, `stable` cases
- `ProgressViewModel.swift` contains `var macroTrend: MacroTrend?`
- Trend uses first-half vs second-half comparison with 10% threshold
- Trend is nil for 7N time range (only calculated for 30N/3T)
</acceptance_criteria>

### Task 3: MacroInsightsView Component

<read_first>
- LiiO_EatClean/Features/Home/Components/DailySummaryCardView.swift (reference for insight row pattern)
- LiiO_EatClean/Features/Progress/Models/MacroAggregateModel.swift
</read_first>

<action>
Tạo file mới: `LiiO_EatClean/Features/Progress/Components/MacroInsightsView.swift`

Hiển thị insights coaching-style dựa trên data thực tế:

```swift
import SwiftUI

struct MacroInsightsView: View {
    let aggregate: MacroAggregate
    let target: MacroTarget
    let trend: MacroTrend?
    let timeRange: TimeRange
    
    private var insights: [MacroInsight] {
        var result: [MacroInsight] = []
        
        // Protein check
        let proteinGoalPct = target.proteinGrams > 0 ? (aggregate.avgDailyProtein / target.proteinGrams) * 100 : 0
        if proteinGoalPct < 70 {
            result.append(MacroInsight(icon: "🔴", message: "Protein thấp (\(Int(proteinGoalPct))% mục tiêu)", suggestion: "Tăng thịt, cá, trứng, đậu phụ trong bữa ăn"))
        } else if proteinGoalPct < 90 {
            result.append(MacroInsight(icon: "🟡", message: "Protein hơi thấp (\(Int(proteinGoalPct))% mục tiêu)", suggestion: "Thêm 1 phần protein mỗi bữa chính"))
        } else if proteinGoalPct >= 95 {
            result.append(MacroInsight(icon: "🟢", message: "Protein đạt mục tiêu (\(Int(proteinGoalPct))%)", suggestion: "Tiếp tục duy trì nhé!"))
        }
        
        // Fat check
        let fatGoalPct = target.fatGrams > 0 ? (aggregate.avgDailyFat / target.fatGrams) * 100 : 0
        if fatGoalPct > 130 {
            result.append(MacroInsight(icon: "🔴", message: "Chất béo vượt mục tiêu (\(Int(fatGoalPct))%)", suggestion: "Giảm đồ chiên, chuyển sang luộc/hấp"))
        } else if fatGoalPct > 110 {
            result.append(MacroInsight(icon: "🟡", message: "Chất béo hơi cao (\(Int(fatGoalPct))% mục tiêu)", suggestion: "Ưu tiên nấu ít dầu mỡ hơn"))
        } else {
            result.append(MacroInsight(icon: "🟢", message: "Chất béo ổn định (\(Int(fatGoalPct))%)", suggestion: "Cân bằng tốt!"))
        }
        
        // Trend insights (only for 30N/3T)
        if let trend = trend {
            if trend.proteinTrend == .up {
                result.append(MacroInsight(icon: "📈", message: "Protein đang tăng", suggestion: "Xu hướng tốt, tiếp tục phát huy!"))
            } else if trend.proteinTrend == .down {
                result.append(MacroInsight(icon: "📉", message: "Protein đang giảm", suggestion: "Cần chú ý bổ sung thêm protein"))
            }
            
            if trend.fatTrend == .up {
                result.append(MacroInsight(icon: "📈", message: "Chất béo đang tăng", suggestion: "Kiểm tra lại lượng dầu mỡ trong bữa ăn"))
            }
        }
        
        return result
    }
    
    var body: some View {
        if !insights.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text("Nhận xét")
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                }
                
                ForEach(Array(insights.prefix(3).enumerated()), id: \.offset) { _, insight in
                    HStack(alignment: .top, spacing: 8) {
                        Text(insight.icon)
                            .font(.caption)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(insight.message)
                                .font(.caption)
                                .fontWeight(.medium)
                            Text(insight.suggestion)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }
}

private struct MacroInsight {
    let icon: String
    let message: String
    let suggestion: String
}
```
</action>

<acceptance_criteria>
- File `LiiO_EatClean/Features/Progress/Components/MacroInsightsView.swift` exists
- File contains `struct MacroInsightsView: View`
- Insights check protein goal (< 70% → red, < 90% → yellow, >= 95% → green)
- Insights check fat goal (> 130% → red, > 110% → yellow)
- Trend insights only shown when `trend` is non-nil (30N/3T only)
- Maximum 3 insights shown (`.prefix(3)`)
- Vietnamese text for all messages
</acceptance_criteria>

### Task 4: Integrate Goal Rings, Trends & Insights into MacroDashboardView

<read_first>
- LiiO_EatClean/Features/Progress/Components/MacroDashboardView.swift
- LiiO_EatClean/Features/Progress/Components/MacroGoalRingView.swift
- LiiO_EatClean/Features/Progress/Components/MacroInsightsView.swift
- LiiO_EatClean/Features/Progress/ProgressTabView.swift
</read_first>

<action>
1. Chỉnh sửa `MacroDashboardView.swift` — thêm properties và sections:

Thêm `trend` property:
```swift
let trend: MacroTrend?
```

Trong body VStack, sau Macro Bars section, thêm:

```swift
// Divider
Divider()
    .padding(.vertical, 4)

// Goal Rings
MacroGoalRingsRow(aggregate: aggregate, target: target)

// Trend badges (30N/3T only)
if let trend = trend {
    HStack(spacing: 16) {
        TrendBadge(label: "P", direction: trend.proteinTrend, color: .blue)
        TrendBadge(label: "C", direction: trend.carbsTrend, color: .purple)
        TrendBadge(label: "F", direction: trend.fatTrend, color: .orange)
    }
    .frame(maxWidth: .infinity)
    .padding(.top, 4)
}
```

2. Thêm `TrendBadge` component vào cuối file:

```swift
struct TrendBadge: View {
    let label: String
    let direction: MacroTrend.TrendDirection
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption2.bold())
                .foregroundColor(color)
            Image(systemName: direction.icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(color)
            Text(direction.rawValue)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}
```

3. Cập nhật `ProgressTabView.swift` — truyền thêm `trend` parameter:

```swift
MacroDashboardView(
    aggregate: aggregate,
    target: target,
    timeRange: viewModel.selectedTimeRange,
    trend: viewModel.macroTrend
)
```

4. Thêm `MacroInsightsView` vào `ProgressTabView.swift` ngay SAU MacroDashboardView:

```swift
// Macro Insights
if viewModel.selectedTab == .calories,
   let aggregate = viewModel.macroAggregate,
   let target = viewModel.macroTarget {
    MacroInsightsView(
        aggregate: aggregate,
        target: target,
        trend: viewModel.macroTrend,
        timeRange: viewModel.selectedTimeRange
    )
    .padding(.horizontal)
}
```
</action>

<acceptance_criteria>
- `MacroDashboardView` has `let trend: MacroTrend?` property
- `MacroDashboardView` contains `MacroGoalRingsRow(`
- `MacroDashboardView` contains `TrendBadge(`
- `ProgressTabView.swift` contains `MacroInsightsView(`
- `ProgressTabView.swift` passes `trend: viewModel.macroTrend` to MacroDashboardView
- TrendBadge has colored background with `.opacity(0.1)`
- Insights section appears below dashboard, only on Calories tab
</acceptance_criteria>

## Verification

```bash
# Check all new files exist
test -f LiiO_EatClean/Features/Progress/Components/MacroGoalRingView.swift
test -f LiiO_EatClean/Features/Progress/Components/MacroInsightsView.swift

# Check integration
grep -q "MacroGoalRingsRow" LiiO_EatClean/Features/Progress/Components/MacroDashboardView.swift
grep -q "MacroInsightsView" LiiO_EatClean/Features/Progress/ProgressTabView.swift
grep -q "TrendBadge" LiiO_EatClean/Features/Progress/Components/MacroDashboardView.swift
grep -q "macroTrend" LiiO_EatClean/Features/Progress/ProgressViewModel.swift
```

## must_haves
- [ ] Goal Rings show percentage of macro target achieved (compact 48x48 rings)
- [ ] Trend indicators work for 30N/3T (first-half vs second-half comparison)
- [ ] Trend is hidden for 7N time range
- [ ] Coaching insights use Vietnamese text with emoji severity markers
- [ ] Insights limited to 3 max per view
- [ ] Full layout: Chart → Macro Bars → Goal Rings → Trends → Insights
- [ ] All components respect the design principle: compact, scanable, coach-feel
