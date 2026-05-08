# Phase 20: Pro Chart UX & Data Visualization - Context

**Gathered:** 2026-05-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Nâng cấp toàn bộ chart system trong Progress tab từ prototype lên production-grade Apple Health/Fitness style. Bao gồm: smart axis labels (Vietnamese weekday cho week, day-number cho month), smart label skipping, dynamic bar spacing, scrollable month/3-month charts, line+gradient weight chart, pro segmented time range filters (7N|30N|3T), subtle target line, smart empty states, và smooth transition animations.

Phạm vi: Chỉ refactor UI/UX của existing chart components. Không thay đổi data layer (MealRepository, UserRepository). Không thêm data models mới.

</domain>

<decisions>
## Implementation Decisions

### 1. Week Mode — X-Axis Labels

- **D-01:** Week mode hiện Vietnamese weekday abbreviations: `T2 T3 T4 T5 T6 T7 CN` thay vì `dd/MM`. Gọn cực nhiều, chuẩn Apple Health Vietnamese locale.
- **D-02:** Mapping: Monday=T2, Tuesday=T3, Wednesday=T4, Thursday=T5, Friday=T6, Saturday=T7, Sunday=CN.

### 2. Month Mode — X-Axis Labels

- **D-03:** Month mode chỉ hiện số ngày: `1 2 3 4 5 6...` — KHÔNG `dd/MM`.
- **D-04:** Smart label skipping (rất quan trọng): KHÔNG hiện đủ 30 labels. Chỉ hiện: `1 5 10 15 20 25 30`. Chart vẫn có đủ data point, chỉ giảm label density. Chuẩn Apple Health / MyFitnessPal.

### 3. 3T (3 Months) Mode — Aggregation

- **D-05:** 3T mode group data theo tuần + scrollable. 90 cột/ngày quá rối.
- **D-06:** Labels: `W1 W2 W3 W4...W12`. Tap/hover hiện tooltip: "Tuần 3: TB 1850 kcal/ngày".
- **D-07:** Calorie chart: hiện average calories/ngày cho mỗi tuần (không total).
- **D-08:** Weight chart: hiện last weight entry trong mỗi tuần.

### 4. Dynamic Spacing

- **D-09:** Dynamic bar/point spacing theo số ngày:
  - ≤7 ngày → spacing rộng (full width, no scroll)
  - 8-14 → spacing vừa
  - 30 ngày → spacing compact + horizontal scroll
  - 90 ngày (3T) → grouped by week + scroll

### 5. Scroll Mechanism

- **D-10:** Dùng `chartScrollableAxes(.horizontal)` — native Swift Charts scroll. Lý do: native feel, momentum + snapping mượt kiểu Apple Health, gesture conflict ít hơn ScrollView, scale tốt cho mọi time range.
- **D-11:** Week mode (7N): fit full width, KHÔNG scroll. Month (30N) và 3T: horizontal scroll.

### 6. Segmented Time Range Filter

- **D-12:** Thay `Tuần | Tháng` bằng `7N | 30N | 3T`. Enum mới:
  ```
  enum TimeRange: String, CaseIterable {
      case week = "7N"
      case month = "30N"
      case quarter = "3T"
  }
  ```
  Giống Apple Health style.

### 7. Weight Chart — Line + Gradient

- **D-13:** Weight chart chuyển từ point-only sang:
  - Line mềm (`interpolationMethod(.catmullRom)`)
  - Point nhỏ (symbolSize ~40, giảm từ 100)
  - Area gradient fill bên dưới line
  - Color: **Teal/Cyan gradient** — top: Cyan, bottom: Teal. Lý do: calorie đã xanh lá, blue generic, teal/cyan health-tech + premium + dễ phân biệt.
  - Annotation labels: chỉ hiện khi tap (không always-on).

### 8. Target Line — Subtle

- **D-14:** Target line calorie chart:
  - Opacity thấp hơn (~0.5)
  - Dash style giữ nguyên
  - Label nhỏ hơn (caption2)
  - Đặt góc phải trên (trailing annotation)
  - Color: `.red.opacity(0.5)` thay vì `.red`

### 9. Empty State — Smart

- **D-15:** Smart empty state messages:
  - Chưa có data: "Chưa có dữ liệu"
  - Có 1-2 ngày: "Cần thêm X ngày dữ liệu để hiển thị xu hướng"
  - Đủ data: hiện chart bình thường
  - Icon + message phù hợp context

### 10. Chart Animation

- **D-16:** Smooth transition animation khi đổi time range:
  - Calories: bars grow upward
  - Weight: line redraw nhẹ
  - Duration: 0.25s → 0.35s
  - Curve: `.easeInOut`
  - KHÔNG bounce, spring mạnh, stagger quá nhiều
  - Kiểu Apple Fitness — subtle, nhanh, không flashy

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Context
- `.planning/PROJECT.md` — App values, design constraints (Apple-style, #4CAF50, SF Pro)
- `.planning/STATE.md` — Chart UX decision from Phase 6: "X-axis padding, Y-axis 0-minimum"

### Current Chart Implementation (Primary refactor targets)
- `LiiO_EatClean/Features/Progress/ProgressTabView.swift` — Main Progress tab with Picker for tab/time range, chart switching logic
- `LiiO_EatClean/Features/Progress/ProgressViewModel.swift` — ViewModel with `TimeRange` enum (week/month), data loading, calorie aggregation
- `LiiO_EatClean/Features/Progress/Components/CalorieChartView.swift` — Bar chart with BarMark, RuleMark target line, tap-to-select annotation, dd/MM axis labels
- `LiiO_EatClean/Features/Progress/Components/WeightChartView.swift` — LineMark + PointMark (symbolSize 100), always-on weight annotations, dd/MM axis, dynamic Y domain

### Data Layer (Read-only reference — NOT modified in this phase)
- `LiiO_EatClean/Data/Repositories/MealRepository.swift` — `fetchMeals(from:to:)` for calorie data
- `LiiO_EatClean/Data/Repositories/UserRepository.swift` — `fetchWeightEntries()` for weight data
- `LiiO_EatClean/Data/Models/WeightEntryModel.swift` — Weight entry struct

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ProgressViewModel` already has `TimeRange` enum — extend with `.quarter` case
- `CalorieDailyTotal` struct — reuse for daily aggregation, add `WeeklyAggregate` for 3T mode
- `ProgressTab` enum (`.calories`, `.weight`) — no changes needed
- Swift Charts `BarMark`, `LineMark`, `PointMark`, `AreaMark`, `RuleMark` — all available
- `chartScrollableAxes(.horizontal)` — available iOS 17+
- `HapticManager` — available for chart interaction feedback

### Established Patterns
- `@Observable` ViewModel + `@State private var viewModel` in View
- `.chartGesture` for tap-to-select interaction (already in CalorieChartView)
- `.chartYScale(domain:)` for custom Y-axis range
- `.chartXScale(domain:)` for custom X-axis range
- `DateFormatter` for axis label formatting — will be replaced with custom Vietnamese labels
- Card-style chart container: `RoundedRectangle(cornerRadius: 16)` + shadow

### Integration Points
- `ProgressTabView` time range Picker — update to 3-option segmented control
- `ProgressViewModel.loadData()` — extend for 90-day (3T) range + weekly aggregation
- `CalorieChartView.chartXAxis` — replace DateFormatter with smart Vietnamese label engine
- `WeightChartView` — add AreaMark gradient, reduce symbolSize, remove always-on annotations

</code_context>

<specifics>
## Specific Ideas

- **Vietnamese weekday mapping:** Dùng `Calendar.current.component(.weekday)` → map 2=T2, 3=T3...7=T7, 1=CN
- **Smart label skipping:** Dùng `AxisMarks(values:)` với filtered array `[1, 5, 10, 15, 20, 25, 30]` thay vì show all
- **Teal/Cyan gradient:** `LinearGradient(colors: [.cyan, .teal], startPoint: .top, endPoint: .bottom)` cho AreaMark
- **Week aggregate model:** `WeeklyAggregate(weekNumber: Int, averageCalories: Double, lastWeight: Double?, dateRange: ClosedRange<Date>)`
- **Tooltip cho 3T:** `.chartOverlay` với `GeometryReader` + tap gesture → show "Tuần X: TB Y kcal/ngày"
- **Animation:** `.animation(.easeInOut(duration: 0.3), value: selectedTimeRange)` trên Chart

</specifics>

<deferred>
## Deferred Ideas

- Year mode (1N) — 12 tháng, group theo tháng → v2.0
- Macro breakdown chart (protein/carbs/fat riêng) — separate phase
- Export chart as image/PDF — future
- Compare periods (tuần này vs tuần trước) — future
- Goal weight line trên weight chart — future enhancement
- Dark mode chart color optimization — future polish

</deferred>

---

*Phase: 20-pro-chart-ux-data-visualization*
*Context gathered: 2026-05-08*
*Decisions: 16 captured across 10 categories*
