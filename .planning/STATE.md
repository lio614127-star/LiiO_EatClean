---
milestone: v1.5
status: planning
progress:
  phases_completed: 2
  phases_total: 7
---

# Project State

- [x] **Phase 25: Date-Aware Planning Foundation**
  - Goal: Cấu trúc lại hệ thống lập kế hoạch để lưu trữ an toàn theo ngày và không ghi đè dữ liệu lịch sử.
  - Requirements: PLAN-04, PLAN-05, PLAN-06, PLAN-07
  - Success Criteria:
    1. DailyPlan sinh ra gắn chặt với startOfDay và tồn tại trong CoreData.
    2. Chọn ngày cũ xem được Plan cũ.
    3. Weekly Plan tạo ra 7 bản ghi DailyPlan tách biệt.
  - Last activity: Phase 25 verified (UAT Passed)
  - Resume file: .planning/phases/26-planned-vs-actual-journal/26-PLAN.md

- [x] **Phase 26: Planned vs Actual UI Engine (Smart Daily Journal)**
  - Goal: Biến tab Planning thành "Nhật ký thông minh" - tổng hợp cả kế hoạch AI và thực tế ăn uống.
  - Requirements: UI-01, UI-02, UI-03, UI-04, UI-05
  - Success Criteria:
    1. UI hiển thị timeline: Planned Meals (Tickable) + Actual Logs (Unplanned).
    2. Smart Linking: Gợi ý gắn món ăn thực tế với món trong kế hoạch.
    3. Delta & Adherence Score được tính toán thời gian thực.
  - Status: Completed (Unified Timeline & Smart Linking Implemented)

- [/] **Phase 27: Calendar Heatmap & Adherence**
  - Goal: Cung cấp góc nhìn toàn cảnh về kỷ luật ăn uống thông qua biểu đồ nhiệt.
  - Requirements: HEAT-01, HEAT-02, HEAT-03
  - Success Criteria:
    1. Lịch tháng hiển thị màu sắc dựa trên Adherence Score.
    2. Tap vào ngày để mở chi tiết lịch sử (Journal).
  - Status: Planned. Ready for execution.
  - Resume file: .planning/phases/27-calendar-heatmap-adherence/27-01-PLAN.md

## Active Context

### Memory (Decisions & Workarounds)
- `MealFoodModel.isEaten` is currently handled by `MealFoodStatusManager` (UserDefaults) rather than a persistent CoreData attribute. This needs to be synced carefully when we upgrade the UI to Planned vs Actual.
- `MealType` string matching must be strictly adhered to across UI ("Sáng", "Trưa", "Tối", "Ăn vặt").
- Calorie target updates reactively on weight logging via `UserRepository`.

### Known Blockers
- CoreData currently lacks `DailyPlan`, `WeeklyPlan`, `ChatSession`, and `ChatMessage` entities. A lightweight migration/addition is required for Phase 25 and Phase 29.
- Audio permissions must be requested before initializing the global Wake Phrase detector in Phase 30.

## Implementation Notes
- **Local-first focus:** All new entities (`DailyPlan`, `ChatMessage`) MUST be added to CoreData.
- **Do not overwrite plans:** We must check for existing plans via `startOfDay` normalized dates.
- **Rebalance boundary:** Rebalance logic must strictly filter out meals where `isEaten == true`.
