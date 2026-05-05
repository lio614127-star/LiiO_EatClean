# Phase 13: Proactive AI — Context

**Date:** 2026-05-05
**Phase:** 13 — Proactive AI (Daily Summary & Memory Insights)
**Requirements:** DSUM-01, DSUM-02, MINS-01, MINS-02

## Domain

Biến AI từ reactive (user hỏi → AI trả lời) thành **proactive** — AI tự phân tích data ăn uống và chủ động đưa ra Daily Summary cuối ngày + Memory Insights nhận diện pattern chưa tốt. Mục tiêu: user hiểu nhanh hôm nay ăn có ổn không + mai nên làm gì.

## Decisions

### Trigger & Timing — Daily Summary (DSUM-01)

- **Combo: Push notification + Home card**
  - **Push notification cuối ngày (~20h):**
    - Local notification: "Hôm nay bạn ăn 1850 kcal. Xem chi tiết?"
    - Tap → mở app → hiện summary card
    - Dùng `ReminderService` pattern đã có
  - **Summary card luôn hiện trên Home:**
    - Hiện summary ngày hôm nay (hoặc hôm qua nếu sáng sớm)
    - Tự refresh mỗi ngày mới
  - **Lý do:** Push = trigger hành vi, Card = nơi tiêu thụ nội dung. Nếu user tắt notification vẫn thấy card.

### Nội dung Summary (DSUM-02)

- **Phân tích trung bình: Calories + macros + timing + gợi ý**
  - Calories ăn / mục tiêu (vd: 1850/2000 kcal)
  - Breakdown macro (protein/carbs/fat) — có đủ hay thiếu?
  - Phân bố bữa ăn (sáng/trưa/tối — cân bằng hay lệch?)
  - 2-3 câu nhận xét AI + 1 gợi ý cải thiện cho ngày mai
  - **"Fake B3":** thêm 1 dòng trend nhẹ (vd: "thiếu protein 2 ngày") mà không cần full trend engine
- **Tone AI:**
  - Đạt goal → tích cực, động viên 🎉
  - Chưa đạt → nhẹ nhàng, không toxic, kèm gợi ý cụ thể
- **Nguyên tắc:** Simple → Useful → Actionable

### Memory Insight — Pattern Detection (MINS-01)

- **4 patterns high-impact:**

  | Pattern | Ví dụ insight |
  |---------|---------------|
  | P1: Thiếu macro | "3 ngày gần đây protein dưới 30g" |
  | P3: Bỏ bữa | "Bạn bỏ bữa sáng 4/7 ngày tuần này" |
  | P5: Vượt calo liên tục | "3 ngày liên tiếp vượt mục tiêu 200+ kcal" |
  | P6: Uống ít nước | "Trung bình tuần này chỉ uống 4 ly/ngày" |

- **KHÔNG detect (deferred):**
  - P2 (ăn khuya) → cần tracking giờ chính xác, dễ sai
  - P4 (lặp món) → nice-to-have, chưa impact mạnh

- **Data window: Mix (C3)**
  - 3 ngày → cảnh báo sớm (nhẹ)
  - 7 ngày → insight đáng tin (mạnh)
  - Tránh spam cảnh báo hoặc phản hồi quá chậm

- **Rules:**
  - Max 2-3 insight / lần
  - Luôn kèm action cụ thể
  - Tone nhẹ nhàng, không phán xét

### Memory Insight — Hiển thị (MINS-02)

- **Gộp vào Daily Summary card (D1):**
  - Không thêm card riêng → không spam UI
  - User đã có context "review ngày" → đúng timing để đưa insight
  - Section "Insight" nằm bên dưới summary chính

### UI & Design — Daily Summary Card

- **Layout: E3 — Compact + auto-expand khi cần**
  - Mặc định compact: icon + "Hôm nay: 1850/2000 kcal ✅" (1 dòng)
  - Nếu có insight đáng kể → tự expand (macros, insight, gợi ý)
  - Animation nhẹ, smooth (0.2-0.3s)
  - Tap khi compact → cũng expand được (manual toggle)
  - Card tự thu nhỏ/mờ sau 1 ngày (chỉ hiển thị "Hôm qua")

- **Vị trí: F1 — Ngay dưới Streak card**
  - Flow tự nhiên: Greeting → Streak (động lực) → Summary (phản hồi) → Meals (hành động)
  - Motivation → Feedback → Action

- **Compact state:**
  ```
  📊 Hôm nay: 1850 / 2000 kcal ✅
  ```

- **Expanded state (khi có insight):**
  ```
  📊 Hôm nay: 1850 / 2000 kcal

  Protein: 45g | Carbs: 250g | Fat: 60g

  ⚠️ Bạn đang thiếu protein 3 ngày gần đây

  👉 Gợi ý: Thêm trứng vào bữa sáng
  ```

## Code Context

### Reusable Assets
- `ContextBuilder.swift` — Đã có 4 mode (chat, suggestion, mealTab, voiceParse). Thêm mode `dailySummary` mới
- `AIService.swift` — Pattern gọi Gemini/OpenAI, tái sử dụng cho summary generation
- `MemoryManager.swift` + `UserProfileMemory.swift` — Memory system đã hoàn chỉnh
- `MealRepository.swift` — `fetchMeals(by:)` và `fetchMeals(from:to:)` cho query data
- `ReminderService.swift` — Local notification scheduling pattern (dùng cho push summary)
- `StreakCardView.swift` — Pattern card trên Home, tham khảo style cho Summary card
- `HomeView.swift` — Integration point chính, đã có Streak card + Mic button
- `HomeViewModel.swift` — Đã có pattern load data ngày hôm nay

### Patterns
- `@Observable` macro cho ViewModels
- `StreakCardView` layout pattern cho expandable cards
- Repository pattern cho data access
- `ContextBuilder` mode pattern cho AI prompt building
- `ReminderService` notification scheduling pattern

## Canonical Refs
- `.planning/REQUIREMENTS.md` — DSUM-01, DSUM-02, MINS-01, MINS-02
- `.planning/ROADMAP.md` — Phase 13 scope
- `LiiO_EatClean/Features/Home/HomeView.swift` — Integration point chính
- `LiiO_EatClean/Features/Home/HomeViewModel.swift` — Dashboard data loading
- `LiiO_EatClean/Features/AI/ContextBuilder.swift` — AI prompt builder (4 modes)
- `LiiO_EatClean/Features/AI/AIService.swift` — AI API caller
- `LiiO_EatClean/Services/MemoryManager.swift` — Memory persistence
- `LiiO_EatClean/Data/Models/UserProfileMemory.swift` — Memory data model
- `LiiO_EatClean/Data/Repositories/MealRepository.swift` — Meal data access
- `LiiO_EatClean/Features/AI/ReminderService.swift` — Notification scheduling
- `LiiO_EatClean/Features/Home/Components/StreakCardView.swift` — Card style reference

## Deferred Ideas
- P2 (ăn khuya detection) — cần tracking giờ chính xác
- P4 (lặp món detection) — nice-to-have, low impact
- Weekly Insight report (tổng hợp tuần) — phase riêng
- Full trend engine (so sánh tuần/tháng) — scale lên từ B2
- AI-driven push notification content (personalized message) — v2
