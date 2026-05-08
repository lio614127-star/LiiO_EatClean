# Phase 20: Pro Chart UX & Data Visualization — Discussion Log

**Date:** 2026-05-08
**Duration:** ~5 min (user provided extensive pre-decisions)
**Mode:** Default (interactive)

## Pre-Decided (from user's initial request)

The user provided 10 detailed optimization points before discussion started:
1. Week axis → T2-CN Vietnamese weekdays
2. Month axis → day numbers only
3. Smart label skipping → 1 5 10 15 20 25 30
4. Dynamic spacing by day count
5. Segmented filter → 7N | 30N | 3T
6. Scrollable chart for Month
7. Weight chart → line + gradient
8. Auto aggregate for month mode
9. Target line subtle
10. Empty state smart

## Gray Areas Discussed

### Area 1: Scroll Mechanism for Month Chart

**Options presented:**
- A) `chartScrollableAxes(.horizontal)` — native Swift Charts scroll
- B) Wrap Chart in `ScrollView(.horizontal)` — full control

**User chose:** A — Native Charts scroll
**Rationale:** Native feel, momentum + snapping mượt kiểu Apple Health, gesture conflict ít hơn, scale tốt cho mọi time range.

### Area 2: Weight Chart Gradient Color

**Options presented:**
- A) Blue gradient (keep current differentiation)
- B) Green gradient (#4CAF50, match brand)
- C) Teal/Cyan gradient (middle ground, professional)

**User chose:** C — Teal/Cyan gradient (Top: Cyan, Bottom: Teal)
**Rationale:** Calorie đã xanh lá, blue generic, teal/cyan health-tech + premium + dễ phân biệt calories vs weight.

### Area 3: 3T (3 Months) Data Aggregation

**Options presented:**
- A) Daily data + scroll (like 30N but longer)
- B) Group by week, show average/total
- C) Group by week + scrollable

**User chose:** C — Group theo tuần + scrollable
**Rationale:** 90 cột/ngày quá rối. Group theo tuần dễ đọc trend, scrollable giữ spacing đẹp.
**Extra detail:** Labels W1-W12, tap shows "Tuần 3: TB 1850 kcal/ngày"

### Area 4: Chart Animation on Time Range Change

**Options presented:**
- A) Smooth transition animation
- B) Simple fade in/out
- C) No animation

**User chose:** A — Smooth transition but subtle
**Constraints:** Duration 0.25-0.35s, curve .easeInOut, NO bounce/spring/stagger. Bars grow upward, line redraw nhẹ. Apple Fitness style.

## Deferred Ideas

- Year mode (1N) → v2.0
- Macro breakdown chart → separate phase
- Export chart as image/PDF
- Compare periods
- Goal weight line
- Dark mode color optimization

---

*16 decisions captured, 0 scope creep, 6 deferred ideas noted*
