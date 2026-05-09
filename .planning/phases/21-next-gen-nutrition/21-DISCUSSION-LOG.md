# Phase 21 Discussion Log

## Area 1: Nguồn dữ liệu Candidate Pool (Single Pass Planning)
- **Options Presented:** 50/50 Cân bằng vs Quen thuộc là chính
- **User Selected:** 50/50 Cân bằng
- **Notes/Insights:** User chỉ ra rằng nếu 100% lấy từ lịch sử sẽ dẫn đến lỗi AI lặp đi lặp lại cùng một món vô tận. Tuy nhiên, thay vì fix cứng 50/50, user đề xuất **Dynamic Ratio**: Tỷ lệ linh hoạt tùy vào độ cũ/mới của user (VD: 20/80 cho user mới, 60/40 cho user cũ). Kèm theo đó là **Diversity Score** để thuật toán App tự chủ động giảm trọng số của các món đã ăn nhiều trong tuần trước khi đưa vào candidate pool. Đây là thay đổi mang tính nền tảng (fix tận gốc).

## Area 2: Cách migrate dữ liệu cũ sang FoodPortionProfile
- **Options Presented:** Migrate toàn bộ bằng AI vs Legacy Mode
- **User Selected:** Legacy Mode (An toàn)
- **Notes/Insights:** Dùng AI convert toàn bộ dữ liệu lịch sử tiềm ẩn rủi ro lớn vì dữ liệu cũ (ví dụ: "1 bát phở") có tính nhiễu cao, mỗi quán mỗi khác. Convert tự động sẽ tạo ra fake precision và mất tính nhất quán. Thay vào đó, lịch sử sẽ ở dạng read-only compatibility. Chuẩn mới chỉ áp dụng cho dữ liệu tương lai hoặc khi user chủ động thao tác lại món cũ (On-Demand Convert).

## Area 3: Giao diện Structured Meal (Ingredient-level)
- **Options Presented:** Clean UI vs Rich UI trên màn hình Home
- **User Selected:** Clean UI (Gọn gàng)
- **Notes/Insights:** Home không phải là Recipe Browser mà là Scan Dashboard. Dồn toàn bộ list nguyên liệu ra màn hình ngoài sẽ làm nhiễu UI. Thông tin chi tiết nguyên liệu, định lượng gram, recipe, và nút AI Cooking Instructor chỉ nên hiện ra ở Detail Sheet (Progressive Disclosure). Tuy nhiên, thêm một dòng **Tiny metadata line** (VD: "3 thành phần • 28g protein") ở ngoài sẽ cung cấp đủ thông tin một cách thanh lịch.

## Area 4: Trải nghiệm Đổi món (Editable Meal Swap UX)
- **Options Presented:** Hiện Macro trực tiếp vs Tối giản (Long press để xem)
- **User Selected:** Hiện Macro trực tiếp
- **Notes/Insights:** Đổi món là quyết định mang tính dinh dưỡng, do đó thông tin Kcal, P, C, F phải hiển thị ngay lập tức (Immediate nutrition visibility). Thiết kế khuyên dùng là **Mini Macro Bars** (dạng `28P • 42C • 12F`) để không quá khô khan kỹ thuật. Tuyệt vời hơn nữa là bổ sung **Nutrition Match Badge** (nhãn đánh giá mức độ phù hợp của món ăn với mục tiêu) để tăng cường vai trò "Coach" của App.
