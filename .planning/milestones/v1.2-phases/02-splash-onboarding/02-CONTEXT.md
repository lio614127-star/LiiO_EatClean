# Phase 2: Splash + Onboarding + Goal Setup - Context

**Gathered:** 2026-04-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver the complete first-run experience: splash screen → 3-slide onboarding → 3-step goal setup → auto-calculate daily calories → transition to Home tab. After this phase, a new user can open the app and have their profile fully configured with a personalized calorie target.

</domain>

<decisions>
## Implementation Decisions

### Splash Screen
- **D-01:** Typography-only logo — "LiiO" (SF Pro Bold, 32–40pt, Primary color) + "EatClean" (SF Pro Regular, 16pt, #666666) centered on screen
- **D-02:** Animation: scale 0.9→1.0 + opacity 0→1, easeOut curve, total duration ~2 seconds
- **D-03:** Background: gradient from Primary (#4CAF50) light tint → white
- **D-04:** After animation completes, fade out transition to Onboarding (or Home if returning user)
- **D-05:** No custom image/logo asset — pure SwiftUI text + animation

### Onboarding Slides
- **D-06:** 3 slides using `TabView` with `.tabViewStyle(.page)` (swipe horizontal + dots indicator)
- **D-07:** Each slide layout: SF Symbol icon (80–100pt) centered → Title (Bold, 22–26pt) → Description (Regular, secondary color) below
- **D-08:** Slide icons: `flame.fill` (Track Calories), `chart.bar.fill` (Progress), `figure.walk` (Goals)
- **D-09:** Slide content (Vietnamese):
  - Slide 1: "Theo dõi Calories" / "Log bữa ăn nhanh chóng, chính xác mỗi ngày"
  - Slide 2: "Xem tiến trình" / "Biểu đồ trực quan giúp bạn theo dõi mục tiêu"
  - Slide 3: "Đạt body mong muốn" / "Thiết lập mục tiêu cá nhân và bắt đầu ngay"
- **D-10:** "Continue" button at bottom center, "Skip" text button at top-right
- **D-11:** Slide transition animation: icon fade + slight slide effect

### Goal Setup Flow (3 Steps)
- **D-12:** 3-step flow with progress bar at top showing current step (1/3, 2/3, 3/3)
- **D-13:** Step 1 — Basic Info: Name (optional TextField), Age (numeric TextField), Gender (Segmented Control: Male/Female)
- **D-14:** Step 2 — Body Metrics: Height in cm (TextField + Stepper), Weight in kg (TextField + Stepper). Numeric keyboard, auto-focus first field
- **D-15:** Step 3 — Goal Selection: 3 goal cards arranged vertically:
  - "Giảm cân" (Lose Weight) — calorie deficit -500
  - "Giữ cân" (Maintain) — no adjustment
  - "Tăng cân" (Gain Weight) — calorie surplus +300
  - Selected card highlighted with Primary color (#4CAF50) border/background
- **D-16:** Each step has "Next" button (disabled until required fields filled) + "Back" button (except Step 1)

### Calorie Calculation
- **D-17:** Mifflin-St Jeor formula:
  - Male: BMR = 10×weight(kg) + 6.25×height(cm) − 5×age − 161 + 5 = 10w + 6.25h - 5a + 5
  - Female: BMR = 10×weight(kg) + 6.25×height(cm) − 5×age − 161
  - TDEE = BMR × 1.55 (moderate activity default)
  - Daily Target = TDEE + goal adjustment (-500/0/+300)
  - Minimum bound: 1200 kcal (enforced)
- **D-18:** Calories preview displayed inline at Step 3, below goal cards: "🔥 Your daily calories" + large number (32–40pt, bold) + "Based on your profile & goal" subtitle
- **D-19:** Number animates (fade/count) when user switches between goal cards — realtime feedback
- **D-20:** No manual calorie override during onboarding — user can adjust later in Profile (Phase 7)

### Navigation & State
- **D-21:** App checks UserDefaults `hasCompletedOnboarding` flag on launch:
  - false → show Splash → Onboarding → Goal Setup
  - true → show Splash → Home (TabView)
- **D-22:** After Goal Setup completes, save User data via `UserRepository.saveUser()`, set `hasCompletedOnboarding = true`, transition to Home TabView
- **D-23:** Gender field added to User entity (String: "male"/"female") — needed for Mifflin-St Jeor formula. Requires CoreData lightweight migration or schema update

### Agent's Discretion
- Exact animation timing curves and durations for slide transitions
- Precise layout spacing between elements within each step
- Error handling for invalid numeric input (negative values, extreme ranges)
- Whether to add haptic feedback on goal card selection

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 1 Foundation
- `.planning/phases/01-project-foundation/01-CONTEXT.md` — CoreData schema, UserRepository protocol, folder structure
- `.planning/phases/01-project-foundation/01-SUMMARY.md` — What was built in Phase 1

### Project Context
- `.planning/PROJECT.md` — Project constraints and core value
- `.planning/REQUIREMENTS.md` — ONBD-01 through ONBD-05 requirements
- `.planning/ROADMAP.md` — Phase 2 success criteria

### Research
- `.planning/research/ARCHITECTURE.md` — System architecture and data flow

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `LiiO_EatClean/Data/Persistence/Persistence.swift` — PersistenceController singleton, inject via Environment
- `LiiO_EatClean/Data/Models/UserModel.swift` — UserModel struct (id, name, age, height, weight, goalType, dailyCalorieTarget)
- `LiiO_EatClean/Data/Repositories/UserRepository.swift` — saveUser() and fetchUser() implementations
- `LiiO_EatClean/App/ContentView.swift` — Existing TabView with 4 tabs

### Established Patterns
- @Observable macro for ViewModels (iOS 17+)
- Repository protocol → implementation pattern from Phase 1
- NavigationStack per tab

### Integration Points
- Splash/Onboarding views will wrap or replace ContentView based on onboarding state
- UserRepository.saveUser() is the single save point after Goal Setup
- LiiO_EatCleanApp.swift needs to check onboarding state and route accordingly

</code_context>

<specifics>
## Specific Ideas

- Gender field is NEW — not in original Phase 1 schema. Need to add it to User entity and UserModel
- Activity level hardcoded to "moderate" (1.55 multiplier) for v1 — can be made configurable in Profile later
- Vietnamese content for slides — keep it natural, not overly formal
- "Get Started" button text on final step (not "Done" or "Finish")
- Calorie preview should show immediately when first goal card is auto-selected or tapped

</specifics>

<deferred>
## Deferred Ideas

- Activity level selection (sedentary/moderate/active) — could be Phase 7 Profile enhancement
- Custom calorie override during onboarding — deferred to Profile (Phase 7)
- Onboarding skip → use default calories (2000) — too complex for v1, require full setup
- Dark mode specific splash gradient colors — handle in Phase 8 polish

</deferred>

---

*Phase: 02-Splash + Onboarding + Goal Setup*
*Context gathered: 2026-04-29*
