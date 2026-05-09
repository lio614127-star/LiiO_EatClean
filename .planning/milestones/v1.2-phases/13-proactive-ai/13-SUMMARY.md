# Phase 13: Proactive AI — Daily Summary & Memory Insights

**Date:** 2026-05-05
**Phase:** 13
**Status:** Executed

## Features Implemented

1. **Insight Detector (`InsightDetector.swift`)**:
   - Detects 4 core patterns using a mixed data window (3-day vs 7-day).
   - `P1`: Low protein detection (<30g) over 3 days (warning) or 5/7 days (alert).
   - `P3`: Skipped breakfast detection over 4/7 days.
   - `P5`: Calorie overrun detection for 3 consecutive days.
   - `P6`: Low water intake (<50% target) on average over 7 days.

2. **Daily Summary Service (`DailySummaryService.swift`)**:
   - Aggregates daily nutritional data (calories, macros, meal breakdown).
   - Combines aggregated data with detected insights and feeds it to the AI prompt (`ContextStrategy.dailySummary`).
   - Parses the JSON response from the AI (`aiComment` and `aiSuggestion`) and prepares the `DailySummary` model for the UI.

3. **Daily Summary UI (`DailySummaryCardView.swift`)**:
   - **Compact mode**: shows calories vs target, and a pass/fail icon.
   - **Expanded mode**: displays horizontal mini progress bars for macros, detected warnings/alerts from the Insight Detector, and the AI's personalized comment and suggestion.
   - Auto-expands gracefully using `.spring` animation when insights are present.
   - Integrated into `HomeView` directly below the Streak Card.

4. **Notification Scheduling (`ReminderService.swift`)**:
   - Added `scheduleDailySummaryReminder` for a 20:00 recurring push notification.
   - Integrated with user profile settings via `ProfileViewModel`.

## Verification
- Code successfully builds on iOS Simulator using Xcode build tools.
- Successfully handles JSON decoding of the AI response by extracting the markdown JSON block explicitly.
- Safely calculates daily calorie logic and handles empty data gracefully (no insights generated if meals are empty).

## Future Work (Phase 14+)
- **Phase 14**: End of the week review (Weekly Summary Report).
- **Refinement**: Add deep links into the push notifications to open the Home tab directly.
