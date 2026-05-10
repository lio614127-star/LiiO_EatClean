# Phase 23: Advanced Chart Visualization & Custom Date Range - Context

**Gathered:** 2026-05-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Nâng cấp hệ thống biểu đồ Progress Tab lên chuẩn Apple Health, bao gồm: Custom Date Range Picker, Smart Aggregation theo tuần/tháng (Average/Day), Min/Max Overlay cho Calories, và Smooth Line cho Weight.

</domain>

<decisions>
## Implementation Decisions

### Giao diện Custom Date Range Picker
- **D-01:** Sử dụng Segment thứ 4 với text "Custom" (chứ không phải icon setting). Segment này sẽ đổi text thành `Từ ngày–Đến ngày` khi user đã chọn (VD: `01/05–31/05`).
- **D-02:** Mở Bottom Sheet compact (không full screen, không push navigation) khi bấm chọn Custom.
- **D-03:** Bottom Sheet cần bao gồm Quick Presets (Hôm nay, 7 ngày, 30 ngày, 90 ngày, Năm nay) trước phần chọn Date, đi kèm với Live Preview text (VD: "31 ngày • Weekly aggregation").
- **D-04:** Aggregation tự động thay đổi theo range: ≤31 ngày (daily), 32-120 ngày (weekly avg), >120 ngày (monthly avg). Không yêu cầu user chọn tay chế độ aggregate.

### Min/Max Overlay cho Calories
- **D-05:** Dùng `RangeMark` với opacity thấp (15-20%) làm background cho cột `BarMark` để hiển thị dải Min/Max trong thời gian được aggregate.
- **D-06:** Visual hierarchy: Cột chính (Solid) > Goal line (Dashed) > Range Overlay (Blur/Opacity).
- **D-07:** Không hiển thị Overlay trong chế độ xem Daily (≤31 ngày), chỉ bật khi ở Weekly/Monthly.
- **D-08:** Có thể thêm tint cảnh báo nhẹ trên overlay nếu Max vượt mức quá cao (binge day anomaly).

### Weight Chart trong chế độ Aggregation
- **D-09:** Dùng `LineMark` với smooth interpolation (cong mượt) làm gốc, kèm `AreaMark` gradient nhẹ phía dưới để tạo chiều sâu. KHÔNG nối các điểm nhọn, không dùng Point rời rạc.
- **D-10:** KHÔNG vẽ Min/Max Overlay cho Weight để tránh tạo stress do biến động (fluctuations).
- **D-11:** Gom nhóm trung bình theo tuần/tháng (chứ không vẽ các điểm dao động hàng ngày).
- **D-12:** Đặt Trend Badge trực tiếp trên header: `Cân nặng      ↓ -1.2kg / 30N`.
- **D-13:** Thêm text nhỏ hiển thị Goal Proximity (VD: "Còn 2.4kg tới mục tiêu").

### Swipe Navigation giữa các khoảng thời gian
- **D-14:** Sử dụng "Pagination Swipe" (Vuốt chuyển trang) thay vì Free Scroll trên trục ngang. Chart layer chỉ dùng để hiển thị dữ liệu hiện tại, navigation được handle qua một wrapper layer.
- **D-15:** Vuốt sang trái/phải sẽ tải cục thời gian kế tiếp/trước đó tương ứng (ví dụ: vuốt từ "Tuần này" sang "Tuần trước", hoặc "Tháng 5" sang "Tháng 4"). Đối với Custom Range, lùi tiến theo khoảng tương đương.
- **D-16:** Header Date phải cập nhật linh hoạt (VD: "12-18 May", "May 2026").
- **D-17:** Thêm nút tắt "Hôm nay" (Today) khi user vuốt đi xa để nhảy về hiện tại.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Features & Ideas
- `.planning/capture/custom-date-range-chart.md` — Chi tiết quy tắc Smart Aggregation và Visualization rules được thiết lập trước đó.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ProgressTabView`: Component chính quản lý giao diện, đang dùng Picker cho TimeRange.
- `ProgressViewModel`: ViewModel cần cập nhật logic fetch dữ liệu Custom Range và Trend Calculation.
- `CalorieChartView` / `WeightChartView`: Cần refactor để hỗ trợ Swipe Pagination (loại bỏ `.chartScrollableAxes`).

</code_context>

<specifics>
## Specific Ideas
- Thiết kế mang phong cách "Premium Apple Health-like", hướng tới sự calm, smooth, wellness-focused (không dùng design kiểu biểu đồ tài chính).
- Tránh dùng các animation phức tạp khi vuốt chuyển trang (chỉ dùng fade + slight slide nhẹ).

</specifics>

<deferred>
## Deferred Ideas
- **Trend Smoothing Mode:** Thêm toggle chuyển đổi giữa Raw data và Smoothed data (như MacroFactor) đã được lưu lại thành idea/seed để làm ở bản cập nhật v1.4 hoặc v1.5 tương lai.

</deferred>

---

*Phase: 23-Advanced Chart Visualization & Custom Date Range*
*Context gathered: 2026-05-10*
