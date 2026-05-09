# Requirements: LiiO EatClean v1.3

**Defined:** 2026-05-09
**Core Value:** Trợ lý Dinh dưỡng Toàn năng & Tiện lợi - Lập kế hoạch siêu tốc, hướng dẫn nấu ăn chi tiết và linh hoạt chỉnh sửa.

## v1.3 Requirements

### 1. Turbo Daily Planning (Performance)
- [ ] **PLAN-01**: Tối ưu hóa AI Orchestration để xử lý plan ngày trong một lần gọi duy nhất (Single-pass), giảm latency xuống dưới 10 giây.
- [ ] **PLAN-02**: Áp dụng Streaming UI để hiển thị kết quả món ăn ngay khi AI đang phản hồi, giảm cảm giác chờ đợi cho người dùng.
- [ ] **PLAN-03**: Hệ thống tự động kiểm tra tính đa dạng (Anti-repeat logic) dựa trên lịch sử 3 ngày gần nhất, đảm bảo không trùng món (trừ Favorites).

### 2. Smart Unit & Recipe Detail
- [ ] **UNIT-01**: Hệ thống tự động nhận diện đơn vị đo lường phù hợp cho từng món ăn (chén, dĩa, tô, cái, gram) thay vì chỉ dùng "phần".
- [ ] **UNIT-02**: Cho phép chuyển đổi linh hoạt giữa đơn vị ước lượng (chén/cái) và đơn vị định lượng (gram) để người dùng dễ dàng theo dõi.
- [ ] **UNIT-03**: Nâng cấp Data Schema để lưu trữ thông tin bóc tách nguyên liệu (Ingredients breakdown) cho các món ăn phức hợp.

### 3. AI Cooking Coach Integration
- [ ] **COOK-01**: Thẻ chi tiết món ăn hiển thị danh sách nguyên liệu và định lượng tương ứng (vd: 150g cá, 1 chén cơm).
- [ ] **COOK-02**: Nút "AI dạy nấu ăn" trong thẻ chi tiết món ăn cho phép chuyển hướng nhanh sang tab AI Coach.
- [ ] **COOK-03**: Tự động chuyển danh sách nguyên liệu của món ăn đang xem sang AI Coach để bắt đầu hướng dẫn nấu ăn từng bước tỉ mỉ.

### 4. Interactive Plan Editor (Cá nhân hóa)
- [ ] **EDIT-01**: Người dùng có thể bấm vào từng bữa ăn trong plan để mở giao diện chỉnh sửa/thay thế món.
- [ ] **EDIT-02**: Tính năng "Magic Swap": Gợi ý danh sách 10 món thay thế có tương đồng về Kcal/PCF với món hiện tại.
- [ ] **EDIT-03**: Cho phép người dùng tự tìm kiếm và thêm món thủ công vào plan, hệ thống tự động tính toán lại tổng dinh dưỡng trong ngày.

### 5. Data & Health Integration
- [ ] **DATA-01**: Đồng bộ dữ liệu Calories đã nạp từ LiiO sang ứng dụng Apple Health (HealthKit basic).
- [ ] **DATA-02**: Đồng bộ dữ liệu Cân nặng giữa LiiO và Apple Health.
- [ ] **DATA-03**: Dashboard Macro chi tiết hiển thị biểu đồ tròn/thanh cho tỉ lệ Protein, Carbs, Fat trong ngày.

## Out of Scope
- Chế độ nấu ăn bằng giọng nói (Voice-controlled cooking mode) - để dành cho v1.4.
- Đồng bộ dữ liệu luyện tập (Workout sync) từ HealthKit - ưu tiên dinh dưỡng trước.

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PLAN-01 | Phase 21 | [ ] |
| PLAN-02 | Phase 21 | [ ] |
| PLAN-03 | Phase 21 | [ ] |
| UNIT-01 | Phase 21 | [ ] |
| UNIT-02 | Phase 21 | [ ] |
| UNIT-03 | Phase 21 | [ ] |
| COOK-01 | Phase 21 | [ ] |
| COOK-02 | Phase 21 | [ ] |
| COOK-03 | Phase 21 | [ ] |
| EDIT-01 | Phase 21 | [ ] |
| EDIT-02 | Phase 21 | [ ] |
| EDIT-03 | Phase 21 | [ ] |
| DATA-01 | Phase 22 | [ ] |
| DATA-02 | Phase 22 | [ ] |
| DATA-03 | Phase 22 | [ ] |

---
*Requirements defined: 2026-05-09 for Milestone v1.3*
