# Requirements: LiiO EatClean v1.3

**Defined:** 2026-05-09
**Core Value:** Tối ưu hóa hiệu năng và chiều sâu dữ liệu — Chuyển dịch từ AI-centic sang Hybrid Architecture.

## v1.3 Requirements

### 1. Hybrid Planning Engine (Tối ưu tốc độ)
- [ ] **PLAN-01**: App tự động tính toán Calorie Split cho các bữa trong ngày (Sáng, Trưa, Tối, Snack) dựa trên TDEE mà không cần gọi AI.
- [ ] **PLAN-02**: Hệ thống tự động lọc danh sách "Candidate Meals" (từ Favorites, món Việt phổ biến, món đã log) phù hợp với kcal split và avoid foods.
- [ ] **PLAN-03**: Chỉ gọi AI một lần duy nhất (Single Pass) để lựa chọn và sắp xếp các món từ Candidate Pool thành Daily Plan hoàn chỉnh.
- [ ] **PLAN-04**: Tốc độ sinh Daily Plan mục tiêu đạt dưới 10 giây (so với 25-50s hiện tại).

### 2. Smart Unit System (FoodPortionProfile)
- [ ] **UNIT-01**: Triển khai `FoodPortionProfile` cho từng món ăn, hỗ trợ các đơn vị đo lường phổ biến của Việt Nam (chén, tô, dĩa, gram).
- [ ] **UNIT-02**: Hệ thống hỗ trợ quy đổi Gram tương ứng cho từng đơn vị (vd: 1 chén cơm = 200g).
- [ ] **UNIT-03**: Hỗ trợ Density Layer (Trọng lượng riêng) để phân biệt đơn vị thể tích (vd: 1 muỗng dầu khác 1 muỗng cơm).

### 3. Structured Meal Details (Dữ liệu sâu)
- [ ] **MEAL-01**: Lưu trữ thông tin bữa ăn dưới dạng cấu trúc (Components/Ingredients) thay vì chỉ một chuỗi văn bản.
- [ ] **MEAL-02**: Cho phép người dùng chỉnh sửa (edit) hoặc thay đổi (swap) từng thành phần trong một món ăn phức hợp.
- [ ] **MEAL-03**: Hệ thống tự động tính toán lại Macro/Calories thời gian thực khi thành phần món ăn thay đổi.

### 4. AI Cooking Assistant (Step-by-step)
- [ ] **COOK-01**: Chế độ "Cooking Instructor": AI hướng dẫn nấu ăn chi tiết từng bước dựa trên `Recipe Context Card`.
- [ ] **COOK-02**: Hỗ trợ Voice Command cơ bản trong khi nấu ("Tiếp theo", "Lùi lại", "Xong").
- [ ] **COOK-03**: AI trả lời các câu hỏi kỹ thuật nấu ăn liên quan đến món đang nấu (vd: "Lửa lớn hay nhỏ?", "Chiên bao lâu?").

### 5. Diversity Engine (Chống trùng món)
- [ ] **DIVE-01**: Mỗi món ăn trong database được gắn metadata về loại Protein, Cuisine, Phương pháp chế biến.
- [ ] **DIVE-02**: Áp dụng quy tắc Diversity: Hạn chế lặp lại cùng một loại thành phần chính (vd: yến mạch, ức gà) quá 2 lần/tuần (ngoại trừ món Favorites).

### 6. Local Swap UI (Instant UX)
- [ ] **SWAP-01**: Cho phép người dùng nhấn Swap trên một slot món ăn trong kế hoạch để đổi món tức thì.
- [ ] **SWAP-02**: Việc đề xuất món thay thế được thực hiện bởi App-side logic (Local Engine) dựa trên kcal target mà không cần gọi API AI.

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PLAN-01-04  | Phase 21 | [ ] |
| UNIT-01-03  | Phase 21 | [ ] |
| MEAL-01-03  | Phase 21 | [ ] |
| COOK-01-03  | Phase 22 | [ ] |
| DIVE-01-02  | Phase 22 | [ ] |
| SWAP-01-02  | Phase 22 | [ ] |

---
*Requirements defined: 2026-05-09 for Milestone v1.3*
