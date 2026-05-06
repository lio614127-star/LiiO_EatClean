# LiiO EatClean

## What This Is

LiiO EatClean là app iOS theo dõi calories và bữa ăn hàng ngày, giúp người dùng đạt mục tiêu giảm cân. App tập trung vào trải nghiệm log đồ ăn nhanh gọn, dashboard trực quan với progress ring, và tab AI Meals thông minh — gợi ý bữa ăn cá nhân hóa với khả năng học thói quen (memory system), ưu tiên món Việt Nam. Thiết kế theo phong cách Apple-native với SwiftUI, bo góc mềm mại và animation mượt.

## Core Value

User có thể log bữa ăn và xem calories hôm nay trong vòng 5 giây — nhanh, đẹp, chính xác.

## Current Milestone: v1.2 Cá nhân hoá sâu & Trợ lý ảo toàn diện

**Goal:** Chuyển đổi LiiO EatClean thành trợ lý dinh dưỡng hiểu người dùng ở mức độ cá nhân hoá sâu nhất (bệnh lý, sở thích, tính cách), hoạt động mượt mà (song song API, offline mode) và giao tiếp linh hoạt (Voice Chat).

**Target features:**
- AI Memory Hub (Quản lý toàn bộ thông tin cá nhân)
- API Key Pool + Auto Swap + Parallel Calls
- Voice Chat cho AI Coach
- Health-Aware AI (Ràng buộc bệnh lý khắt khe)
- Insight Detection Engine (Mở rộng)
- Offline Mode cho Core Features
- Custom Food Builder
- Context Compression Engine
- AI Personality Settings

## Requirements

### Validated

- ✓ App foundation, CoreData schema, Tab bar navigation — v1.0
- ✓ Splash screen với logo custom + auto transition — v1.0
- ✓ Onboarding slides + Setup Goal (tính calories bằng Mifflin-St Jeor) — v1.0
- ✓ Home Dashboard (progress ring, summary, quick add) — v1.0
- ✓ Add Meal Flow (search hybrid local JSON + CalorieNinjas) — v1.0
- ✓ Progress Screen (Swift Charts cho cân nặng và calories) — v1.0
- ✓ Profile & Settings (quản lý API keys, mục tiêu) — v1.0
- ✓ Water tracking & Smart reminders — v1.0
- ✓ AI Nutritionist Chatbox — v1.0
- ✓ AI-Powered Meals Tab (Smart Suggestions, Context Memory, Log Ngay) — v1.0

- ✓ Voice Input: Cho phép người dùng nói để log nhanh đồ ăn — v1.1
- ✓ Barcode Scan: Quét mã vạch sản phẩm để tra cứu nhanh calories — v1.1
- ✓ Daily AI Summary: Tóm tắt hành vi ăn uống cuối ngày và đưa ra lời khuyên — v1.1
- ✓ AI Meal Planning: Sinh thực đơn theo ngày/tuần dựa trên memory và calo mục tiêu — v1.1
- ✓ Streak Tracking: Đếm và hiển thị chuỗi ngày hoàn thành log bữa ăn/mục tiêu calo — v1.1
- ✓ Advanced Memory Insight: Nhận diện pattern chưa tốt (ví dụ: thiếu protein, ăn khuya) — v1.1
- ✓ UI Polish: Thêm haptic feedback, micro-animations khi tương tác — v1.1

### Active

- [ ] AI Memory Hub: Màn hình quản lý toàn bộ Profile, Calories, Health, Preferences, Notes (chuyển icon từ Meals sang AI Coach).
- [ ] API Infrastructure Upgrade: Quản lý nhiều API keys, auto swap, gọi API song song để giảm latency.
- [ ] Voice Chat: Giao tiếp với AI Coach bằng giọng nói (Speech-to-text).
- [ ] Health-Aware AI: Ràng buộc tuyệt đối không đề xuất món ăn cấm/kỵ theo bệnh lý người dùng.
- [ ] Insight Expansion: Mở rộng các logic nhận diện hành vi (lặp món, lệch macro dài ngày).
- [ ] Offline Mode: Log bữa ăn không cần mạng, đồng bộ sau.
- [ ] Custom Food Builder: Cho phép người dùng tự định nghĩa món ăn và lưu local.
- [ ] Context Compression: Nén nội dung memory và lịch sử chat để giảm token usage.
- [ ] AI Personality: Tuỳ chỉnh văn phong AI (nghiêm túc, thân thiện, chill).
- [ ] HealthKit integration (sync weight, calories) — *Pending backlog*
- [ ] Macro tracking (protein, carbs, fat breakdown chi tiết hơn) — *Pending backlog*

### Out of Scope

- Workout tracking — làm loãng focus của app, core value là meal/calorie tracking
- Community chat — rất tốn công, không phải core value
- Android version — build native iOS trước, Android làm riêng sau nếu cần
- Multi-device sync — v1 local-only, chuẩn bị schema cho sync sau
- Firebase/backend — overkill cho v1, local CoreData đủ dùng

## Context

**Target user:** Người Việt Nam muốn giảm cân, theo dõi calories hàng ngày. App cá nhân (LiiO).

**Current State (v1.1 Shipped):** Hoàn thành v1.1, nâng cấp mạnh mẽ tốc độ log bữa ăn (Voice, Barcode) và tính chủ động của AI (Daily Summary, Meal Planning). Các tương tác UI đã được mượt mà hóa với haptic và micro-animations.

## Constraints

- **Platform**: iOS only — SwiftUI, minimum iOS 17+
- **Tech stack**: Swift + SwiftUI native — không cross-platform
- **Data**: CoreData local-first — Repository pattern
- **Food API**: CalorieNinjas fallback cho local JSON
- **AI API**: OpenAI hoặc Gemini (tích hợp multi-key)
- **Design**: Apple-style — SF Pro font, bo góc 16-24px, màu xanh lá #4CAF50, custom app icon/logo.
- **Architecture**: MVVM + Repository

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Swift + SwiftUI native | UI mượt, animation nhiều, HealthKit-ready | ✓ Good |
| CoreData local-first | Đơn giản cho v1, không cần backend | ✓ Good |
| Hybrid food database | Lợi thế cạnh tranh: hỗ trợ món Việt instant | ✓ Good |
| AI Chat & Learning Memory | Nâng cao UX cá nhân hóa, prompt injection tối ưu token | ✓ Good |
| Repository pattern | Tách data layer → dễ bảo trì và test | ✓ Good |
| Ephemeral State (UserDefaults) | Hỗ trợ lưu trạng thái nhỏ không cần migration CoreData | ✓ Good |

## Evolution

This document evolves at phase transitions and milestone boundaries.

---
*Last updated: 2026-05-06 after v1.1 milestone completion*
