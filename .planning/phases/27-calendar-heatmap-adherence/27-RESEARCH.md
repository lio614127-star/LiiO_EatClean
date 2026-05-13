# Phase 27: calendar-heatmap-adherence - Research

## Objective
Research the technical implementation for a high-performance Calendar Heatmap visualizing meal adherence scores.

## Domain Research

### 1. Data Layer: DailyAdherenceSnapshot
To ensure smooth scrolling in the calendar view, we must avoid real-time calculation of adherence scores for every visible day. We will implement a caching layer in CoreData.

**Entity: `DailyAdherenceSnapshot`**
- `id`: UUID (Primary Key)
- `date`: Date (Normalized to start of day, indexed)
- `adherenceScore`: Double (0-100)
- `totalCalories`: Double
- `totalProtein`: Double
- `totalCarbs`: Double
- `totalFat`: Double
- `targetCalories`: Double
- `targetProtein`: Double
- `targetCarbs`: Double
- `targetFat`: Double
- `mealCount`: Int16
- `plannedMealCount`: Int16
- `dataVersion`: Int16 (Increment this when scoring logic changes to trigger a rebuild)

### 2. Service Layer: Snapshot Management
We need a `DailyAdherenceSnapshotService` to manage the lifecycle of these snapshots.

**Event-Driven Updates:**
- Observe `mealLogDidUpdate` (existing) and a new `mealPlanDidUpdate` notification.
- When an update occurs, recalculate the snapshot for the affected date(s).
- Use `MealAdherenceCalculator.shared.calculate()` for the scoring logic.

**Lazy Loading:**
- When the Heatmap displays a month, check for missing snapshots in CoreData.
- If missing, calculate and save them in a background task to keep the UI responsive.

### 3. UI Layer: Calendar Heatmap
We will build a custom SwiftUI calendar instead of using `DatePicker` to allow full control over cell styling.

**Implementation Details:**
- **Grid Structure**: `LazyVGrid` with 7 columns.
- **Color Mapping**:
    - Excellent (>=90): `.mint`
    - Good (75-89): `.green`
    - Fair (60-74): `.yellow`
    - Poor (40-59): `.orange`
    - Critical (<40): `.red`
    - No Data: `.gray.opacity(0.2)`
- **Interactions**:
    - Tap on cell: Opens a `.medium` detent sheet with `DailyAdherenceSummaryView`.
    - Deep Link: "Xem chi tiết Journal" button updates `selectedTab` to 1 and `selectedDate` in `MealsViewModel`.

## Verification Strategy

### 1. Automated Tests
- `DailyAdherenceSnapshotServiceTests`: Verify that snapshots are correctly generated, updated, and persisted.
- `MealAdherenceCalculatorTests`: (Existing/Update) Ensure scoring logic remains consistent with snapshot requirements.

### 2. Manual UAT
- Verify heatmap colors match the calculated scores.
- Verify smooth scrolling across multiple months.
- Verify deep-linking to the correct date in the Journal.

## Technical Dependencies
- CoreData (Entity migration/addition)
- `MealAdherenceCalculator`
- `MealsViewModel` refactor for date support.
