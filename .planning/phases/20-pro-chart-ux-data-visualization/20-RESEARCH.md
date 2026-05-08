# Phase 20: Pro Chart UX & Data Visualization - Research

## Context
Phase 20 upgrades the charts in `ProgressTabView` to match Apple Health's production-grade UI, introducing smart label skipping, weekly aggregations for a new 90-day (3T) mode, scrollable charts, and enhanced visual polish like teal/cyan gradients for weight.

## Technical Architecture & Constraints
1.  **Swift Charts limitations**: `chartScrollableAxes(.horizontal)` works beautifully but requires a predefined `chartXVisibleDomain` to constrain the visible viewport so the user can scroll. If we want 7 days to fit without scrolling but 30 days to scroll showing ~7-10 days at a time, we must conditionally apply `.chartXVisibleDomain`.
2.  **Date Axis Grouping**: In Swift Charts, `AxisMarks(values: .stride(by: ...))` is typically used. However, the requirement specifically requests "1 5 10 15 20 25 30" label skipping. This means we might need a custom array of Dates or a custom conditional block inside `AxisMarks` to determine if a label should be shown.
3.  **Weekly Aggregation**: For 3T mode, we need 12 weeks of data. We can calculate this by breaking the 90 days into 7-day chunks, calculating the average for calories and taking the most recent entry for weight.
4.  **Gradient AreaMark**: For `WeightChartView`, we will add an `AreaMark` overlaid with a `LineMark`. The gradient requires `LinearGradient` mapped to the `AreaMark` foreground style.

## Key Integration Points
*   **ProgressViewModel**: Needs `TimeRange` updated to include `.quarter` ("3T"). The fetch logic needs to pull 90 days instead of 30, and compute `WeeklyAggregate` items.
*   **ProgressTabView**: Update the time range `Picker` and inject the right data format into the sub-views. Handle `.quarter` mode specifically.
*   **CalorieChartView & WeightChartView**: Implement the `chartScrollableAxes` modifier, update `chartXAxis` with the smart Vietnamese labels and skipping logic. Implement Empty State handling directly within these views.

## Edge Cases
*   **Empty States**: The chart must not crash when the data array is empty. It should display the custom empty state view. "Cần thêm X ngày..." requires calculating the number of unique days of data.
*   **Scroll Viewport**: The `chartXVisibleDomain` might snap awkwardly if the data array length is smaller than the domain length.

## Validation Strategy (Nyquist)
- **UI Consistency**: Verify the gradient is applied and point marks are shrunk to size 40.
- **Scroll Behavior**: Verify that dragging horizontally works in 30N and 3T modes.
- **Data Integrity**: Ensure the weekly aggregation math correctly averages calories and selects the latest weight, avoiding index-out-of-bounds.
