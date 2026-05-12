# Phase 25 Discussion Log

**Area:** CoreData Schema
- Options: Tái sử dụng hay tạo mới?
- Selected: Tạo mới (`DailyPlan`, `PlannedMeal`, `PlannedFoodItem`)
- Notes: Tránh dùng chung entity để không gây nhầm lẫn tổng calo. Actual intake remains only in Meal/MealFood. Khi user check Đã ăn, copy data sang.

**Area:** Migration
- Options: Migrate hay bắt đầu sạch?
- Selected: Bắt đầu sạch.
- Notes: Không migrate UserDefaults cũ. Từ v1.5 dùng CoreData DailyPlan làm source of truth.

**Area:** Date Picker UX
- Options: Horizontal, Inline Calendar, hay Wheel?
- Selected: Horizontal date strip chính, Calendar Sheet phụ.
- Notes: Horizontal strip là giao diện chính, Calendar cho những ngày xa.

**Area:** Drafts
- Options: Hủy hay Lưu tạm khi rời màn hình?
- Selected: Lưu Draft vào CoreData (`status = draft`).
- Notes: Auto-cleanup sau 24h. Cần phân biệt rõ với Confirmed plan. Mở app lại nếu có draft thì hiển thị tùy chọn Tiếp tục/Bỏ qua/Tạo mới.
