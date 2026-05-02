# Features Research: LiiO EatClean

## Table Stakes (Must Have — Users Leave Without These)

### Calorie Tracking
- Daily calorie target calculation (TDEE based on height/weight/age/goal)
- Visual calorie progress (ring/bar showing consumed vs target)
- Meal logging by time slot (breakfast/lunch/dinner/snack)
- Food search with nutrition data
- Quick-add calories (manual entry)
- Daily calorie summary

### Weight Tracking
- Log weight entries
- Weight history chart (line graph)
- Goal weight display
- Trend visualization (weekly/monthly)

### User Profile & Goals
- Basic profile (name, age, height, weight)
- Goal selection (lose/maintain/gain weight)
- Daily calorie target auto-calculation
- Edit goals anytime

### Onboarding
- First-time setup wizard
- Goal configuration flow
- Clear value proposition

## Differentiators (Competitive Advantage)

### Vietnamese Food Database
- Pre-loaded local Vietnamese dishes with accurate calories
- Phở, bún bò, cơm tấm, bánh mì, etc.
- Local-first search (instant results)
- **Complexity:** Medium — requires manual curation
- **Impact:** High — no competitor focuses on Vietnamese food

### AI Meal Suggestions
- AI-powered meal recommendations based on remaining calories
- Vietnamese food preferences
- JSON structured output for clean UI
- Multi API key rotation
- **Complexity:** Medium — API integration + prompt engineering
- **Impact:** High — differentiates from basic trackers

### Smart Reminders
- Meal logging reminders
- Configurable timing
- **Complexity:** Low — iOS Local Notifications
- **Impact:** Medium — improves retention

### Water Tracking
- Daily water intake logging
- Visual progress
- **Complexity:** Low
- **Impact:** Medium — common in health apps

## Anti-Features (Do NOT Build)

| Feature | Why Not |
|---------|---------|
| Workout tracking | Dilutes app focus, different domain |
| Community/social | Massive engineering effort, not core value |
| Barcode scanner (v1) | Camera permissions, UPC database, defer to v2 |
| Macro tracking (protein/carbs/fat) | Adds complexity, calories-only is simpler for v1 |
| Recipe builder | Complex UI, defer to v2 |
| Meal planning calendar | Overkill for MVP |

## Feature Dependencies

```
Setup Goal → Home Dashboard (needs calorie target)
Food Database → Add Meal (needs search data)
Add Meal → Home Dashboard (updates daily calories)
Weight Logging → Progress Charts (needs data points)
AI Service → Meal Suggestions (needs API connection)
```
