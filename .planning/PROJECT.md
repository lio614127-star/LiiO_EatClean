# LiiO EatClean

## What This Is

LiiO EatClean là app iOS theo dõi calories và bữa ăn hàng ngày, giúp người dùng đạt mục tiêu giảm cân. App tập trung vào trải nghiệm log đồ ăn nhanh gọn, dashboard trực quan với progress ring, và gợi ý bữa ăn thông minh bằng AI — ưu tiên món Việt Nam. Thiết kế theo phong cách Apple-native với SwiftUI, bo góc mềm mại và animation mượt.

## Core Value

User có thể log bữa ăn và xem calories hôm nay trong vòng 5 giây — nhanh, đẹp, chính xác.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Splash screen với logo + auto transition sau 1-2s
- [ ] Onboarding 3 slides (track calories, theo dõi tiến trình, đạt body mong muốn) + Skip/Continue
- [ ] Setup Goal: nhập cân nặng, chiều cao, tuổi, mục tiêu → tính calories/ngày (step-by-step + progress bar)
- [ ] Home Dashboard: header greeting, calories progress ring, meals hôm nay (Breakfast/Lunch/Dinner), nút Add Meal
- [ ] Meals Screen: list bữa ăn theo ngày, card từng món, click vào detail
- [ ] Add Meal: search món ăn (hybrid local + API), nhập calories, save
- [ ] Progress Screen: biểu đồ cân nặng, weekly/monthly toggle
- [ ] Profile Screen: thông tin cá nhân, mục tiêu, settings, quản lý API keys
- [ ] Food database hybrid: local Vietnamese foods JSON + API (Nutritionix/FatSecret) + cache
- [ ] AI meal suggestion: tích hợp OpenAI/Gemini, multi API key với auto swap
- [ ] Tab bar navigation: Home / Meals / Progress / Profile
- [ ] Water tracking (theo dõi nước uống)
- [ ] Smart reminders (nhắc nhở thông minh)
- [ ] Scan food (nâng cao — camera scan món ăn)

### Out of Scope

- Workout tracking — làm loãng focus của app, core value là meal/calorie tracking
- Community chat — rất tốn công, không phải core value
- Android version — build native iOS trước, Android làm riêng sau nếu cần
- Multi-device sync — v1 local-only, chuẩn bị schema cho sync sau
- Firebase/backend — overkill cho v1, local CoreData đủ dùng

## Context

**Target user:** Người Việt Nam muốn giảm cân, theo dõi calories hàng ngày. App cá nhân (LiiO).

**Daily loop:** Open app → xem calories → log đồ ăn → xem progress

**Key action flow:** Home → Add Meal → Save → Dashboard update

**Vietnamese food focus:** Đây là lợi thế cạnh tranh — hỗ trợ sẵn cơm, bún bò, phở, bánh mì... với calories chính xác. Food search ưu tiên local DB trước, API sau, cache lại.

**AI integration:** Dùng AI thật từ v1. User nhập nhiều API key (OpenAI/Gemini), app tự swap khi key fail. AI nhận input: calories còn lại + mục tiêu + món đã ăn → suggest 2 bữa ăn đơn giản (JSON format) ưu tiên món Việt.

**Data schema (chuẩn bị cho sync sau):**
- User (profile, goals)
- Meal (breakfast/lunch/dinner, date)
- FoodItem (name, calories, source: local/api)
- DailyLog (date, total calories, water intake)

## Constraints

- **Platform**: iOS only — SwiftUI, minimum iOS 17+
- **Tech stack**: Swift + SwiftUI native — không cross-platform
- **Data**: CoreData local-first — Repository pattern để swap backend sau
- **Food API**: Nutritionix hoặc FatSecret — cần API key
- **AI API**: OpenAI hoặc Gemini — user tự nhập key, multi-key rotation
- **Design**: Apple-style — SF Pro font, bo góc 16-24px, shadow nhẹ, màu xanh lá #4CAF50 vibe, nền trắng
- **Architecture**: App Layer → ViewModel → Repository → Local DB (CoreData)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Swift + SwiftUI native | UI mượt, animation nhiều, HealthKit-ready, build nhanh cho MVP | — Pending |
| CoreData local-first | Đơn giản cho v1, không cần backend, schema chuẩn bị sync sau | — Pending |
| Hybrid food database | API cho international foods + local JSON cho món Việt → lợi thế cạnh tranh | — Pending |
| AI thật từ v1 | Multi API key + auto swap, đủ đơn giản để implement, UX value cao | — Pending |
| Repository pattern | Tách data layer → dễ swap CoreData sang CloudKit/API sau | — Pending |
| Tab bar 4 tabs | Home/Meals/Progress/Profile — chuẩn iOS, không quá phức tạp | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-29 after initialization*
