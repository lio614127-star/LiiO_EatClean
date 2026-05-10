# Project State: LiiO EatClean

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-09)

**Core value:** User có thể log bữa ăn và xem calories hôm nay trong vòng 5 giây
**Current focus:** Milestone v1.3 Trợ lý Dinh dưỡng Toàn năng & Tiện lợi

## Current Milestone

**Milestone: v1.3 Trợ lý Dinh dưỡng Toàn năng & Tiện lợi**

- Turbo Daily Planning (All-in-one Prompting)
- Smart Unit Recognition (chén, dĩa, gram...)
- Recipe Detail View (Ingredient breakdown)
- AI Cooking Coach Integration (Deep-link to Chat)
- Magic Swap Feature (Interactive Plan Editor)
- Anti-Repeat & Vietnamese Priority Logic
- HealthKit Integration (Basic sync)
- Macro Tracking Dashboard

## Current Position

Phase: 21
Status: Executed
Last activity: 2026-05-09 — Phase 21 implemented (Turbo Planning, Smart Units, Magic Swap)
- Current Phase: Phase 21 (Completed)
- Current Task: Finalized Interactive AI Nutrition Integration
- Progress: 100% of Phase 21 complete

## Memory

### Decisions
- Swift + SwiftUI native iOS (no cross-platform)
- CoreData local-first with Repository pattern
- Hybrid food database (local Vietnamese JSON + CalorieNinjas API)
- AI from v1 with multi API key rotation (OpenAI/Gemini)
- Design: Apple-style, #4CAF50 green, SF Pro, bo góc 16-24px
- **Macros (protein/carbs/fat) elevated to core feature** (not deferred)
- MealFood snapshot pattern for historical accuracy
- 3 domain repos: MealRepository, FoodRepository, UserRepository
- Hybrid folder structure: Features/ + Data/ + Core/
- **Suggestion vs Eaten Logic**: AI suggestions are stored but not counted toward calories until user ticks "eaten" in the new Interactive Meal Detail Sheet.
- **AI Data Normalization**: Multi-portion AI suggestions (e.g. 3 bananas) are divided into a single-unit base food item + a quantity multiplier to ensure reusable suggestions.
- **Calorie Calculation Safety**: Minimum daily calories enforced by gender (Men: 1500 kcal, Women: 1200 kcal) using Mifflin-St Jeor + 1.55 activity factor.
- **Reactive Profile**: Automatic calorie target recalculation triggered by any change in age, weight, height, or goal type in the Profile screen.
- **Chart UX**: Applied X-axis padding to weight charts and forced Y-axis 0-minimum on calorie charts to prevent label clipping and negative scale artifacts.
- **Data Management**: "Danger Zone" implemented in Profile to allow users to completely purge all CoreData records (Meals, Weights, Logs) and reset app state.
- **Water Management**: Added "Undo/Reset" capability for water intake to handle over-logging errors.
- **Custom Branding**: Integrated `avatar_tool` as the primary visual identity. Replaced text-based Splash Screen with a styled image logo and generated a full suite of optimized App Icons (40px to 1024px) for production-grade display.
- **AI Meal Planning Flow**: Decoupled planning from tracking via a full-screen sheet. Implemented adaptive context (History + Insights) to prevent repetitive suggestions and address nutritional gaps.
- **Proportional Calorie Trimming**: Implemented app-side logic to scale AI-suggested meal portions proportionally to fit within ±5% of the user's daily calorie target.
- **Advanced Chart Refinement**: Implemented Apple Health-style chart axes with smart label skipping (1, 5, 10...) for 30N/3T views, month/year anchors (e.g., 5/26), and fixed chart height (220px) to prevent UI jumping.
- **Persistent Summary UX**: The Daily Summary Card expansion state is now persistent via `@AppStorage`. Auto-expansion on new insights has been removed to respect the user's manual preference.

### Learnings
- AI `mealType` mapping must strictly match UI categories ("Bữa phụ" -> "Ăn vặt") to prevent ghost data.
- User portions need normalization (divided by servingSize) to handle manual quantity changes correctly later.
- Ephemeral state (UserDefaults for isEaten) is a reliable way to add properties without complex CoreData migrations mid-development.
- Context injection strategy: Base memory is reliable, but history/insights should be conditional to avoid token bloat and "hallucinated" patterns for new users.

### Roadmap Evolution
- Phase 9 added: AI Nutritionist Chatbox (Expert advice, habit-aware, app context)
- Phase 10 added: AI-Powered Meals Tab — Smart Suggestions, Memory & Actionable AI
- Phase 14 added: Dedicated AI Meal Planning Engine (Decoupled UI, Adaptive Context, Proportional Trimming)
- Phase 20 added: Pro Chart UX & Data Visualization (Apple Health-style axes, smart label skipping, scrollable month, line+gradient weight chart, pro segmented filters)
- **Phase 21 added: Next-Gen Nutrition & AI Planning Update (Turbo Daily Planning, Smart Units, Recipe Detail, Cooking Assistant, Interactive Swap)**

## Session Log

| Date | Stopped At | Resume |
|------|-----------|--------|
| 2026-05-09 | Milestone 1.2 completed | `milestones/v1.2-ROADMAP.md` |
| 2026-05-09 | Milestone 1.3 started | Phase 21: Next-Gen Nutrition |
| 2026-05-07 | Phase 15 context gathered | `.planning/phases/15-ai-memory-hub-personality/15-CONTEXT.md` |
| 2026-04-29 | Phase 1 context gathered | `.planning/phases/01-project-foundation/01-CONTEXT.md` |
| 2026-04-29 | Phase 1 UI-SPEC approved | `.planning/phases/01-project-foundation/01-UI-SPEC.md` |
| 2026-04-29 | Phase 1 planned | `.planning/phases/01-project-foundation/01-PLAN.md` |
| 2026-04-29 | Phase 1 executed | `.planning/phases/01-project-foundation/01-SUMMARY.md` |
| 2026-04-29 | Phase 2 context gathered | `.planning/phases/02-splash-onboarding/02-CONTEXT.md` |
| 2026-04-29 | Phase 2 planned | `.planning/phases/02-splash-onboarding/02-PLAN.md` |
| 2026-04-29 | Phase 2 executed | Splash + Onboarding + Goal Setup implemented |
| 2026-04-29 | Phase 3 context gathered | `.planning/phases/03-home-dashboard/03-CONTEXT.md` |
| 2026-04-29 | Phase 3 planned | `.planning/phases/03-home-dashboard/03-PLAN.md` |
| 2026-04-29 | Phase 3 executed | `.planning/phases/03-home-dashboard/03-SUMMARY.md` |
| 2026-04-29 | Phase 4 context gathered | `.planning/phases/04-food-database/04-CONTEXT.md` |
| 2026-04-29 | Phase 4 planned | `.planning/phases/04-food-database/04-PLAN.md` |
| 2026-04-29 | Phase 4 executed | `.planning/phases/04-food-database/04-SUMMARY.md` |
| 2026-04-29 | Phase 5 context gathered | `.planning/phases/05-meal-logging/05-CONTEXT.md` |
| 2026-04-29 | Phase 5 planned | `.planning/phases/05-meal-logging/05-PLAN.md` |
| 2026-04-29 | Phase 5 executed | `.planning/phases/05-meal-logging/05-SUMMARY.md` |
| 2026-04-29 | Phase 6 context gathered | `.planning/phases/06-progress/06-CONTEXT.md` |
| 2026-04-29 | Phase 6 planned | `.planning/phases/06-progress/06-PLAN.md` |
| 2026-04-29 | Phase 6 executed | `.planning/phases/06-progress/06-SUMMARY.md` |
| 2026-04-29 | Phase 7 context gathered | `.planning/phases/07-profile-ai/07-CONTEXT.md` |
| 2026-04-29 | Phase 7 planned | `.planning/phases/07-profile-ai/07-PLAN.md` |
| 2026-04-29 | Phase 7 executed | `.planning/phases/07-profile-ai/07-SUMMARY.md` |
| 2026-04-29 | Phase 8 context gathered | `.planning/phases/08-water-reminders-polish/08-CONTEXT.md` |
| 2026-04-29 | Phase 8 planned | `.planning/phases/08-water-reminders-polish/08-PLAN.md` |
| 2026-04-29 | Phase 8 executed | `.planning/phases/08-water-reminders-polish/08-SUMMARY.md` |
| 2026-05-03 | Debugging & Calorie Logic | Fixed startup black screens, gendered calorie minimums, chart clipping, and added global data reset. |
| 2026-05-03 | Branding & Visual Identity | Rebranded Splash Screen with custom logo and configured optimized App Icon suite in Assets.xcassets. |
| 2026-05-04 | Phase 10 context gathered | `.planning/phases/10-ai-meals-tab/10-CONTEXT.md` |
| 2026-05-04 | Phase 10 planned | `.planning/phases/10-ai-meals-tab/10A-10D-PLAN.md` |
| 2026-05-04 | Phase 10 executed | `.planning/phases/10-ai-meals-tab/10-SUMMARY.md` |
| 2026-05-04 | Debugging | Fixed physical device Memory Save bug with NotificationCenter. Fixed AI mealType matching. Fixed severe SwiftUI iOS 17 Sheet State Capture bug using `.sheet(item:)` for `AddMealView` and `MealDetailSheet`. |
| 2026-05-04 | Phase 11 executed | `.planning/phases/11-gamification-ui-polish/11-SUMMARY.md` |
| 2026-05-05 | Phase 12 executed | `.planning/phases/12-advanced-data-inputs/12-SUMMARY.md` |
| 2026-05-05 | Phase 12 UAT verified | 9/9 passed. Fixed action bar layout + mic pulsing animation on device. |
| 2026-05-05 | Debugging | Fixed physical device Voice Input race conditions (flaky `isAvailable`). Refined UI: removed manual stop buttons and stabilized ZStack/VStack layout to match the seamless, clean look from the Simulator. |
| 2026-05-05 | Phase 13 context gathered | `.planning/phases/13-proactive-ai/13-CONTEXT.md` |
| 2026-05-05 | Phase 13 executed | `.planning/phases/13-proactive-ai/13-SUMMARY.md` |
| 2026-05-05 | Phase 13 UAT verified | 9/9 passed. Fixed: calo x4 bug, loading spinner block, auto-expand timing |
| 2026-05-05 | Phase 14 context gathered | `.planning/phases/14-ai-meal-planning/14-CONTEXT.md` |
| 2026-05-05 | Phase 14 planned | 3 plans (14A, 14B, 14C) in 2 waves. |
| 2026-05-05 | Phase 14 executed | `.planning/phases/14-ai-meal-planning/14-SUMMARY.md` |
| 2026-05-05 | Phase 14 UAT verified | 8/8 passed. Fixed AI JSON parse and URLSession timeouts for weekly plan. |
| 2026-05-07 | Phase 15 context gathered | `.planning/phases/15-ai-memory-hub-personality/15-CONTEXT.md` |
| 2026-05-07 | Phase 15 planned | 4 plans created in 4 waves |
| 2026-05-07 | Phase 15 executed | `.planning/phases/15-ai-memory-hub-personality/` |
| 2026-05-07 | Phase 15 UAT verified | 7/7 passed. Fixed CoreData schema path and missing imports. |
| 2026-05-07 | Phase 16 context gathered | `.planning/phases/16-api-infrastructure-context-compression/16-CONTEXT.md` |
| 2026-05-07 | Phase 16 planned | 6 tasks created in 5 waves |
| 2026-05-07 | Phase 16 executed | `.planning/phases/16-api-infrastructure-context-compression/16-SUMMARY.md` |
| 2026-05-08 | Debugging & AI Optimization | Implemented Distributed Batching & Streaming, Soft Constraints (±15% tolerance) for natural portions, and simplified AI Coach chat UI. Fixed Weekly Plan error bleed. |
| 2026-05-08 | Phase 16 UAT verified | 5/6 passed. Fixed raw JSON display, implemented real-time streaming JSON suppression, and collapsed redundant newlines for a cleaner chat UI. |
| 2026-05-08 | Phase 17 discussed | Gathered user context for Voice Chat implementation, focusing on premium UX and natural flow. |
| 2026-05-08 | Phase 17 executed | `.planning/phases/17-voice-chat/17-SUMMARY.md` |
| 2026-05-08 | Phase 17 UAT verified | 6/6 passed. Voice Chat feature fully functional: Mic/Send toggle, permission flow, recording sheet with waveform, real-time transcript, auto-stop on silence. |
| 2026-05-08 | Quick Task: UI Polish | Applied Apple HIG sizing to Chat input bar: 54pt minHeight, 44x44 mic container, 22pt icon, and added hold-to-record glow animation. |
| 2026-05-08 | Phase 18 discussed | 3-layer health safety (prompt + validation + re-ask), hybrid food mapping, repeated meals + macro imbalance insights, separate insight cards UI. |
| 2026-05-08 | Phase 18 planned | 5 tasks created in 4 waves |
| 2026-05-08 | Phase 18 executed | `.planning/phases/18-advanced-insights-health-aware-ai/` |
| 2026-05-08 | Phase 18 UAT verified | 8/8 passed, 2 skipped. Fixed duplicate insights display, consolidated into DailySummaryCard per user preference. |
| 2026-05-08 | Phase 19 discussed | NWPathMonitor singleton, Custom Food Builder (sheet + auto-calc macros), 4-section search priority, Chat-only queue. 36 decisions captured. |
| 2026-05-08 | Phase 19 planned | 5 plans in 4 waves: NetworkMonitor, CustomFoodBuilder, FoodSearch upgrade, Offline UI degradation, Pending chat queue. |
| 2026-05-08 | Phase 19 executed | `.planning/phases/19-offline-mode-custom-foods/` |
| 2026-05-08 | Phase 19 UAT verified | 10/10 passed. Custom foods persisted, dual-mode chat send button, rapid tap toast race fixed, and robust offline sync queue fully verified. |
| 2026-05-08 | Phase 20 context gathered | `.planning/phases/20-pro-chart-ux-data-visualization/20-CONTEXT.md` |
| 2026-05-08 | Phase 20 planned | 3 plans in 3 waves |
| 2026-05-08 | Phase 20 executed | `.planning/phases/20-pro-chart-ux-data-visualization/` |
| 2026-05-08 | Phase 20 UAT verified | Fixed axis mark spacing and empty state logic |
| 2026-05-09 | Chart & Summary Refinements | Added month/year anchors to charts, fixed Y-axis jumping, moved target label to axis, and implemented Daily Summary expansion persistence. |
| 2026-05-10 | Phase 22 context gathered | `.planning/phases/22-macro-dashboard/22-CONTEXT.md` — HealthKit deferred, focus on Macro Dashboard under Calories chart |

---
*Last updated: 2026-05-10 after Phase 22 context gathering*
