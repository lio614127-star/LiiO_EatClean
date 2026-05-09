---
wave: 1
depends_on: []
files_modified:
  - LiiO_EatClean/Features/Progress/ProgressViewModel.swift
  - LiiO_EatClean/Features/Progress/Models/WeeklyAggregate.swift
autonomous: true
---

# Phase 20A: TimeRange Expansion & WeeklyAggregate Logic

## 1. Goal
Expand the `TimeRange` enum to include a 3-month (quarter) option and implement the 90-day fetch and weekly aggregation logic in `ProgressViewModel`.

## 2. Tasks

<task>
<read_first>
- LiiO_EatClean/Features/Progress/ProgressViewModel.swift
</read_first>
<action>
1. Create a new model file `LiiO_EatClean/Features/Progress/Models/WeeklyAggregate.swift` (create directory if needed).
2. Define the struct:
```swift
import Foundation

struct WeeklyAggregate: Identifiable {
    let id = UUID()
    let weekNumber: Int
    let averageCalories: Double
    let lastWeight: Double?
    let startDate: Date
    let endDate: Date
}
```
3. In `ProgressViewModel.swift`, modify the `TimeRange` enum:
```swift
enum TimeRange: String, CaseIterable {
    case week = "7N"
    case month = "30N"
    case quarter = "3T"
}
```
4. Add `var weeklyData: [WeeklyAggregate] = []` to `ProgressViewModel`.
5. Update `loadData()` to handle `.quarter`:
   - If `selectedTimeRange == .quarter`, set `daysToSubtract = 89` (90 days total).
   - After fetching `meals` and `allWeights`, if `.quarter`, generate `weeklyData`.
   - Calculate chunks of 7 days starting from `startDate`.
   - For each 7-day chunk, filter meals within that window, calculate total calories, divide by 7 to get `averageCalories`.
   - Filter `allWeights` for that window, and take the last element for `lastWeight`.
   - Append to `weeklyData` with `weekNumber` (1 to 12).
</action>
<acceptance_criteria>
- `WeeklyAggregate.swift` exists and contains the defined fields.
- `TimeRange` enum has `quarter` case with raw value "3T".
- `ProgressViewModel` has `weeklyData` property.
- `loadData()` calculates `weeklyData` correctly when `.quarter` is selected.
</acceptance_criteria>
</task>

## 3. Verification
- `swift build` or Xcode build succeeds.
- Selecting `3T` in the UI does not crash and populates `weeklyData` without out-of-bounds errors.

## 4. Must Haves
- Data aggregation correctly handles missing meals (averages over 7 days regardless of log count, or 0 if no meals).
