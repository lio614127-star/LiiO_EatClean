# Phase 3: Home Dashboard - Context

**Gathered:** 2026-04-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Build the central Home Dashboard that users see every day. Shows calories progress ring with macro breakdown bars, greeting with remaining calories summary, 4 fixed meal cards (Breakfast/Lunch/Dinner/Snack) with food preview, and a full-width "Add Meal" button. This is the heart of the app — a daily decision tool, not just a tracker.

</domain>

<decisions>
## Implementation Decisions

### Calories Progress Ring
- **D-01:** Ring + macro bars layout — 1 large circular progress ring for total calories + 3 horizontal progress bars below for protein/carbs/fat
- **D-02:** Ring center displays: consumed calories (large bold) / target calories (smaller). Example: "1250 / 1800 kcal"
- **D-03:** Ring color: Primary green (#4CAF50) normally, transitions to orange (#FF9800) when calories exceed target. No red — avoid negative/toxic UX
- **D-04:** Macro bars: 3 thin horizontal bars labeled Protein / Carbs / Fat with consumed/target values. Color-coded (distinct from each other)
- **D-05:** Ring should be animated — fill animation on appear and when data changes

### Header & Greeting
- **D-06:** Header layout: "Xin chào, [Tên]!" greeting + "Còn [X] kcal hôm nay" subtitle directly below
- **D-07:** If calories exceeded: subtitle changes to "Đã vượt [X] kcal hôm nay" with orange text color
- **D-08:** User name comes from UserModel.name (via UserRepository.fetchUser). If name is empty, show "Xin chào!"

### Meal Cards Section
- **D-09:** 4 fixed meal cards always visible: Bữa sáng (Breakfast), Bữa trưa (Lunch), Bữa tối (Dinner), Ăn vặt (Snack)
- **D-10:** Card design — detailed style: meal type name + icon + total calories for that meal + preview of first 2-3 food items inside the card
- **D-11:** Empty state for each card: "Chưa có bữa ăn" text + subtle "+" icon. Tapping empty card = same as Add Meal for that type
- **D-12:** Card icons: SF Symbols — "sunrise.fill" (breakfast), "sun.max.fill" (lunch), "moon.fill" (dinner), "leaf.fill" (snack)
- **D-13:** Cards are tappable — tap → navigate to meal detail (Phase 5). For now, just placeholder navigation

### Add Meal Button
- **D-14:** Full-width button at bottom of meal cards list (not floating). Text: "Thêm bữa ăn". Green background, white text, rounded corners (14px)
- **D-15:** Tap → navigate to Add Meal screen (Phase 5). For Phase 3, this is a placeholder that shows an alert or empty view
- **D-16:** Native iOS style — no floating action button (FAB), keeps clean Apple aesthetic

### Data Flow
- **D-17:** Dashboard data loaded from MealRepository.fetchMeals(by: today) + UserRepository.fetchUser()
- **D-18:** Total calories calculated from sum of all MealFood.caloriesSnapshot for today's meals
- **D-19:** Macro totals calculated from sum of MealFood.proteinSnapshot/carbsSnapshot/fatSnapshot
- **D-20:** Dashboard should auto-refresh when returning from Add Meal (observed via @Observable ViewModel or .onAppear)

### Agent's Discretion
- Exact macro bar colors (suggest: blue for protein, yellow for carbs, pink for fat)
- Spacing and padding between ring and meal cards
- Whether to add pull-to-refresh gesture
- Animation easing curves for the ring

</decisions>

<canonical_refs>
## Canonical References

### Prior Phase Context
- `.planning/phases/01-project-foundation/01-CONTEXT.md` — Repository protocols, CoreData schema, folder structure
- `.planning/phases/02-splash-onboarding/02-CONTEXT.md` — User setup flow, CalorieCalculator utility

### Project Context
- `.planning/REQUIREMENTS.md` — DASH-01 through DASH-05 requirements
- `.planning/ROADMAP.md` — Phase 3 success criteria

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `LiiO_EatClean/Features/Home/HomeView.swift` — Existing placeholder, will be replaced
- `LiiO_EatClean/Data/Repositories/MealRepository.swift` — fetchMeals(by:) method
- `LiiO_EatClean/Data/Repositories/UserRepository.swift` — fetchUser() method
- `LiiO_EatClean/Data/Models/MealModel.swift` — MealModel with totalCalories computed property
- `LiiO_EatClean/Data/Models/MealFoodModel.swift` — Snapshot fields (caloriesSnapshot, proteinSnapshot, etc.)
- `LiiO_EatClean/Core/Utils/CalorieCalculator.swift` — Existing utility (may reference for consistency)

### Established Patterns
- @Observable for ViewModels (iOS 17+)
- async/await for Repository calls
- Green (#4CAF50) as Primary accent color
- NavigationStack per tab
- SF Symbols for icons

### Integration Points
- HomeView is already wired as first tab in ContentView.swift TabView
- MealRepository.fetchMeals(by:) returns [MealModel] — needs date filtering
- UserRepository.fetchUser() returns UserModel? with dailyCalorieTarget

</code_context>

<specifics>
## Specific Ideas

- Dashboard = "decision tool" not just tracker — user should instantly know "what to eat next"
- Macro bars add real depth vs competitors who only show calories
- Orange (not red) for over-target keeps the vibe positive and non-judgmental
- Cards showing food preview removes one tap from the user journey
- "Còn X kcal" subtitle is THE most valuable info on the screen — make it prominent

</specifics>

<deferred>
## Deferred Ideas

- Pull-to-refresh for dashboard data — can add in Phase 8 polish
- Date picker to view other days — belongs in Phase 6 progress
- Streak indicator on dashboard — v2 feature (STRK-01)
- Water intake display on dashboard — Phase 8

</deferred>

---

*Phase: 03-Home Dashboard*
*Context gathered: 2026-04-29*
