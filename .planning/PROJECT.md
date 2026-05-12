# LiiO EatClean

## What This Is

LiiO EatClean là app iOS theo dõi calories và bữa ăn hàng ngày, giúp người dùng đạt mục tiêu giảm cân. App tập trung vào trải nghiệm log đồ ăn nhanh gọn, dashboard trực quan với progress ring, và tab AI Meals thông minh — gợi ý bữa ăn cá nhân hóa với khả năng học thói quen (memory system), ưu tiên món Việt Nam. Thiết kế theo phong cách Apple-native với SwiftUI, bo góc mềm mại và animation mượt.

## Core Value

User có thể log bữa ăn và xem calories hôm nay trong vòng 5 giây — nhanh, đẹp, chính xác.

## Current Milestone: v1.5 [TBD]

**Goal:** [Mục tiêu sẽ được xác định qua /gsd-new-milestone]

**Target features:**
- [Gợi ý: Tối ưu hóa hiệu năng, AI Coaching chuyên sâu, UI Analytics mở rộng]

## Requirements

### Validated

<details>
<summary>✓ v1.0 - v1.2: Foundation & AI Assistant</summary>

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
- ✓ Daily AI Summary: Tóm tắt hành vi ăn uống cuối ngày — v1.1
- ✓ AI Meal Planning: Sinh thực đơn theo ngày/tuần dựa trên memory — v1.1
- ✓ Streak Tracking: Đếm và hiển thị chuỗi ngày hoàn thành log — v1.1
- ✓ Advanced Memory Insight: Nhận diện pattern chưa tốt — v1.1
- ✓ UI Polish: Thêm haptic feedback, micro-animations — v1.1
- ✓ AI Memory Hub: Quản lý Profile, Calories, Health, Preferences — v1.2
- ✓ API Infrastructure Upgrade: Quản lý multi-keys, auto swap, parallel calls — v1.2
- ✓ Voice Chat: Giao tiếp với AI Coach bằng giọng nói (Speech-to-text) — v1.2
- ✓ Health-Aware AI: Ràng buộc tuyệt đối không đề xuất món ăn cấm/kỵ — v1.2
- ✓ Insight Expansion: Nhận diện thói quen lặp món, lệch macro — v1.2
- ✓ Offline Mode: Hoạt động đầy đủ tính năng core khi không có mạng — v1.2
- ✓ Custom Food Builder: Tự định nghĩa món ăn cá nhân lưu local — v1.2
- ✓ Context Compression: Nén history chat/memory tối ưu token — v1.2
- ✓ AI Personality: Tuỳ chỉnh văn phong AI (5 tone presets) — v1.2
- ✓ Pro Chart UX: Biểu đồ 3 tháng, smart labels, weight gradient — v1.2
</details>

<details>
<summary>✓ v1.3 Trợ lý Dinh dưỡng Toàn năng & Tiện lợi</summary>

- ✓ Turbo Daily Planning (All-in-one Prompting)
- ✓ Smart Unit Recognition (chén, dĩa, gram...)
- ✓ Recipe Detail View (Ingredient breakdown)
- ✓ AI Cooking Coach Integration (Deep-link to Chat)
- ✓ Magic Swap Feature (Interactive Plan Editor)
- ✓ Anti-Repeat & Vietnamese Priority Logic
- ✓ Macro Tracking Dashboard
</details>

<details>
<summary>✓ v1.4 Nâng cấp Phân tích & Trải nghiệm</summary>

- ✓ Advanced Chart Visualization (Swipe pagination, Apple Health style)
- ✓ Smart Data Aggregation (Daily/Weekly/Monthly)
- ✓ Metabolic Intelligence Engine (Adaptive TDEE, Goal History)
- ✓ AI Coaching Cards (Insight-driven goal updates)
- ✓ Reactive Calorie Target Sync
- ✓ Stability & Performance Polish
</details>

### Active

(Define next steps via `/gsd-new-milestone`)

### Out of Scope

- Workout tracking — làm loãng focus của app
- Community chat — không phải core value
- Android version — build native iOS trước
- Multi-device sync — v1 local-only
- HealthKit Integration — Removed (2026-05-12)

## Context

**Target user:** Người Việt Nam muốn giảm cân, theo dõi calories hàng ngày.

**Current State (v1.4 Shipped):** LiiO EatClean đã trở thành một nền tảng quản lý dinh dưỡng thông minh vượt trội. App không chỉ gợi ý món ăn mà còn chủ động phân tích sự thích nghi của cơ thể (Metabolic AI), hỗ trợ theo dõi Macro chi tiết và cung cấp trải nghiệm phân tích dữ liệu chuyên nghiệp (Advanced Charts).

## Constraints

- **Platform**: iOS only — SwiftUI, minimum iOS 17+
- **Tech stack**: Swift + SwiftUI native
- **Data**: CoreData local-first
- **Food API**: CalorieNinjas fallback cho local JSON
- **AI API**: OpenAI hoặc Gemini (tổng hợp multi-key)
- **Architecture**: MVVM + Repository

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Swift + SwiftUI native | UI mượt, nhanh gọn | ✓ Good |
| CoreData local-first | Đơn giản, không cần backend | ✓ Good |
| Hybrid food database | Hỗ trợ món Việt instant | ✓ Good |
| AI Chat & Learning Memory | UX cá nhân hóa sâu | ✓ Good |
| Parallel API Calls | Giảm latency đáng kể cho AI Planning | ✓ Good |
| Consolidated Insights | Giảm clutter cho Home screen | ✓ Good |
| Metabolic Intelligence | Tự động thích ứng mục tiêu theo sinh lý | ✓ Good |

## Evolution

This document evolves at phase transitions and milestone boundaries.

---
*Last updated: 2026-05-12 after v1.4 milestone completion*
