# LiiO EatClean

## What This Is

LiiO EatClean là app iOS theo dõi calories và bữa ăn hàng ngày, giúp người dùng đạt mục tiêu giảm cân. App tập trung vào trải nghiệm log đồ ăn nhanh gọn, dashboard trực quan với progress ring, và tab AI Meals thông minh — gợi ý bữa ăn cá nhân hóa với khả năng học thói quen (memory system), ưu tiên món Việt Nam. Thiết kế theo phong cách Apple-native với SwiftUI, bo góc mềm mại và animation mượt.

## Core Value

User có thể log bữa ăn và xem calories hôm nay trong vòng 5 giây — nhanh, đẹp, chính xác.

## Current Milestone: v1.3 Trợ lý Dinh dưỡng Toàn năng & Tiện lợi

**Goal:** Hiện đại hoá hạ tầng dữ liệu dinh dưỡng, tối ưu hoá tốc độ lập kế hoạch, và cung cấp trải nghiệm hướng dẫn nấu ăn chi tiết ngay từ thực đơn gợi ý.

**Target features:**
- **Turbo Daily Planning:** Tối ưu hóa AI Orchestration để lên kế hoạch ngày trong < 10 giây.
- **Smart Unit & Recipe Detail:** Tự động nhận diện đơn vị (chén, dĩa, cái, gram) và hiển thị bóc tách nguyên liệu chi tiết cho món ăn.
- **AI Cooking Coach:** Hướng dẫn nấu ăn từng bước tỉ mỉ thông qua kết nối trực tiếp với AI Coach từ thực đơn.
- **Interactive Plan Editor:** Cho phép người dùng chỉnh sửa plan của AI, chọn món thay thế (Top 10 gợi ý) hoặc tự thêm món.
- **Meal Variety Logic:** Thuật toán chống lặp món và ưu tiên thực đơn thuần Việt, nguyên liệu dễ tìm.
- **HealthKit Integration:** Đồng bộ cân nặng và calories với Apple Health (Cơ bản).
- **Macro Tracking:** Hiển thị chi tiết tỉ lệ Protein, Carbs, Fat với biểu đồ trực quan.

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

### Active

- [ ] Turbo Daily Planning (All-in-one Prompting)
- [ ] Smart Unit Recognition (chén, dĩa, gram...)
- [ ] Recipe Detail View (Ingredient breakdown)
- [ ] AI Cooking Coach Integration (Deep-link to Chat)
- [ ] Magic Swap Feature (Interactive Plan Editor)
- [ ] Anti-Repeat & Vietnamese Priority Logic
- [ ] HealthKit Integration (Basic sync)
- [ ] Macro Tracking Dashboard

### Out of Scope

- Workout tracking — làm loãng focus của app
- Community chat — không phải core value
- Android version — build native iOS trước
- Multi-device sync — v1 local-only

## Context

**Target user:** Người Việt Nam muốn giảm cân, theo dõi calories hàng ngày.

**Current State (v1.2 Shipped):** LiiO EatClean đã trở thành một trợ lý AI toàn diện với khả năng ghi nhớ sâu sắc người dùng, hỗ trợ voice chat, hoạt động offline và bảo vệ sức khoẻ thông qua ràng buộc bệnh lý. Giao diện biểu đồ đã đạt chuẩn premium.

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
| Swift + SwiftUI native | UI mượt, HealthKit-ready | ✓ Good |
| CoreData local-first | Đơn giản, không cần backend | ✓ Good |
| Hybrid food database | Hỗ trợ món Việt instant | ✓ Good |
| AI Chat & Learning Memory | UX cá nhân hóa sâu | ✓ Good |
| Parallel API Calls | Giảm latency đáng kể cho AI Planning | ✓ Good |
| Consolidated Insights | Giảm clutter cho Home screen | ✓ Good |

## Evolution

This document evolves at phase transitions and milestone boundaries.

---
*Last updated: 2026-05-09 after v1.2 milestone completion*
