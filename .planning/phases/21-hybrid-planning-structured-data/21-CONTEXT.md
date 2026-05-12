# Phase 21: Next-Gen Nutrition & AI Planning Update — Context

**Date:** 2026-05-09
**Status:** In Progress
**Codes:** PLAN, UNIT, COOK, EDIT

## Domain

Nâng cấp trải nghiệm AI Planning từ cơ chế distributed sang Single-pass Streaming để tối ưu tốc độ (<10s). Chuyển đổi Food Schema sang dạng Composed Food (có nguyên liệu, hướng dẫn) và hỗ trợ Smart Units. Xây dựng cầu nối giữa Meal Planning và AI Cooking Coach.

## Requirements

- **PLAN-01**: Single-pass Day Planning (latency < 10s)
- **PLAN-02**: Streaming UI (fill meal by meal)
- **UNIT-01**: Smart Units (chén, tô, dĩa, gram)
- **COOK-03**: AI Coach Deep-link with structured context injection
- **EDIT-02**: Magic Swap (Local-first engine < 0.5s)

## Decisions

### 1. Turbo Planning Architecture
- **Decision:** Bỏ Master Planner cho Day Plan. Dùng 1 prompt All-in-one.
- **Model:** Ưu tiên Gemini 1.5 Flash (v1beta) cho tốc độ và khả năng streaming.
- **Parsing:** Dùng `AsyncThrowingStream` và custom block-parser để nhận diện món ngay khi AI vừa stream xong 1 khối JSON của bữa đó.

### 2. Smart Unit Logic
- **Decision:** Dual-display `1 chén (~200g)`.
- **Conversion:** App tự động convert khi user đổi đơn vị. Macros/Calories sẽ scale theo trọng lượng thực tế so với trọng lượng chuẩn của đơn vị đó.

### 3. Recipe Storage (Hybrid)
- **Decision:** 
  - **Ingredients:** Lưu Local DB/Cache ngay khi tạo plan (để dùng cho swap/grocery).
  - **Instructions:** Cache sau lần đầu fetch AI chi tiết (để tiết kiệm quota và hỗ trợ offline).

### 4. AI Coach Integration
- **Decision:** Chuyển hẳn sang Tab Brain (AI Coach).
- **Injection:** Không chỉ navigate mà còn gửi một `StructuredPayload` chứa Recipe Card để AI Coach "biết" user đang nấu gì, định lượng bao nhiêu mà không cần hỏi lại.

### 5. Magic Swap Engine
- **Decision:** Local-first priority.
- **Variety Memory:** Engine sẽ kiểm tra lịch sử ăn uống gần đây để giảm priority của các món vừa ăn (vd: nếu đã ăn yến mạch quá nhiều, Swap sẽ né yến mạch).

## Canonical Refs
- `LiiO_EatClean/Features/AI/AIOrchestrator.swift` -> Refactor `generateDayPlanBatched`
- `LiiO_EatClean/Features/Meals/MealPlanViewModel.swift` -> Streaming integration & Local Swap
- `LiiO_EatClean/Data/Models/FoodItemModel.swift` -> Schema upgrade
- `LiiO_EatClean/Features/Chat/ChatViewModel.swift` -> Structured Context Handling
