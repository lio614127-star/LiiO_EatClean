# Phase 21 Context: Next-Gen Nutrition Architecture & AI Planning 2.0

## Domain
Đại tu toàn bộ kiến trúc lập kế hoạch bữa ăn, chuyển từ mô hình "AI quyết định tất cả" sang mô hình "App kiểm soát khung (constraint-based), AI tối ưu". Triển khai hệ thống nguyên liệu chi tiết (Structured Meal), chế độ dạy nấu ăn (AI Cooking Instructor) và hệ thống đơn vị thông minh.

## Decisions

### 1. Nguồn dữ liệu Candidate Pool (Single Pass Planning)
- **Tỷ lệ động (Dynamic Ratio):** Lấy pool món ăn kết hợp giữa History/Favorites và Local Vietnamese DB. Tỷ lệ này điều chỉnh linh hoạt (VD: User mới 20% history / 80% Local DB, User cũ 60% history / 40% Local DB).
- **Diversity Score:** Cân bằng thông qua chấm điểm đa dạng. Nếu món (VD: gà, yến mạch) xuất hiện nhiều trong tuần, thuật toán App sẽ giảm trọng số (weight) của chúng trước khi đẩy vào candidate pool cho AI chọn.

### 2. Migrate dữ liệu FoodPortionProfile
- **Legacy Mode (An toàn & Ổn định):** Giữ nguyên dữ liệu lịch sử bữa ăn cũ ở dạng Read-Only. Không dùng AI convert hàng loạt để tránh rủi ro hallucination và mất tính toàn vẹn dữ liệu.
- **On-Demand Convert:** Áp dụng chuẩn mới (Gram/Unit) cho các meal mới. Khi user mở/log lại món cũ, App mới tiến hành gợi ý quy đổi (convert on-demand) để user xác nhận.

### 3. Giao diện Structured Meal (Ingredient-level)
- **Clean UI (Progressive Disclosure):** Ở màn hình Home (MealCardView), giữ giao diện cực gọn: Tên món + Kcal + Tiny Metadata Line (VD: "3 thành phần • 28g protein"). Không dồn toàn bộ nguyên liệu ra màn hình ngoài.
- Chi tiết từng nguyên liệu, Recipe, và nút AI Cooking chỉ hiển thị khi user tap vào món ăn để mở Detail Sheet.

### 4. Trải nghiệm Đổi món (Editable Meal Swap UX)
- **Immediate Nutrition Visibility:** Khi list gợi ý đổi món, hiển thị trực tiếp Tên món + Kcal + Mini Macro (VD: `28P • 42C • 12F`) để user ra quyết định dinh dưỡng ngay lập tức.
- **Nutrition Match Badge:** Thêm nhãn đánh giá mức độ phù hợp ngay trên gợi ý (VD: 🟢 Rất phù hợp giảm cân / 🟡 Cần thêm protein) - nâng cấp App thành một "Coach" thực thụ.

## Canonical Refs
- `.planning/ROADMAP.md`
- `.planning/capture/ai-meal-planning-2.0.md` (Chi tiết giải pháp kỹ thuật và vấn đề)
