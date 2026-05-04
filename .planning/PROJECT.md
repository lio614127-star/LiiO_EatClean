# LiiO EatClean

## What This Is

LiiO EatClean là app iOS theo dõi calories và bữa ăn hàng ngày, giúp người dùng đạt mục tiêu giảm cân. App tập trung vào trải nghiệm log đồ ăn nhanh gọn, dashboard trực quan với progress ring, và tab AI Meals thông minh — gợi ý bữa ăn cá nhân hóa với khả năng học thói quen (memory system), ưu tiên món Việt Nam. Thiết kế theo phong cách Apple-native với SwiftUI, bo góc mềm mại và animation mượt.

## Core Value

User có thể log bữa ăn và xem calories hôm nay trong vòng 5 giây — nhanh, đẹp, chính xác.

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

### Active

- [ ] Scan food (camera scan món ăn)
- [ ] HealthKit integration (sync weight, calories)
- [ ] Macro tracking (protein, carbs, fat breakdown chi tiết hơn)

### Out of Scope

- Workout tracking — làm loãng focus của app, core value là meal/calorie tracking
- Community chat — rất tốn công, không phải core value
- Android version — build native iOS trước, Android làm riêng sau nếu cần
- Multi-device sync — v1 local-only, chuẩn bị schema cho sync sau
- Firebase/backend — overkill cho v1, local CoreData đủ dùng

## Context

**Target user:** Người Việt Nam muốn giảm cân, theo dõi calories hàng ngày. App cá nhân (LiiO).

**Current State (v1.0 MVP Shipped):** App đang có đầy đủ tính năng cốt lõi cho việc tracking calories. AI System đã phát triển từ chatbot cơ bản thành một hệ thống thông minh (Learning System) có thể tự trích xuất sở thích, dị ứng của user vào Memory và dùng đó làm context injection cho các Tab gợi ý món ăn. Các bug liên quan đến logic đồ thị, navigation và sheet reload đã được khắc phục. UI/UX đạt chuẩn Apple design guidelines. 

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
*Last updated: 2026-05-04 after v1.0 MVP milestone completion*
