# Phase 25 Context: Date-Aware Planning Foundation

## Domain
Chuyển đổi hệ thống lập kế hoạch từ ephemeral (UserDefaults) sang persistent (CoreData) với khả năng quản lý theo ngày cụ thể và lưu nháp (drafts).

## Canonical Refs
- PROJECT.md
- REQUIREMENTS.md
- ROADMAP.md

## Code Context
- **Meal/MealFood**: Currently handles actual logged intake.
- **MealPlanViewModel**: Currently manages UserDefaults-based planning and AI generation.
- **WeeklyPlanView**: Currently displays a 7-day layout but loses data on dismiss.

## Decisions

### 1. CoreData Schema Separation
- **Decision:** Tạo các entity tách biệt hoàn toàn cho kế hoạch: `DailyPlan`, `PlannedMeal`, `PlannedFoodItem`.
- **Reason:** Đảm bảo `Meal` và `MealFood` chỉ chứa lượng thức ăn thực tế (Actual). Ngăn chặn lỗi query tổng calo bị lẫn thức ăn dự kiến.
- **Action:** Khi người dùng đánh dấu "Đã ăn", sao chép data từ `PlannedFoodItem` sang `MealFood` (thực tế) và gán `convertedMealId` vào `PlannedMeal`.

### 2. Migration Plan Cũ
- **Decision:** KHÔNG migrate dữ liệu cũ từ UserDefaults. Bắt đầu sạch.
- **Reason:** Dữ liệu cũ ngắn hạn, cấu trúc không đủ chuẩn cho v1.5, rủi ro lỗi migration cao hơn giá trị mang lại.
- **Action:** CoreData `DailyPlan` là source of truth duy nhất. Có thể dọn dẹp key UserDefaults cũ một cách an toàn mà không cần copy.

### 3. Date Picker UX
- **Decision:** Sử dụng "Horizontal scrollable date strip" làm giao diện chọn ngày chính, kèm icon mở Calendar Sheet phụ.
- **Reason:** Tối ưu hóa cho thói quen dùng hằng ngày (hôm nay, ngày mai, hôm qua). Hiển thị trạng thái kỷ luật (màu sắc) ngay trên strip.
- **Action:** Tránh dùng Date Wheel. Tránh inline calendar chiếm toàn bộ diện tích dọc.

### 4. Xử lý Bản nháp (Drafts)
- **Decision:** Lưu kết quả trả về của AI thành Draft trong CoreData (`status = draft`). KHÔNG hủy ngay lập tức khi user rời màn hình.
- **Reason:** Tránh mất công gọi API AI (chi phí, thời gian chờ) nếu app bị background hoặc user đổi tab.
- **Action:** Nếu user quay lại, hiển thị lựa chọn: "Tiếp tục draft", "Xóa draft", "Tạo mới". Draft không được hiển thị như plan chính thức và tự động dọn dẹp sau 24h.
