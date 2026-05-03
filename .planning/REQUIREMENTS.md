# Requirements: LiiO EatClean

**Defined:** 2026-04-29
**Core Value:** User có thể log bữa ăn và xem calories hôm nay trong vòng 5 giây — nhanh, đẹp, chính xác.

## v1 Requirements

### Foundation

- [ ] **FOUND-01**: Xcode project với SwiftUI, iOS 17+ target, CoreData stack
- [ ] **FOUND-02**: CoreData schema (User, Meal, FoodItem, MealFood, DailyLog, WeightEntry, APIKey)
- [ ] **FOUND-03**: Repository pattern (MealRepository, FoodRepository, UserRepository protocols + implementations)
- [ ] **FOUND-04**: App navigation structure với TabView (Home/Meals/Progress/Profile)

### Onboarding

- [ ] **ONBD-01**: Splash screen với logo ở giữa, background trắng/xanh nhạt, auto chuyển sau 1-2s
- [ ] **ONBD-02**: Onboarding 3 slides ("Track calories dễ dàng", "Theo dõi tiến trình", "Đạt body mong muốn") với Continue + Skip
- [ ] **ONBD-03**: Setup Goal step-by-step (3-4 bước): nhập cân nặng, chiều cao, tuổi, mục tiêu
- [ ] **ONBD-04**: Auto tính calories/ngày bằng Mifflin-St Jeor formula với bounds checking (min 1200 kcal)
- [ ] **ONBD-05**: Progress bar trên đầu Setup Goal screens

### Dashboard

- [ ] **DASH-01**: Header "Hello, LiiO" với calories today summary
- [ ] **DASH-02**: Calories progress ring (vòng tròn animated) hiển thị consumed/target
- [ ] **DASH-03**: Meals hôm nay section (Breakfast/Lunch/Dinner cards) với calories từng bữa
- [ ] **DASH-04**: Nút "Add Meal" lớn, nổi bật
- [ ] **DASH-05**: Dashboard auto-refresh khi save meal mới

### Food Database

- [ ] **FOOD-01**: Local Vietnamese foods JSON (cơm, phở, bún bò, bánh mì, etc.) với calories chính xác
- [ ] **FOOD-02**: Food API integration (CalorieNinjas) cho international foods
- [ ] **FOOD-03**: Hybrid search: query local DB trước (instant) → API nếu không có → cache kết quả
- [ ] **FOOD-04**: Food search UI với debounce (300ms), loading state, recent/frequent foods

### Meal Logging

- [ ] **MEAL-01**: Add Meal screen với food search, chọn meal type (breakfast/lunch/dinner/snack)
- [ ] **MEAL-02**: Chọn food từ search results, nhập portion/quantity
- [ ] **MEAL-03**: Save meal → update DailyLog → refresh Dashboard calories
- [ ] **MEAL-04**: Meals list screen hiển thị tất cả bữa ăn theo ngày, card từng món
- [ ] **MEAL-05**: Meal detail view khi tap vào card
- [ ] **MEAL-06**: Edit/delete meal đã log

### Progress

- [ ] **PROG-01**: Weight logging (nhập cân nặng theo ngày)
- [ ] **PROG-02**: Weight chart dùng Swift Charts (LineMark + PointMark + goal RuleMark)
- [ ] **PROG-03**: Weekly/Monthly toggle cho chart view
- [ ] **PROG-04**: Calorie history visualization

### Profile

- [ ] **PROF-01**: Hiển thị thông tin cá nhân (tên, tuổi, chiều cao, cân nặng)
- [ ] **PROF-02**: Hiển thị và edit mục tiêu (goal type, daily calories target)
- [ ] **PROF-03**: Settings section
- [ ] **PROF-04**: API key management UI (add/remove OpenAI/Gemini keys)

### AI Integration

- [ ] **AI-01**: AI meal suggestion dựa trên calories còn lại, mục tiêu, món đã ăn
- [ ] **AI-02**: Prompt engineering: ưu tiên Vietnamese food, JSON output format
- [ ] **AI-03**: Multi API key storage + auto rotation khi key fail
- [ ] **AI-04**: Graceful fallback UI khi AI unavailable

### Water & Reminders

- [ ] **WATR-01**: Water intake logging (ml) theo ngày
- [ ] **WATR-02**: Water progress visualization trên Dashboard hoặc separate section
- [ ] **RMND-01**: Local notification reminders cho meal logging
- [ ] **RMND-02**: Configurable reminder timing trong Settings

### AI Nutritionist Chatbox

- [ ] **CHAT-01**: Giao diện Chatbot chuyên nghiệp (bubble chat, typing indicator, markdown)
- [ ] **CHAT-02**: Persona Chuyên gia dinh dưỡng (kiến thức về calories, macros, chế độ ăn uống)
- [ ] **CHAT-03**: App context awareness (AI hiểu và hướng dẫn được các chức năng của app)
- [ ] **CHAT-04**: Phân tích thói quen (AI phân tích food logs/activity để đưa ra nhận xét cá nhân hóa)
- [ ] **CHAT-05**: Gợi ý món ăn thông minh (AI gợi ý món ăn phù hợp với thói quen và mục tiêu hiện tại)

## v2 Requirements

### Enhanced Features
- **SCAN-01**: Camera scan món ăn (food recognition AI)
- **HLTH-01**: HealthKit integration (sync weight, calories)
- **MACR-01**: Macro tracking (protein, carbs, fat breakdown)
- **SYNC-01**: CloudKit sync cho multi-device
- **RCPE-01**: Recipe builder với auto calorie calculation
- **STRK-01**: Streak tracking (consecutive days logged)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Workout tracking | Làm loãng app focus, khác domain |
| Community/social features | Rất tốn công, không phải core value |
| Android version | Native iOS trước, Android riêng sau |
| Barcode scanner (v1) | Camera permissions + UPC database, defer v2 |
| Multi-device sync (v1) | Overkill, local CoreData đủ cho v1 |
| Firebase/backend | Không cần server cho v1, local-first |
| Macro tracking (v1) | Thêm complexity, calories-only đơn giản hơn |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| FOUND-01 | Phase 1 | Pending |
| FOUND-02 | Phase 1 | Pending |
| FOUND-03 | Phase 1 | Pending |
| FOUND-04 | Phase 1 | Pending |
| ONBD-01 | Phase 2 | Pending |
| ONBD-02 | Phase 2 | Pending |
| ONBD-03 | Phase 2 | Pending |
| ONBD-04 | Phase 2 | Pending |
| ONBD-05 | Phase 2 | Pending |
| DASH-01 | Phase 3 | Pending |
| DASH-02 | Phase 3 | Pending |
| DASH-03 | Phase 3 | Pending |
| DASH-04 | Phase 3 | Pending |
| DASH-05 | Phase 3 | Pending |
| FOOD-01 | Phase 4 | Pending |
| FOOD-02 | Phase 4 | Pending |
| FOOD-03 | Phase 4 | Pending |
| FOOD-04 | Phase 4 | Pending |
| MEAL-01 | Phase 5 | Pending |
| MEAL-02 | Phase 5 | Pending |
| MEAL-03 | Phase 5 | Pending |
| MEAL-04 | Phase 5 | Pending |
| MEAL-05 | Phase 5 | Pending |
| MEAL-06 | Phase 5 | Pending |
| PROG-01 | Phase 6 | Pending |
| PROG-02 | Phase 6 | Pending |
| PROG-03 | Phase 6 | Pending |
| PROG-04 | Phase 6 | Pending |
| PROF-01 | Phase 7 | Pending |
| PROF-02 | Phase 7 | Pending |
| PROF-03 | Phase 7 | Pending |
| PROF-04 | Phase 7 | Pending |
| AI-01 | Phase 7 | Pending |
| AI-02 | Phase 7 | Pending |
| AI-03 | Phase 7 | Pending |
| AI-04 | Phase 7 | Pending |
| WATR-01 | Phase 8 | Pending |
| WATR-02 | Phase 8 | Pending |
| RMND-01 | Phase 8 | Pending |
| RMND-02 | Phase 8 | Pending |
| CHAT-01 | Phase 9 | Pending |
| CHAT-02 | Phase 9 | Pending |
| CHAT-03 | Phase 9 | Pending |
| CHAT-04 | Phase 9 | Pending |
| CHAT-05 | Phase 9 | Pending |

**Coverage:**
- v1 requirements: 43 total
- Mapped to phases: 43
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-29*
*Last updated: 2026-04-29 after initial definition*
