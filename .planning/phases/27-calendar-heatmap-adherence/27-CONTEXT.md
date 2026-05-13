# Phase 27: Calendar Heatmap & Adherence - Context

**Gathered:** 2026-05-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Cung cấp góc nhìn toàn cảnh về kỷ luật ăn uống thông qua biểu đồ nhiệt (Calendar Heatmap). Phase này bao gồm việc xây dựng hạ tầng lưu trữ Snapshot kỷ luật, hiển thị bảng màu 5 cấp độ trên lịch tháng, và cho phép xem chi tiết từng ngày qua Bottom Sheet (Daily Detail).

</domain>

<decisions>
## Implementation Decisions

### 1. Heatmap Visualization (Discrete Mapping)
- **D-01:** Sử dụng 5 cấp độ màu cố định (Discrete) thay vì dải màu liên tục.
- **D-02:** Palette màu Apple-native: Deep Mint (>=90), Soft Green (75-89), Warm Yellow (60-74), Soft Orange (40-59), Soft Coral/Red (<40), Light Gray (No Data).
- **D-03:** Hình dạng ô: Rounded square (corner radius 4-6), kích thước ~32-40 cho view tháng.
- **D-04:** Legend: Bắt buộc hiển thị bảng chú giải màu sắc bên dưới lịch.

### 2. Hybrid Data Strategy (Performance)
- **D-05:** Triển khai Entity CoreData `DailyAdherenceSnapshot` để lưu trữ kết quả tính toán adherence của từng ngày.
- **D-06:** Cơ chế Hybrid:
    - **Quá khứ:** Đọc trực tiếp từ Snapshot cache. Lazy-generate nếu thiếu snapshot của ngày cũ.
    - **Hôm nay:** Tính toán real-time hoặc refresh snapshot ngay khi có thay đổi (`MealLog`, `DailyPlan`).
    - **Tương lai:** Không tính điểm, chỉ hiển thị trạng thái "Có kế hoạch" (outline/dot) nếu đã confirm DailyPlan.
- **D-07:** Snapshot có `dataVersion` để tự động rebuild khi logic tính điểm của `MealAdherenceCalculator` thay đổi.

### 3. Service Layer & Logic
- **D-08:** `DailyAdherenceSnapshotService` quản lý toàn bộ vòng đời của snapshot. 
- **D-09:** Refresh dựa trên Event (NotificationCenter/Combine): Lắng nghe các thay đổi từ MealLog, DailyPlan, Rebalance để cập nhật snapshot ngày tương ứng.

### 4. Interaction (Daily Detail Sheet)
- **D-10:** Sử dụng `PresentationDetents` (.medium, .large). Initial state là .medium.
- **D-11:** Nội dung Sheet: Hiển thị Score, Label, Macro comparison (Planned vs Actual), Insight ngắn gọn.
- **D-12:** Navigation: Luôn có nút "Xem chi tiết Journal" ở cuối sheet để chuyển sang tab Nhật ký với ngày được chọn.

### the agent's Discretion
- Kiến trúc chi tiết của `CalendarHeatmapViewModel` và cách phối hợp giữa `SnapshotService` với CoreData.
- Animation chuyển tháng và hiệu ứng highlight cho "Ngày hôm nay".

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Core Logic
- `LiiO_EatClean/Features/Meals/Services/MealAdherenceCalculator.swift` — Logic tính điểm kỷ luật chính thức.
- `LiiO_EatClean/Core/AI/AdherenceEngine.swift` — Phân tích xu hướng kỷ luật dài hạn.

### Project Specs
- `.planning/ROADMAP.md` — Định nghĩa Phase 27.
- `.planning/REQUIREMENTS.md` — HEAT-01, HEAT-02, HEAT-03.

### Data Models (Internal)
- `LiiO_EatClean/Data/Models/DailyPlanModel.swift`
- `LiiO_EatClean/Data/Models/MealModel.swift`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `MealAdherenceCalculator.shared`: Sử dụng để generate snapshot data.
- `AppColor` (nếu có): Sử dụng các token màu hệ thống thay vì hardcode.

### Established Patterns
- **Repository Pattern:** Truy cập `MealLog` và `DailyPlan` thông qua Repository hiện có.
- **@Observable macro:** Dùng cho `CalendarHeatmapViewModel`.

### Integration Points
- **Progress Tab / Home Tab:** Tích hợp Calendar Heatmap vào View.
- **Daily Journal Navigation:** Link từ Detail Sheet quay lại Planning/Journal tab.

</code_context>

<specifics>
## Specific Ideas
- "Tạo cảm giác bảng thành tích giống GitHub nhưng dùng màu sắc để biểu thị chất lượng thay vì số lượng."
- "Màu sắc không được quá gắt, không tạo cảm giác đang 'phạt' người dùng."

</specifics>

<deferred>
## Deferred Ideas
- Setting "Tự động gắn món khi độ khớp > 95%": Để dành cho v1.6.
- HealthKit Integration: Out of scope.

</deferred>

---

*Phase: 27-calendar-heatmap-adherence*
*Context gathered: 2026-05-13*
