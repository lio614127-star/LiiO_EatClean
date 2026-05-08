---
wave: 3
depends_on: [20B-PLAN.md]
files_modified:
  - LiiO_EatClean/Features/Progress/ProgressTabView.swift
  - LiiO_EatClean/Features/Progress/Components/CalorieChartView.swift
  - LiiO_EatClean/Features/Progress/Components/WeightChartView.swift
autonomous: true
---

# Phase 20C: Filters, Empty States & Animations

## 1. Goal
Connect the UI with the Segmented Filter ("7N | 30N | 3T"), inject smart empty states, and add smooth Apple Fitness-style animations to chart transitions.

## 2. Tasks

<task>
<read_first>
- LiiO_EatClean/Features/Progress/ProgressTabView.swift
- LiiO_EatClean/Features/Progress/Components/CalorieChartView.swift
- LiiO_EatClean/Features/Progress/Components/WeightChartView.swift
</read_first>
<action>
1. **ProgressTabView Updates**:
   - The segmented picker for `viewModel.selectedTimeRange` should already show `7N`, `30N`, `3T` because of the enum raw values updated in Wave 1. Ensure it binds correctly.
   - Pass `weeklyData: viewModel.weeklyData` into `CalorieChartView` and `WeightChartView`.
   - Apply an animation to the chart container: `.animation(.easeInOut(duration: 0.35), value: viewModel.selectedTimeRange)`.

2. **Smart Empty States in Chart Views**:
   - In `CalorieChartView` and `WeightChartView`, replace the basic `emptyState` logic.
   - Determine the number of unique data days (or weeks for `.quarter`).
   - If count is 0: Show "Chưa có dữ liệu" with the chart icon.
   - If count is > 0 but < 3 (for week/month) or < 2 (for quarter): Show "Cần thêm X ngày dữ liệu để hiển thị xu hướng" (e.g., `3 - count` days).
   - Update the UI to center this message beautifully with `.secondary` text color and the appropriate SF Symbol.
</action>
<acceptance_criteria>
- `ProgressTabView` passes `weeklyData` down to the chart views.
- The `.animation(.easeInOut(duration: 0.35), value: viewModel.selectedTimeRange)` modifier is applied to the chart content.
- Empty states calculate data length and display "Cần thêm X ngày dữ liệu để hiển thị xu hướng" when data is sparse.
</acceptance_criteria>
</task>

## 3. Verification
- Toggling between 7N, 30N, and 3T smoothly animates the chart bars/lines.
- When there's only 1 weight entry, the view tells the user "Cần thêm 2 ngày dữ liệu...".

## 4. Must Haves
- Animations must not cause layout jumping (use proper geometry or static heights if needed).
