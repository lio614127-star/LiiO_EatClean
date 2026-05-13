# Roadmap

## Vision
Trợ lý AI toàn diện: Ghi nhớ, Lắng nghe, và Tự động thích nghi với từng thay đổi nhỏ của người dùng.

## Milestones

<details>
<summary>✅ v1.0 - v1.2 Foundation & AI Assistant (Phases 1-20) — SHIPPED</summary>
*See previous milestone archives.*
</details>

<details>
<summary>✅ v1.3 Trợ lý Dinh dưỡng Toàn năng & Tiện lợi (Phases 21-22) — SHIPPED</summary>
*See previous milestone archives.*
</details>

<details>
<summary>✅ v1.4 Nâng cấp Phân tích & Trải nghiệm (Phases 23-24) — SHIPPED</summary>
*See previous milestone archives.*
</details>

### 🚀 v1.5 Trợ lý AI Toàn diện (Voice, Heatmap & Rebalance)

- [x] **Phase 25: Date-Aware Planning Foundation**
  - Goal: Cấu trúc lại hệ thống lập kế hoạch để lưu trữ an toàn theo ngày và không ghi đè dữ liệu lịch sử.
  - Requirements: PLAN-04, PLAN-05, PLAN-06, PLAN-07
  - Success Criteria:
    1. DailyPlan sinh ra gắn chặt với startOfDay và tồn tại trong CoreData.
    2. Chọn ngày cũ xem được Plan cũ.
    3. Weekly Plan tạo ra 7 bản ghi DailyPlan tách biệt.

- [x] **Phase 26: Two-Layer Execution (Home integration)**
  - Goal: Đưa kế hoạch vào đời thực thông qua Home tab mà không gây cản trở việc log món tự do.
  - Requirements: UI-01, UI-04, UI-05, PLAN-08
  - Success Criteria:
    1. Home hiển thị card "Next Planned Meal" với nút "Đã ăn".
    2. Log món khớp plan tự động link (Smart Linking).
    3. Log món khác cùng mealType gợi ý "Thay thế" (replaced status).
    4. Calories thực tế chỉ tính từ Actual MealLogs, không double count với Plan.

- [x] **Phase 27: Calendar Heatmap & Adherence**
  - Goal: Cung cấp góc nhìn toàn cảnh về kỷ luật ăn uống thông qua biểu đồ nhiệt.
  - Requirements: HEAT-01, HEAT-02, HEAT-03
  - Success Criteria:
    1. Lịch tháng hiển thị màu sắc dựa trên Adherence Score.
    2. Tap vào ngày để mở chi tiết lịch sử (Journal).

- [x] **Phase 28: AI Rebalance & Smart Correction**
  - Goal: Tái cấu trúc tự động các bữa chưa ăn dựa trên độ lệch thực tế.
  - Requirements: REBAL-01, REBAL-02, REBAL-03
  - Success Criteria:
    1. AI nhận diện các bữa status "replaced" hoặc "skipped" để cân đối lại macro.
    2. Nút "Tái cấu trúc" hoạt động mượt mà chỉ cho các bữa chưa ăn.

- [x] **Phase 29: Chat Persistence Fix**
  - Goal: Đảm bảo lịch sử trò chuyện AI Coach không bị mất khi thoát ứng dụng.
  - Requirements: VOICE-06
  - Success Criteria:
    1. ChatSession và ChatMessage hoạt động ổn định trên CoreData.
    2. Mở app lên giữ nguyên phiên chat cũ.
  - Status: Completed (UAT Passed)

- [/] **Phase 30: In-App Voice Assistant & Global Wake Phrase**
  - Goal: Trải nghiệm Hands-free đích thực, nói là hiểu.
  - Requirements: VOICE-01, VOICE-02, VOICE-03, VOICE-04
  - Success Criteria:
    1. Nói "Hey LiiO" trong app thì AI lắng nghe.
    2. Auto-send khi dừng nói.
    3. Đổi tên AI hoạt động hoàn hảo.
  - Progress: 2/5 plans complete

- [ ] **Phase 31: Global Context Builder cho AI Coach**
  - Goal: AI Coach đọc và hiểu mọi dữ liệu người dùng để tư vấn như một con người thực sự.
  - Requirements: VOICE-05
  - Success Criteria:
    1. AI trả lời chính xác số calo còn thiếu và món đang chờ trong Plan.
    2. Không bịa dữ liệu và tuân thủ ràng buộc dị ứng.

## Progress

- **Phases Complete:** 29
- **Phases Active:** 30
- **Phases Pending:** 1
- **Completion:** 94% (29/31)

---
*Last updated: 2026-05-12 for Milestone v1.5*
