# Phase 11: Gamification & UI Polish — Context

**Date:** 2026-05-04
**Phase:** 11 — Gamification & UI Polish (Streak, Haptic, Micro-interactions)
**Requirements:** STRK-01, STRK-02, UIPL-01, UIPL-02

## Domain

Xây dựng hệ thống Streak (chuỗi ngày duy trì thói quen) kết hợp Haptic Feedback và Micro-animations để nâng cấp cảm giác sử dụng app từ "functional" lên "feels good to use".

## Decisions

### Streak Logic (STRK-01)

- **Điều kiện tính streak mỗi ngày (Nghiêm ngặt — 3 tiêu chí):**
  1. Log ≥2 bữa ăn trong ngày
  2. Tổng calo đạt ±10% so với target
  3. Uống nước ≥80% target
- **Tất cả 3 điều kiện phải đạt** để streak +1
- **UX mềm khi chưa đạt đủ:** Hiển thị "Gần đạt streak (2/3 điều kiện)" thay vì chỉ reset lạnh lùng — giữ motivation cho user
- **Data model:** Tạo CoreData entity riêng `StreakRecord` với các field:
  - `currentStreak: Int` — chuỗi hiện tại
  - `longestStreak: Int` — kỷ lục cá nhân
  - `lastActiveDate: Date` — ngày cuối cùng đạt đủ 3 tiêu chí
- **Lý do chọn entity riêng:** Hiển thị thường xuyên trên Dashboard, cần performance tốt, dễ scale sau này cho weekly/monthly stats

### Streak UI (STRK-02)

- **Vị trí:** Card riêng trên Home Dashboard, đặt giữa CalorieRingView và WaterCardView
- **Thiết kế card:** Bo góc + shadow nhẹ giống design system hiện tại (16-24px radius), compact — không chiếm quá nhiều không gian
- **Biểu tượng kết hợp:**
  - 🔥 (lửa) cho streak hàng ngày — quen thuộc, dễ nhận biết
  - 🌿 (cây/lá) cho milestone đặc biệt — phù hợp branding EatClean #4CAF50
  - Hình dung: `[ 🔥 7 ngày liên tiếp ]` → đạt 7 ngày: 🌿 xuất hiện
- **Milestone celebrations:**
  - Popup nhẹ chúc mừng + animation khi đạt mốc (7, 14, 30 ngày)
  - Style: subtle, nhanh, không spam — tạo dopamine nhưng không gây phiền
  - Milestone tiers: 7 ngày = 🌿 cây con, 30 ngày = 🌿 cây lớn

### Haptic Feedback (UIPL-01)

- **Phạm vi áp dụng (Success + Interactions):**
  - Save meal thành công
  - Thêm nước (add water)
  - Swipe delete món ăn
  - Chạm vào streak card
  - Đạt streak / milestone
- **Phân loại haptic theo ngữ nghĩa:**
  - `UIImpactFeedbackGenerator(.light)` hoặc `.success` → lưu thành công, đạt streak
  - `UIImpactFeedbackGenerator(.medium)` → interaction (tap, add nước)
  - `UINotificationFeedbackGenerator(.warning)` → vượt calo target
- **Nguyên tắc:** User cảm nhận trạng thái qua haptic mà không cần đọc text

### Micro-animations (UIPL-02)

- **Animation style chính:** Slide-in + fade cho meal items mới
  - Món mới trượt vào từ bên phải + fade in
  - Calm, clean, đúng chuẩn iOS — không "gamey"
- **Nguyên tắc tổng:** Subtle → Consistent → Meaningful
- **Không làm:** Bounce quá mạnh, confetti, animation kéo dài — giữ vibe health app

## Code Context

### Reusable Assets
- `HomeView.swift` — Layout hiện tại: header → CalorieRing → MacroBars → WaterCard → MealCards → AddButton. Streak card sẽ chèn giữa CalorieRing và WaterCard.
- `HomeViewModel.swift` — Đã có `totalCalories`, `waterConsumed`, `dailyTarget`, `isOverTarget`, `todayMeals` — sẵn sàng cho logic kiểm tra streak conditions.
- `DailyLogModel.swift` — Có `waterIntake` và `meals` — cung cấp data để check điều kiện streak.
- `MealCardView.swift`, `WaterCardView.swift` — Existing card components có thể tham khảo style cho StreakCard.
- `CalorieRingView.swift` — Đã có `.animation(.easeInOut(duration: 0.6))` — chuẩn animation timing cho app.

### Patterns
- `@Observable` macro cho ViewModels (không dùng ObservableObject)
- Repository pattern: StreakRecord sẽ cần thêm method vào `UserRepository` hoặc tạo `StreakRepository` mới
- `MealSheetItem` pattern cho `.sheet(item:)` — tham khảo nếu cần sheet cho streak detail

## Canonical Refs
- `.planning/REQUIREMENTS.md` — STRK-01, STRK-02, UIPL-01, UIPL-02
- `.planning/ROADMAP.md` — Phase 11 scope
- `LiiO_EatClean/Features/Home/HomeView.swift` — Integration point chính
- `LiiO_EatClean/Features/Home/HomeViewModel.swift` — Logic layer
- `LiiO_EatClean/Data/Models/DailyLogModel.swift` — Existing data model

## Deferred Ideas
- Weekly/monthly streak stats view (Phase riêng nếu cần)
- Streak sharing (social) — out of scope
