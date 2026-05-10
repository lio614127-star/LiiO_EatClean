# Phase 23: Advanced Chart Visualization & Custom Date Range - Research

## Context and Goal
The goal is to upgrade the Progress Tab charts to Apple Health standards, adding Custom Date Range Picker, Smart Aggregation (Daily/Weekly/Monthly) with Min/Max Overlays for Calories, and Smooth Trend lines for Weight.

## Files Examined
- `LiiO_EatClean/Features/Progress/ProgressViewModel.swift`
- `LiiO_EatClean/Features/Progress/ProgressTabView.swift`
- `LiiO_EatClean/Features/Progress/Components/CalorieChartView.swift`
- `LiiO_EatClean/Features/Progress/Components/WeightChartView.swift`
- `.planning/phases/23-advanced-chart-visualization/23-CONTEXT.md`

## Architecture Analysis
1. **Picker and Date Range UI**: Currently `TimeRange` is an enum (`week, month, quarter`). We need to switch this to support `Custom`. A `BottomSheet` will present Quick Presets and `From/To` pickers. The segment control needs to be updated.
2. **ViewModel State**: `ProgressViewModel` fetches data based on `selectedTimeRange`. It needs a `periodOffset` (Int) to manage Swipe Pagination, and it needs to compute the actual start/end dates.
3. **Smart Aggregation**:
   - `<= 31 days`: Return daily records.
   - `32-120 days`: Return `WeeklyAggregate` (adding min/max fields).
   - `> 120 days`: Return `MonthlyAggregate` (need to create this).
4. **Data Models**: `WeeklyAggregate` needs to be expanded to store `minCalories` and `maxCalories` along with `averageCalories` and `startDate`.
5. **Charts**:
   - Remove `.chartScrollableAxes(.horizontal)`.
   - Implement swipe gesture handling at the view level (e.g., `DragGesture`) to update `periodOffset` in `ProgressViewModel`.
   - In `CalorieChartView`, conditionally render `RangeMark` behind `BarMark`.
   - In `WeightChartView`, add the Trend badge to the Header, remove PointMark, ensure `AreaMark` and `LineMark` use `.catmullRom`.

## Validation Architecture
- **Swipe Pagination**: UI interaction smoothly loads the next/previous time period.
- **Aggregation Logic**: The correct level of aggregation is selected based on the number of days in the range.
- **Visuals**: RangeMarks are visible for aggregated calories. Smooth lines for weight.

## RESEARCH COMPLETE
