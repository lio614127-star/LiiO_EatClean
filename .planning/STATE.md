---
gsd_state_version: 1.0
milestone: v1.5
milestone_name: Trợ lý AI Toàn diện
status: Executing Phase 30
last_updated: "2026-05-13T07:49:38.921Z"
progress:
  total_phases: 10
  completed_phases: 3
  total_plans: 14
  completed_plans: 6
  percent: 43
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

- [x] **Phase 27: Calendar Heatmap & Adherence**
  - Goal: Cung cấp góc nhìn toàn cảnh về kỷ luật ăn uống thông qua biểu đồ nhiệt.
  - Requirements: HEAT-01, HEAT-02, HEAT-03
  - Success Criteria:
    1. Lịch tháng hiển thị màu sắc dựa trên Adherence Score.
    2. Tap vào ngày để mở chi tiết lịch sử (Journal).
  - Status: Completed (Heatmap & Adherence Snapshotting Implemented)
  - Last activity: Phase 27 verified.
- [x] **Phase 28: AI Rebalance & Smart Correction**
  - Goal: Triển khai hệ thống tự động tái cấu trúc bữa ăn khi người dùng ăn lệch kế hoạch.
  - Success Criteria:
    1. Tự động phát hiện lệch Calo (>10%) hoặc Protein (>15g) để kích hoạt gợi ý.
    2. Proactive UI: Card trên Home và Banner trên Journal.
    3. AI Rebalance: Chỉnh portion trước, swap sau, tôn trọng món đã ăn và món bị khóa (Locked).
    4. Giao diện Preview so sánh "Trước & Sau" trực quan.
  - Status: Completed (Service, UI & Core Rules Implemented)

- [x] **Phase 29: Chat Persistence & Model Refactoring**
  - Goal: Đảm bảo lịch sử trò chuyện AI Coach không bị mất khi thoát ứng dụng.
  - Success Criteria:
    1. ChatSessionEntity và ChatMessageEntity hoạt động ổn định trên CoreData.
    2. Model Logic (ChatMessageModel) được tách biệt hoàn toàn khỏi CoreData Entities.
    3. Mở app lên giữ nguyên phiên chat cũ, hỗ trợ tạo Chat mới.
  - Status: Completed (UAT Passed)
  - Last activity: Phase 29 verified.

### Memory (Decisions & Workarounds)

- `MealFoodModel.isEaten` is currently handled by `MealFoodStatusManager` (UserDefaults) rather than a persistent CoreData attribute. This needs to be synced carefully when we upgrade the UI to Planned vs Actual.
- `MealType` string matching must be strictly adhered to across UI ("Sáng", "Trưa", "Tối", "Ăn vặt").
- Calorie target updates reactively on weight logging via `UserRepository`.

### Known Blockers

- CoreData currently lacks `DailyPlan`, `WeeklyPlan`, `ChatSession`, and `ChatMessage` entities. A lightweight migration/addition is required for Phase 25 and Phase 29.
- [/] **Phase 30: In-App Voice Assistant & Global Wake Phrase**
  - Goal: Trải nghiệm Hands-free đích thực, nói là hiểu.
  - Requirements: VOICE-01, VOICE-02, VOICE-03, VOICE-04
  - Success Criteria:
    1. Nói "Hey LiiO" trong app thì AI lắng nghe.
    2. Auto-send khi dừng nói.
    3. Đổi tên AI hoạt động hoàn hảo.
  - Status: Executing Plan 4 of 5
  - Last activity: Plan 4 (AI Pipeline) completed.

## Implementation Notes

- **Local-first focus:** All new entities (`DailyPlan`, `ChatMessage`) MUST be added to CoreData.
- **Do not overwrite plans:** We must check for existing plans via `startOfDay` normalized dates.
- **Rebalance boundary:** Rebalance logic must strictly filter out meals where `isEaten == true`.
