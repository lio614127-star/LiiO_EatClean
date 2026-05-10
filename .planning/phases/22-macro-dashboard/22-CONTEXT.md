# Phase 22: Macro Dashboard — Context

**Date:** 2026-05-10
**Status:** Discussed
**Codes:** DATA-03

## Domain

Xây dựng Dashboard Macro chi tiết hiển thị trực quan tỉ lệ Protein/Carbs/Fat, tích hợp trực tiếp bên dưới Calories Chart trong tab Tiến độ. Dashboard phải compact, scanable, và mang lại cảm giác "coach" — giúp user hiểu ngay calo đến từ đâu và cân bằng chưa.

## Scope Change

- ❌ **HealthKit Integration (DATA-01, DATA-02) — REMOVED** từ Phase 22. Lý do: ưu tiên hoàn thiện UX dinh dưỡng trước, HealthKit sẽ được xem xét trong phiên bản sau.
- ✅ Phase 22 chỉ tập trung vào **DATA-03: Macro Tracking Dashboard**.

## Decisions

### 1. Vị trí Dashboard Macro
- **Decision:** Nằm bên dưới Calories Chart trong tab Tiến độ (Option B).
- **Rationale:** Macro là context của calories, không phải metric độc lập. Tách tab riêng (Option A) sẽ thiếu liên kết và buộc user chuyển qua lại. Flow tự nhiên: Calories trend → Macro composition → Insight. User nhìn phát hiểu luôn.
- **Layout structure khi chọn tab Calories:**
  1. Calories Chart (giữ nguyên)
  2. Macro Breakdown (compact bars)
  3. Macro Insights (trend/warnings)
  4. Optional: Nutrition Score

### 2. Kiểu biểu đồ Macro
- **Decision:** Compact horizontal progress bars + Macro Goal Rings. KHÔNG dùng Pie chart to hoặc Stacked bars phức tạp.
- **Rationale:** Macro section phải compact, scanable, không chiếm nhiều chiều cao. Pie chart to đùng, graph phức tạp, stacked bars rối — đều KHÔNG phù hợp.
- **Components:**
  - **Macro Breakdown Bars:** Thanh ngang hiển thị % (P 28%, C 44%, F 28%)
  - **Macro Goal Rings:** Hiển thị % đạt mục tiêu (Protein 82% goal, Carbs 95% goal, Fat 76% goal)

### 3. Hành vi theo Time Range
- **7N (7 ngày):** Hiển thị average macro ratio (trung bình P%, C%, F% trong 7 ngày).
- **30N / 3T:** Hiển thị trend indicators nhẹ (Protein đang tăng ↑, Fat đang giảm ↓). KHÔNG render 30/90 cột macro — rất rối và vô nghĩa.

### 4. Macro Insights
- **Decision:** Cảnh báo nhẹ nhàng kiểu coaching, KHÔNG phán xét.
- **Format:** Icon màu + text ngắn (🟡 Protein hơi thấp, 🟢 Carb ổn định, 🔴 Fat vượt mục tiêu)
- **Logic:** So sánh tỉ lệ macro thực tế với tỉ lệ mục tiêu (mặc định P30/C40/F30 hoặc custom).

### 5. Nguyên tắc thiết kế
- Compact & scanable — KHÔNG chiếm nhiều chiều cao
- "Coach feel" — supportive, không phán xét
- Nhất quán với design language hiện tại (Apple-style, #4CAF50 green, bo góc)
- Macro section chỉ hiển thị khi đang ở tab Calories (không hiện ở tab Weight)

## Deferred Ideas

- **HealthKit Integration (DATA-01, DATA-02):** Đồng bộ calories và cân nặng với Apple Health — xem xét cho v1.4+
- **Deep Analytics page:** Trang phân tích riêng với micronutrients, advanced coaching — chỉ hợp khi app mature hơn
- **Customizable macro targets:** Cho phép user tự set tỉ lệ P/C/F mục tiêu — có thể thêm trong phase sau

## Canonical Refs

- `LiiO_EatClean/Features/Progress/ProgressTabView.swift` → Tích hợp Macro section bên dưới Calories Chart
- `LiiO_EatClean/Features/Progress/ProgressViewModel.swift` → Thêm macro aggregation logic
- `LiiO_EatClean/Features/Progress/Components/CalorieChartView.swift` → Giữ nguyên, Macro section nằm bên dưới
- `LiiO_EatClean/Features/Home/Components/DailySummaryCardView.swift` → Tham khảo MacroMiniBar component hiện có
- `LiiO_EatClean/Data/Repositories/MealRepository.swift` → Fetch macro data cho aggregation

## Code Context

### Reusable Assets
- `MacroMiniBar` (DailySummaryCardView.swift) — Mini progress bar cho P/C/F, có thể mở rộng
- `MacroMini` (MealItemRow.swift) — Label nhỏ "P: 25g", dùng cho chi tiết
- `MacroCard` (MealDetailSheet.swift) — Card hiển thị từng macro riêng
- `ProgressViewModel` — Đã có `calorieData`, `weightData`, `weeklyData` — cần thêm `macroData`
- `CalorieChartView` — Swift Charts implementation hiện tại, dùng làm reference cho style

### Patterns
- Tab Tiến độ dùng Picker segmented + ZStack để switch giữa charts
- Time range dùng enum `TimeRange` với 3 cases (7N, 30N, 3T)
- Data loading pattern: `viewModel.loadData()` async trong `.onAppear` và `.refreshable`
