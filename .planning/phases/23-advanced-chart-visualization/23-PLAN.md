---
wave: 1
depends_on: []
files_modified:
  - LiiO_EatClean/Features/Progress/ProgressViewModel.swift
  - LiiO_EatClean/Features/Progress/ProgressTabView.swift
  - LiiO_EatClean/Features/Progress/Components/CalorieChartView.swift
  - LiiO_EatClean/Features/Progress/Components/WeightChartView.swift
  - LiiO_EatClean/Features/Progress/Models/MacroAggregateModel.swift
  - LiiO_EatClean/Features/Progress/Components/CustomDateRangePickerSheet.swift
autonomous: true
---

# Phase 23: Advanced Chart Visualization & Custom Date Range - Plan

## Requirements Covered
- Phase 23 implementation from ROADMAP.md
- UI Specs & UX rules defined in 23-CONTEXT.md

## Wave 1: Date Range Picker & Smart Aggregation Foundation
This wave sets up the core data models and Custom Date Picker UI.

### Tasks
<task>
  <action>
    Modify `MacroAggregateModel.swift`.
    - Update `WeeklyAggregate` struct to include `let minCalories: Double` and `let maxCalories: Double`.
    - Add a new struct `MonthlyAggregate: Identifiable` with `id`, `startDate`, `averageCalories`, `minCalories`, `maxCalories`, `month`, `year`.
  </action>
  <read_first>
    - LiiO_EatClean/Features/Progress/Models/MacroAggregateModel.swift
  </read_first>
  <acceptance_criteria>
    - `MacroAggregateModel.swift` contains `minCalories` and `maxCalories` in `WeeklyAggregate`.
    - `MacroAggregateModel.swift` contains `MonthlyAggregate` struct.
  </acceptance_criteria>
</task>

<task>
  <action>
    Modify `ProgressViewModel.swift` to support Custom Range and Smart Aggregation.
    - Update `TimeRange` enum to include `custom(start: Date, end: Date)`.
    - Add `var periodOffset: Int = 0`.
    - Implement a computed property `currentDateRange: ClosedRange<Date>` that calculates the actual date span based on `selectedTimeRange` and `periodOffset`.
    - Refactor `loadData()` to use `currentDateRange` instead of hardcoded days subtraction.
    - Implement Smart Aggregation logic: if days <= 31 (populate `calorieData`), if 32-120 (populate `weeklyData` with calculated min/max), if >120 (populate `monthlyData`).
  </action>
  <read_first>
    - LiiO_EatClean/Features/Progress/ProgressViewModel.swift
    - LiiO_EatClean/Features/Progress/Models/MacroAggregateModel.swift
  </read_first>
  <acceptance_criteria>
    - `ProgressViewModel.swift` contains `var periodOffset: Int`.
    - `ProgressViewModel.swift` contains Smart Aggregation logic based on date range duration.
  </acceptance_criteria>
</task>

<task>
  <action>
    Create `CustomDateRangePickerSheet.swift`.
    - Implement a Bottom Sheet view presenting Quick Presets ("Hôm nay", "7 ngày", "30 ngày", "90 ngày", "Năm nay").
    - Implement "Từ ngày" and "Đến ngày" `DatePicker` components.
    - Add a Live Preview text (e.g., "31 ngày • Theo ngày").
  </action>
  <read_first>
    - LiiO_EatClean/Features/Progress/ProgressTabView.swift
  </read_first>
  <acceptance_criteria>
    - `CustomDateRangePickerSheet.swift` exists.
    - Contains presets and `DatePicker` controls.
  </acceptance_criteria>
</task>

## Wave 2: Swipe Pagination Architecture
This wave implements the Apple Health-style pagination swipe on the Progress Tab.

### Tasks
<task>
  <action>
    Modify `ProgressTabView.swift`.
    - Replace the `Picker` segmented control to show "7N", "30N", "3T", "Custom".
    - Render the dynamic text for the "Custom" tab if selected (e.g., "01/05-31/05").
    - Add a `DragGesture` to the `ZStack` containing the charts to update `viewModel.periodOffset` when swiped left/right.
    - Update the Header Date dynamically based on `viewModel.currentDateRange`.
    - Add a "Hôm nay" shortcut button that sets `periodOffset = 0` when `periodOffset < 0`.
  </action>
  <read_first>
    - LiiO_EatClean/Features/Progress/ProgressTabView.swift
  </read_first>
  <acceptance_criteria>
    - `ProgressTabView.swift` uses a `DragGesture` to modify `periodOffset`.
    - A "Hôm nay" button is conditionally displayed.
  </acceptance_criteria>
</task>

## Wave 3: Chart Visualization Enhancements
This wave applies the Min/Max overlays and smooth trend lines.

### Tasks
<task>
  <action>
    Modify `CalorieChartView.swift`.
    - Remove `.chartScrollableAxes(.horizontal)`.
    - Update X-axis logic to rely on the current data boundaries rather than hardcoded domain lengths.
    - In the weekly/monthly iterations, add a `RangeMark` bounded by `yStart: .value("Min", item.minCalories)` and `yEnd: .value("Max", item.maxCalories)` with `foregroundStyle` set to `opacity(0.15)`.
  </action>
  <read_first>
    - LiiO_EatClean/Features/Progress/Components/CalorieChartView.swift
  </read_first>
  <acceptance_criteria>
    - `CalorieChartView.swift` does not contain `.chartScrollableAxes`.
    - `CalorieChartView.swift` contains `RangeMark`.
  </acceptance_criteria>
</task>

<task>
  <action>
    Modify `WeightChartView.swift`.
    - Remove `.chartScrollableAxes(.horizontal)`.
    - Add a Trend Badge in the header (e.g., `↓ -1.2kg / 30N`) calculated from the first and last weight in the current date range.
    - Remove `PointMark`.
    - Ensure `LineMark` and `AreaMark` are rendered with `.interpolationMethod(.catmullRom)`.
  </action>
  <read_first>
    - LiiO_EatClean/Features/Progress/Components/WeightChartView.swift
  </read_first>
  <acceptance_criteria>
    - `WeightChartView.swift` does not contain `.chartScrollableAxes`.
    - `WeightChartView.swift` contains trend badge calculation logic in the header.
  </acceptance_criteria>
</task>

## Verification
- Run the app and navigate to the Progress Tab.
- Swipe left/right on the chart and verify that the `periodOffset` updates and data refreshes smoothly.
- Open the Custom Picker, select a 90-day range, and ensure the Calorie Chart displays the Min/Max `RangeMark` overlay.
- Switch to the Weight tab and confirm the presence of the smooth `AreaMark` and the inline Trend Badge at the top.
