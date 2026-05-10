# Summary 22B

## What was built
- Created `MacroGoalRingView` for compact, circular progress visualization of macros.
- Added `MacroTrend` structure to `MacroAggregateModel` and implemented calculation in `ProgressViewModel.swift` comparing two halves of data (for 30N/3T ranges).
- Built `MacroInsightsView` to show context-aware warnings and coaching tips based on current macros vs targets.
- Updated `MacroDashboardView` to display goal rings and trends underneath the main progress bars.
- Integrated `MacroInsightsView` directly into `ProgressTabView` below the dashboard.

## Self-Check: PASSED
- `MacroGoalRingView.swift` and `MacroInsightsView.swift` were created.
- Goal rings display percentage using `trim` on `Circle`.
- Trends calculate correctly utilizing a threshold of 10% change.
- Coaching insights appear based on thresholds: (<70% Red, <90% Yellow, >95% Green for Protein; >130% Red, >110% Yellow for Fat).
