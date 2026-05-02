# Phase 6: Progress & Weight Tracking - Context

**Gathered:** 2026-04-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Build the "Progress" tab (Analytics) focusing on visual trends for Weight and Calories over time. Users can log their daily weight and view their historical performance against their goals. It relies heavily on `Swift Charts` for clear, 2-second readability.

</domain>

<decisions>
## Implementation Decisions

### Weight Logging Flow
- **D-01:** Floating Action Button (FAB) / Modal Approach: Provide a Floating Action Button or Navigation Bar button `+ Log Weight`. Tapping it opens a Bottom Sheet (Modal) to enter weight. This keeps the chart canvas clean and uncrowded.

### Chart Layout (Tabs)
- **D-02:** Segmented Control (Pagination): The tab features a top `Segmented Control` to toggle between `[Calo | Cân nặng]`. This prevents information overload and separates input vs. output visually.

### Calorie History Visualization
- **D-03:** Total Calories (Simple Bar Chart): The calorie chart displays a single bar per day representing total caloric intake. It features a horizontal `RuleMark` representing the user's daily calorie target for immediate visual context of over/under eating. Stacked macro charts are deferred.

### Time Range Toggle
- **D-04:** Universal Time Toggle: Provide a global toggle (e.g., `Tuần | Tháng`) that affects whichever chart is currently visible. It simplifies mental load by keeping the time context unified.

### Agent's Discretion
- The exact color themes for Swift Charts, adhering to the project's #4CAF50 green and minimal Apple aesthetic.
- The UI styling of the Weight Input bottom sheet.
- How to generate dummy historical data for previewing the charts gracefully if the user has no past data.

</decisions>

<canonical_refs>
## Canonical References

### Prior Phase Context
- `.planning/phases/01-project-foundation/01-CONTEXT.md` — CoreData schema (WeightEntry, DailyLog)
- `.planning/phases/05-meal-logging/05-CONTEXT.md` — Meal data structures

### Project Context
- `.planning/REQUIREMENTS.md` — PROG-01 through PROG-04
- `.planning/ROADMAP.md` — Phase 6 success criteria

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `UserRepository` (Phase 1 Stub) — Needs to be fully implemented for `saveWeightEntry`, `fetchWeightEntries`, and optionally `DailyLog` historical queries (if not aggregating `MealModel` directly).
- `User` and `WeightEntry` CoreData entities already defined in the schema.

### Integration Points
- Add a new root tab to `MainTabView` (or replace a placeholder tab) for `ProgressView`.

</code_context>

<specifics>
## Specific Ideas

- **The Layout:** 
  `[ Segmented: Calo | Cân nặng ]`
  `[ Biểu đồ chính ]`
  `[ Toggle: Tuần | Tháng ]`
  `[ (Floating button) + Log Weight ]`
- **Goal Mark:** The Calorie chart must use `RuleMark` for the daily calorie goal.
- **Empty States:** Ensure charts have a clean "No Data" state if there are no logs for the selected period.

</specifics>

<deferred>
## Deferred Ideas

- Stacked Macro charts (Protein/Carbs/Fat breakdown over time).
- Exporting data to CSV or HealthKit integration.

</deferred>

---

*Phase: 06-Progress*
*Context gathered: 2026-04-29*
