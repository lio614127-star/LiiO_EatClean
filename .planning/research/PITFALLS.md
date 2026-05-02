# Pitfalls Research: LiiO EatClean

## Critical Pitfalls

### 1. Inaccurate Calorie Data
**Risk:** High — users lose trust if calories are wrong
**Warning signs:** Inconsistent values between API and local data, missing serving sizes
**Prevention:**
- Always include serving size with calorie data
- Cross-validate local Vietnamese food data with multiple sources
- Show data source to user (builds trust)
- Allow manual correction
**Phase:** Food Database (Phase 3-4)

### 2. CoreData Threading Crashes
**Risk:** High — accessing managed objects from wrong thread causes crashes
**Warning signs:** Random EXC_BAD_ACCESS, data corruption
**Prevention:**
- Use `perform {}` and `performAndWait {}` consistently
- Never pass NSManagedObject across threads — map to structs in Repository
- Use @MainActor on ViewModels
- Background context for heavy operations (batch imports)
**Phase:** Foundation (Phase 1)

### 3. Onboarding Drop-off
**Risk:** Medium — users quit before reaching core feature
**Warning signs:** Complex multi-step setup, too many required fields
**Prevention:**
- Maximum 3-4 steps in goal setup
- Show progress bar
- Allow skip with sensible defaults
- Get user to "first win" (seeing their dashboard) within 60 seconds
**Phase:** Onboarding (Phase 2)

### 4. Slow Food Search UX
**Risk:** Medium — users won't log meals if search is slow
**Warning signs:** API latency > 1s, no results feedback, no offline support
**Prevention:**
- Search local DB first (instant)
- Debounce API calls (300ms)
- Show loading state
- Cache all API results locally
- Show recent/frequent foods at top
**Phase:** Food Database + Meal Logging (Phase 3-4)

### 5. AI Response Parsing Failures
**Risk:** Medium — AI output format can be unpredictable
**Warning signs:** JSON parse errors, garbled responses, timeout
**Prevention:**
- Use system prompt to enforce JSON format
- Validate JSON structure before displaying
- Graceful fallback UI when AI fails
- Set timeout (10s max)
- Show "AI unavailable" state, not crash
**Phase:** AI Integration (Phase 6)

### 6. Date/Timezone Bugs
**Risk:** Medium — meals logged "yesterday" or "tomorrow" due to timezone
**Warning signs:** Meals appearing on wrong day, daily totals incorrect
**Prevention:**
- Store all dates in UTC
- Use Calendar.current for display
- Use startOfDay() consistently for daily grouping
- Test across timezone changes
**Phase:** Foundation (Phase 1)

### 7. Calorie Calculation Formula Errors
**Risk:** Medium — wrong TDEE means wrong daily target
**Warning signs:** Unrealistic calorie targets (< 1200 or > 4000)
**Prevention:**
- Use Mifflin-St Jeor (most accurate for general population)
- Add bounds checking (minimum 1200 kcal)
- Show calculation breakdown to user
- Allow manual override
**Phase:** Goal Setup (Phase 2)

### 8. Over-engineering the Architecture
**Risk:** Medium — spending too long on abstractions before shipping
**Warning signs:** Many protocols with single implementations, deep layer nesting
**Prevention:**
- Start with concrete implementations, extract protocols when needed
- Repository pattern is enough abstraction for v1
- Don't add dependency injection framework — init injection is sufficient
- Ship working features, refactor later
**Phase:** All phases

## Common iOS-Specific Gotchas

| Gotcha | Impact | Mitigation |
|--------|--------|------------|
| SwiftUI preview crashes with CoreData | Dev speed | Use in-memory store for previews |
| Keyboard covers input fields | UX | Use ScrollView + .scrollDismissesKeyboard |
| Large list performance | UX | Use LazyVStack, not VStack for meal lists |
| Dark mode forgotten | Visual bugs | Test both modes from Phase 1 |
| Notification permissions denied | Feature loss | Graceful degradation, explain value first |
