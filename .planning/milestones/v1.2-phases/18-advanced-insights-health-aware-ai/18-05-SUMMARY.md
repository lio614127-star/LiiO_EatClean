# Plan 18-05: Insight Cards UI & Health Safety Badge

## Completed Tasks
- Created `InsightCardView.swift` to display individual `DailyInsight` instances with semantic color-coding based on the 3-tier severity system (low = green, medium = orange, high = red).
- Implemented tap gestures on insight cards to navigate the user directly to the AI Coach (`selectedTab = 4`) for follow-up questions regarding the insight.
- Implemented dismiss gestures on insight cards with `.easeOut` animation, persisting the dismissed IDs in `@AppStorage` with a 3-day auto-expire cache to prevent UI clutter.
- Created `HealthSafetyBadge.swift` as a non-intrusive UI component that surfaces system-level interventions (e.g., when the AI actively replaces unsafe food items).
- Integrated `HealthSafetyBadge` into `ChatView.swift`, appending it below the AI response when `healthSafetyApplied` is triggered.
- Updated `HomeViewModel.swift` to generate insights in the background upon `loadDashboard()`, ensuring the dashboard UI doesn't block while processing 7-day data.

## Validation
- UI cards appear elegantly below the daily summary and animate away smoothly upon dismissal.
- Dismissal state persists across app launches and appropriately clears after the 3-day window.
- The `HealthSafetyBadge` renders seamlessly within the chat scroll view when memory interventions occur.
