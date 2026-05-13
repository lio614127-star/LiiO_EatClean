# Requirements: LiiO EatClean v1.5

**Status:** 🏗️ Planning
**Current Milestone:** v1.5 Trợ lý AI Toàn diện (Voice, Heatmap & Rebalance)

## v1.5 Requirements

### 1. Date-aware Daily Plan & Weekly Plan (PLAN)
- [ ] **PLAN-04**: Hệ thống quản lý DailyPlan theo ngày cụ thể (được normalize theo startOfDay).
- [ ] **PLAN-05**: Gọi AI tạo plan mới cho ngày chưa có, giữ nguyên và hiển thị plan cũ nếu ngày đã có.
- [ ] **PLAN-06**: Lên kế hoạch tuần (Weekly Plan) tạo và lưu trữ thành 7 DailyPlan riêng biệt.
- [ ] **PLAN-07**: Cho phép xem lại lịch sử ngày cũ bao gồm cả DailyPlan và Actual Meal Logs.

### 2. Planned vs Actual UI Upgrade (UI)
- [ ] **UI-01**: Tách biệt rõ ràng chỉ số Planned Totals và Actual Totals trong ngày.
- [ ] **UI-02**: Hiển thị Delta (độ chênh lệch) của Macros/Calories giữa Plan và Actual.
- [ ] **UI-03**: Thêm UI Card "Kế hoạch vs Thực tế" hiển thị Progress Bar/Ring trạng thái (đúng plan, vượt calo, thiếu protein...).
- [ ] **UI-04**: Quản lý trạng thái từng Planned Meal: "planned", "eaten", "skipped", "replaced".
- [ ] **UI-05**: Home tab hiển thị "Next Planned Meal" card với các nút hành động nhanh (Đã ăn, Đổi, Bỏ qua).
- [ ] **PLAN-08**: Logic Smart Linking & Suggestion: Tự động link khi khớp cao, gợi ý replace khi cùng mealType nhưng món khác.

### 3. AI Rebalance Remaining Meals (REBAL)
- [ ] **REBAL-01**: Phát hiện ăn lệch kế hoạch (vượt calo > 10% hoặc thiếu protein > 15g) và hiển thị thẻ "Tái cấu trúc".
- [ ] **REBAL-02**: Gọi AI Rebalance chỉ để chỉnh sửa các bữa ăn CHƯA ĂN, không ghi đè log thực tế hoặc bữa đã ăn.
- [ ] **REBAL-03**: Hiển thị Before/After preview và lưu thay đổi vào metadata (isRebalanced, rebalanceReason) khi user chốt.

### 4. Calendar Heatmap (HEAT)
- [ ] **HEAT-01**: Tạo Calendar Heatmap (dạng tháng) hiển thị màu sắc dựa trên Adherence Score.
- [ ] **HEAT-02**: Định nghĩa các trạng thái màu sắc: Xanh (tốt), Vàng (lệch nhẹ), Đỏ (lệch nhiều), Xám (trống).
- [ ] **HEAT-03**: Tap vào một ngày trên Heatmap để xem chi tiết Plan, Actual, và Adherence Score.

### 5. In-App Voice Assistant & Global Context (VOICE)
- [ ] **VOICE-01**: Tính năng "Auto-Send": Bấm micro -> nói xong (im lặng 0.8s-1.5s) -> tự stop và tự gửi vào AI Coach.
- [ ] **VOICE-02**: Hỗ trợ Global Wake Phrase ("Hey LiiO") lắng nghe khi app đang foreground.
- [ ] **VOICE-03**: Cho phép user đổi tên AI trong Settings và cập nhật tự động Wake Phrases tương ứng.
- [ ] **VOICE-04**: Lắng nghe command sau Wake Phrase và đẩy vào AI Coach pipeline, phản hồi qua Text-To-Speech (nếu bật).
- [ ] **VOICE-05**: Context Engine: Cung cấp dữ liệu thực tế (Actual meals, Plan, Target, Progress) vào prompt của AI Coach.
- [ ] **VOICE-06**: Fix dứt điểm Chat Persistence: Lưu trữ ChatSession và ChatMessage qua app restart.

## Out of Scope
- OS-level Wake Phrase ("Hey LiiO" khi màn hình tắt/app background) — Giới hạn trong app cho v1.5.
- HealthKit Integration (Removed).
- Ghi đè dữ liệu lịch sử của ngày khác.

## Traceability
| Requirement | Phase | Status |
|-------------|-------|--------|
| PLAN-04     | 25    | [ ]    |
| PLAN-05     | 25    | [ ]    |
| PLAN-06     | 25    | [ ]    |
| PLAN-07     | 25    | [ ]    |
| UI-01       | 26    | [ ]    |
| UI-02       | 26    | [ ]    |
| UI-03       | 26    | [ ]    |
| UI-04       | 26    | [ ]    |
| UI-05       | 26    | [ ]    |
| PLAN-08     | 26    | [ ]    |
| HEAT-01     | 27    | [ ]    |
| HEAT-02     | 27    | [ ]    |
| HEAT-03     | 27    | [ ]    |
| REBAL-01    | 28    | [ ]    |
| REBAL-02    | 28    | [ ]    |
| REBAL-03    | 28    | [ ]    |
| VOICE-06    | 29    | [ ]    |
| VOICE-01    | 30    | [ ]    |
| VOICE-02    | 30    | [ ]    |
| VOICE-03    | 30    | [ ]    |
| VOICE-04    | 30    | [ ]    |
| VOICE-05    | 31    | [ ]    |
