# Requirements: LiiO EatClean v1.1

**Defined:** 2026-05-04
**Core Value:** Nâng cao tốc độ log bữa ăn qua đa phương thức (Voice, Barcode) và biến AI thành huấn luyện viên cá nhân chủ động.

## v1.1 Requirements

### Daily AI Summary
- [ ] **AISUM-01**: Tự động sinh tóm tắt cuối ngày (lượng calo đã ăn vs mục tiêu).
- [ ] **AISUM-02**: AI đưa ra nhận xét hành vi ăn uống (tốt/chưa tốt) và gợi ý cải thiện cho ngày mai.

### Streak & Gamification
- [ ] **STRK-01**: Logic tính toán chuỗi ngày (streak) log đủ bữa, đạt target calo, và uống đủ nước.
- [ ] **STRK-02**: Hiển thị trạng thái streak (lửa/biểu tượng) trên Home Dashboard để khuyến khích duy trì.

### Voice Input
- [ ] **VOIC-01**: Tích hợp Speech-to-Text cho phép thu âm giọng nói (vd: "Tôi ăn 1 bát phở").
- [ ] **VOIC-02**: AI tự động parse văn bản thành món ăn (local DB hoặc API fallback) và cho phép log nhanh.

### AI Meal Planning
- [ ] **PLAN-01**: AI gợi ý thực đơn ăn uống cho ngày hoặc tuần dựa trên sở thích, calo mục tiêu và bệnh lý.
- [ ] **PLAN-02**: Nút "Áp dụng" hoặc "Log nhanh" để tự động thêm thực đơn được lên kế hoạch vào log bữa ăn.

### Barcode Scan
- [ ] **SCAN-01**: Tích hợp camera để quét mã vạch (Barcode) của sản phẩm.
- [ ] **SCAN-02**: Tra cứu mã vạch qua API (OpenFoodFacts hoặc CalorieNinjas) để lấy calories cơ bản và log vào bữa ăn.

### Advanced Memory Insight
- [ ] **MEMO-01**: AI phân tích pattern lịch sử bữa ăn để tìm thói quen (VD: ăn quá nhiều buổi tối, thiếu protein).
- [ ] **MEMO-02**: Tự động hiển thị các cảnh báo insight hoặc đề xuất cải thiện thói quen trên tab AI Meals hoặc Chat.

### UI Polish & Micro-interactions
- [ ] **UIPL-01**: Bổ sung Haptic Feedback (Core Haptics) cho các thao tác log meal, update progress, nhận thưởng streak.
- [ ] **UIPL-02**: Nâng cấp các vi-chuyển động (micro-animations) khi chuyển trạng thái card món ăn, lưu meal thành công.

## Out of Scope (for v1.1)
- Multi-device CloudKit sync (Defer sang v2.0 do cần migration phức tạp).
- Social sharing/Community (Không nằm trong core value).
- Advanced Recipe Builder (Chỉ tập trung vào log nhanh).

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| AISUM-01 | Phase 13 | [ ] |
| AISUM-02 | Phase 13 | [ ] |
| STRK-01 | Phase 11 | [ ] |
| STRK-02 | Phase 11 | [ ] |
| VOIC-01 | Phase 12 | [ ] |
| VOIC-02 | Phase 12 | [ ] |
| PLAN-01 | Phase 14 | [ ] |
| PLAN-02 | Phase 14 | [ ] |
| SCAN-01 | Phase 12 | [ ] |
| SCAN-02 | Phase 12 | [ ] |
| MEMO-01 | Phase 13 | [ ] |
| MEMO-02 | Phase 13 | [ ] |
| UIPL-01 | Phase 11 | [ ] |
| UIPL-02 | Phase 11 | [ ] |

---
*Requirements defined: 2026-05-04 for Milestone v1.1*
