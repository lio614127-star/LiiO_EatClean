# Project State: LiiO EatClean

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-29)

**Core value:** User có thể log bữa ăn và xem calories hôm nay trong vòng 5 giây
**Current focus:** Milestone 1 Completion & Final Polish

## Current Milestone

**Milestone: v1.1 Trải Nghiệm Nhanh & AI Chủ Động**

- Daily AI Summary
- Streak & Gamification
- Voice Input
- AI Meal Planning
- Barcode Scan
- Advanced Memory Insight
- UI Polish & Micro-interactions

## Current Position

Phase: 12
Plan: 12-PLAN.md
Status: Verified (UAT 9/9 passed)
Last activity: 2026-05-05 — Phase 12 UAT complete, all tests passed

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

### Learnings
- AI `mealType` mapping must strictly match UI categories ("Bữa phụ" -> "Ăn vặt") to prevent ghost data.
- User portions need normalization (divided by servingSize) to handle manual quantity changes correctly later.
- Ephemeral state (UserDefaults for isEaten) is a reliable way to add properties without complex CoreData migrations mid-development.
(None yet)

### Roadmap Evolution
- Phase 9 added: AI Nutritionist Chatbox (Expert advice, habit-aware, app context)
- Phase 10 added: AI-Powered Meals Tab — Smart Suggestions, Memory & Actionable AI

## Session Log

| Date | Stopped At | Resume |
|------|-----------|--------|
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

---
*Last updated: 2026-05-05 after Phase 12 debugging*
