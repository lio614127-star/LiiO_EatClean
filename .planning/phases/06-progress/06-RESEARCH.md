# Phase 6: Progress & Weight Tracking — Research

**Gathered:** 2026-04-29

## 1. Repository Enhancements
To draw charts across time, we need to fetch data over date ranges.
*   **Weight Data:** `UserRepository.swift` currently stubs `fetchWeightEntries()` and `saveWeightEntry()`.
    *   `fetchWeightEntries()` should fetch entries sorted by date ascending.
    *   `saveWeightEntry(_ entry:)` should save a new `WeightEntry`. Additionally, when a user logs a new weight, it makes sense to update the `User.weight` property to reflect their latest current weight (which might be used elsewhere).
*   **Calorie Data:** `MealRepository.swift` only has `fetchMeals(by date: Date)`.
    *   We need `fetchMeals(from startDate: Date, to endDate: Date)` to get meals for the past 7 or 30 days.
    *   Once fetched, the ViewModel will group these meals by day to calculate the `totalCalories` per day for the Bar Chart.

## 2. Swift Charts Implementation
Swift Charts (available iOS 16+) is perfect for this.
*   **Calorie Chart:**
    *   Requires data in the form of `(date: Date, calories: Double)`.
    *   `BarMark(x: .value("Date", item.date, unit: .day), y: .value("Calories", item.calories))`
    *   Goal line: `RuleMark(y: .value("Mục tiêu", dailyTarget))` with `.lineStyle(StrokeStyle(dash: [5]))` and `.foregroundStyle(.red)`.
*   **Weight Chart:**
    *   Requires `WeightEntryModel` data.
    *   `LineMark(x: .value("Date", entry.date, unit: .day), y: .value("Weight", entry.weight))`
    *   `PointMark` overlaid on the `LineMark` to make data points clear.
    *   Y-Axis scaling: Weight charts look terrible if the Y-axis starts at 0. We should configure `.chartYScale(domain: minWeight...maxWeight)` with some padding.

## 3. State Management (ProgressViewModel)
A dedicated `ProgressViewModel` will manage:
*   `enum TabSelection { case calories, weight }`
*   `enum TimeRange { case week, month }`
*   `var weightData: [WeightEntryModel]`
*   `var calorieData: [(date: Date, calories: Double)]`
*   Re-fetching data when `TimeRange` changes.
*   Handling the `saveWeight` action and refreshing the data.

## 4. UI Layout Details
*   **Main View (`ProgressView`)**:
    *   Top: `Picker` for TabSelection.
    *   Middle: The Chart (conditionally rendering `CalorieChartView` or `WeightChartView`).
    *   Below Chart: `Picker` for TimeRange.
    *   Overlay (ZStack): Floating Action Button (FAB) at the bottom right.
*   **Bottom Sheet (`LogWeightSheet`)**:
    *   Triggered by the FAB.
    *   Contains a `TextField` for decimal input and a `Button` to save.
