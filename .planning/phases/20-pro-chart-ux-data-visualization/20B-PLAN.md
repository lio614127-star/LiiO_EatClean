---
wave: 2
depends_on: [20A-PLAN.md]
files_modified:
  - LiiO_EatClean/Features/Progress/Components/CalorieChartView.swift
  - LiiO_EatClean/Features/Progress/Components/WeightChartView.swift
autonomous: true
---

# Phase 20B: Chart Overhaul (Calorie + Weight)

## 1. Goal
Overhaul the visual and interaction design of `CalorieChartView` and `WeightChartView` using Swift Charts `.chartScrollableAxes`, custom `AxisMarks` for label skipping, and a cyan-to-teal gradient for the weight line.

## 2. Tasks

<task>
<read_first>
- LiiO_EatClean/Features/Progress/Components/CalorieChartView.swift
- LiiO_EatClean/Features/Progress/Components/WeightChartView.swift
- LiiO_EatClean/Features/Progress/Models/WeeklyAggregate.swift
</read_first>
<action>
1. **CalorieChartView Updates**:
   - Pass `weeklyData: [WeeklyAggregate]` into the view alongside `data`.
   - Add `.chartScrollableAxes(.horizontal)` to the `Chart`.
   - Conditionally add `.chartXVisibleDomain(length: 7 * 86400)` for `.month` and `(length: 4 * 604800)` for `.quarter`.
   - Update `.chartXAxis`:
     - If `.week`: Format date to return Vietnamese weekday ("T2", "T3"..."CN"). Use `Calendar.current.component(.weekday, from: date)`.
     - If `.month`: Use `Calendar.current.component(.day, from: date)`. Conditionally render `AxisValueLabel` ONLY if the day is in `[1, 5, 10, 15, 20, 25, 30]`.
     - If `.quarter`: Loop over `weeklyData`, label as "W\(weekNumber)".
   - Update the Target Line (`RuleMark`): Change `.foregroundStyle(.red)` to `.red.opacity(0.5)` and set `.font(.caption2)`.

2. **WeightChartView Updates**:
   - Pass `weeklyData: [WeeklyAggregate]` into the view.
   - Replace standard `LineMark` styling with `.interpolationMethod(.catmullRom)`.
   - Set `PointMark` `.symbolSize(40)` (down from 100). Remove the always-on `annotation` from `PointMark`.
   - Add an `AreaMark` underneath the `LineMark` with `.foregroundStyle(LinearGradient(colors: [.cyan, .teal], startPoint: .top, endPoint: .bottom))`.
   - Add the exact same `.chartScrollableAxes` and `.chartXAxis` smart labeling logic as implemented in `CalorieChartView`.
</action>
<acceptance_criteria>
- `CalorieChartView` uses `.chartScrollableAxes(.horizontal)`.
- `CalorieChartView` Target line is `.red.opacity(0.5)`.
- Weekday mapping specifically uses "T2", "T3", "T4", "T5", "T6", "T7", "CN".
- Month mapping only displays labels for 1, 5, 10, 15, 20, 25, 30.
- `WeightChartView` has `AreaMark` with cyan-to-teal `LinearGradient`.
- `WeightChartView` `LineMark` has `.interpolationMethod(.catmullRom)`.
- `WeightChartView` `PointMark` has `.symbolSize(40)` and no text annotation.
</acceptance_criteria>
</task>

## 3. Verification
- The chart horizontally scrolls in Month and Quarter modes.
- Labels correctly skip days in Month mode.
- The gradient area appears below the weight line.

## 4. Must Haves
- The chart must not crash if data is empty (handled implicitly by existing empty state, which we refine in Wave 3).
