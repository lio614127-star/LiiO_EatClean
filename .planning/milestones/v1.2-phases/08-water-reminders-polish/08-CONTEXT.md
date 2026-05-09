# Phase 8: Water Tracking + Smart Reminders + Polish — Context

**Gathered:** 2026-04-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Final MVP phase. Add water intake tracking with quick-log buttons on Home, interval-based smart reminders via Local Notifications, and micro-animation polish across the entire app to elevate it from "tracker" to "daily health dashboard".

</domain>

<decisions>
## Implementation Decisions

### Water Logging UX
- **D-01:** Quick-tap buttons on Home Dashboard: A row of `+100ml`, `+250ml`, `+500ml` buttons directly on the Home screen. Each tap instantly adds to today's water total with no popups, no modals. Water logging must be 1-tap.

### Water Visualization
- **D-02:** Integrated into Home Dashboard: A progress bar (or circular indicator) placed directly below the calorie ring on Home. User sees both Calories and Water in a single glance — forming a complete "daily control center".

### Reminder Strategy
- **D-03:** Interval-based smart reminders: User configures Start time (default 8:00), End time (default 20:00), and Interval (default 2h). App calculates and schedules Local Notifications at each interval point using `UNUserNotificationCenter`. More flexible than fixed times, and still straightforward to implement.

### Polish Scope
- **D-04:** Animation + Micro-interactions (targeted, not excessive):
  1. Water log: progress bar "fill" animation + light haptic feedback.
  2. Add meal: item fade+slide into MealCard, cart bump animation.
  3. Calorie ring: sweep animation on value update.
  4. Empty states: ensure all screens have graceful empty states.
  5. Edge case review: no crashes on empty data, first-use scenarios.

</decisions>

<canonical_refs>
## Canonical References

### Requirements
- `.planning/REQUIREMENTS.md` — WATR-01, WATR-02, RMND-01, RMND-02

### Prior Context
- Phase 3 (Home Dashboard) — `HomeView.swift`, `HomeViewModel.swift`
- Phase 6 (Progress) — `ProgressTabView.swift` for chart patterns

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `HomeView.swift` — Will be extended with WaterCard section and quick-log buttons.
- `HomeViewModel.swift` — Will gain water tracking state (fetch/save daily water).
- `UserRepository` — May need a water log entity or a simple daily counter.

### New Components Needed
- `WaterCardView.swift` — Progress bar + quick buttons component.
- `ReminderService.swift` — Manages `UNUserNotificationCenter` scheduling.
- Reminder settings UI in `ProfileView` (Start/End/Interval fields).

</code_context>

<deferred>
## Deferred Ideas

- Water intake visualization in Progress tab (charts).
- Custom water container size presets.
- Integration with HealthKit for water data sync.

</deferred>

---

*Phase: 08-Water-Reminders-Polish*
*Context gathered: 2026-04-29*
