---
wave: 1
depends_on: ["05-PLAN"]
files_modified: ["LiiO_EatClean/Data/Protocols/MealRepositoryProtocol.swift", "LiiO_EatClean/Data/Repositories/MealRepository.swift", "LiiO_EatClean/Data/Protocols/UserRepositoryProtocol.swift", "LiiO_EatClean/Data/Repositories/UserRepository.swift", "LiiO_EatClean/Features/Progress/ProgressViewModel.swift", "LiiO_EatClean/Features/Progress/ProgressView.swift", "LiiO_EatClean/Features/Progress/Components/CalorieChartView.swift", "LiiO_EatClean/Features/Progress/Components/WeightChartView.swift", "LiiO_EatClean/LiiO_EatCleanApp.swift"]
autonomous: true
---

# Phase 6: Progress & Weight Tracking

This phase implements the "Progress" tab. It introduces Swift Charts to visualize total caloric intake against daily targets, and tracks weight over time. It includes a unified UI with segmented controls for navigation, a time toggle, and a clean Floating Action Button for logging weight.

## Proposed Changes

### Data Layer Enhancements

#### [MODIFY] [MealRepositoryProtocol.swift](file:///c:/Users/K2HPC/OneDrive/Desktop/CodeToolLiiO/LiiO_EatClean/LiiO_EatClean/Data/Protocols/MealRepositoryProtocol.swift)
Add `func fetchMeals(from startDate: Date, to endDate: Date) async throws -> [MealModel]`.

#### [MODIFY] [MealRepository.swift](file:///c:/Users/K2HPC/OneDrive/Desktop/CodeToolLiiO/LiiO_EatClean/LiiO_EatClean/Data/Repositories/MealRepository.swift)
Implement `fetchMeals(from:to:)` using an `NSPredicate` bounding the date range.

#### [MODIFY] [UserRepository.swift](file:///c:/Users/K2HPC/OneDrive/Desktop/CodeToolLiiO/LiiO_EatClean/LiiO_EatClean/Data/Repositories/UserRepository.swift)
Implement `fetchWeightEntries()` to fetch all `WeightEntry` sorted by date ascending.
Implement `saveWeightEntry(_ entry: WeightEntryModel)` to create a new `WeightEntry` and automatically update the associated `User.weight` field so the profile stays in sync.

---
### Presentation Layer (Progress Feature)

#### [NEW] [ProgressViewModel.swift](file:///c:/Users/K2HPC/OneDrive/Desktop/CodeToolLiiO/LiiO_EatClean/LiiO_EatClean/Features/Progress/ProgressViewModel.swift)
Create a ViewModel to handle state for the Progress tab:
- Enums: `TabSelection` (calories, weight), `TimeRange` (week, month).
- State: `selectedTab`, `selectedTimeRange`, `weightData`, `calorieData` (array of `(Date, Double)`), `dailyTarget`.
- Fetch logic that calculates `startDate` based on the selected `TimeRange`, calls the repositories, and maps `MealModels` into aggregated daily calorie totals.

#### [NEW] [CalorieChartView.swift](file:///c:/Users/K2HPC/OneDrive/Desktop/CodeToolLiiO/LiiO_EatClean/LiiO_EatClean/Features/Progress/Components/CalorieChartView.swift)
Create a sub-view utilizing `import Charts`:
- Iterates over `calorieData`.
- Uses `BarMark` for daily calories.
- Adds a horizontal `RuleMark` colored red with a dashed line to indicate the `dailyTarget`.

#### [NEW] [WeightChartView.swift](file:///c:/Users/K2HPC/OneDrive/Desktop/CodeToolLiiO/LiiO_EatClean/LiiO_EatClean/Features/Progress/Components/WeightChartView.swift)
Create a sub-view utilizing `import Charts`:
- Iterates over `weightData`.
- Uses `LineMark` and `PointMark`.
- Automatically scales the Y-axis (`.chartYScale(domain:)`) using the min and max weight values from the data set with slight padding, avoiding a chart that starts at 0.

#### [NEW] [ProgressView.swift](file:///c:/Users/K2HPC/OneDrive/Desktop/CodeToolLiiO/LiiO_EatClean/LiiO_EatClean/Features/Progress/ProgressView.swift)
Assemble the UI according to D-01/D-02/D-04:
- A `Picker` (segmented) at the top for Tab Selection.
- A central area displaying either `CalorieChartView` or `WeightChartView`.
- A `Picker` (segmented) below the chart for Time Range (Tuần / Tháng).
- A ZStack containing a Floating Action Button in the bottom right corner: `Image(systemName: "plus")` styled as a circle.
- Tapping the FAB sets `isShowingLogWeight = true`, triggering a `.sheet` with a simple input for entering a decimal weight.

---
### App Integration

#### [MODIFY] [MainTabView.swift](file:///c:/Users/K2HPC/OneDrive/Desktop/CodeToolLiiO/LiiO_EatClean/LiiO_EatClean/MainTabView.swift) (Assumption/To Create)
Ensure `ProgressView()` is registered as the second tab.

## Verification Plan

### Automated Tests
- Build verification: ensure `import Charts` compiles successfully on iOS 17+.

### Manual Verification
- Deploy to simulator.
- Navigate to the Progress tab.
- Add a new weight entry via the FAB -> verify the Line Chart updates immediately and the Y-axis scales correctly.
- Add a meal via the Dashboard -> navigate to Progress tab -> verify the Bar chart shows the updated total for today.
- Toggle between Week and Month views -> verify X-axis distribution changes.
