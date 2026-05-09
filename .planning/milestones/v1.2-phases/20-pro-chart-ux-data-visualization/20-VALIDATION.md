---
phase: 20
slug: pro-chart-ux-data-visualization
date: 2026-05-09
---

# Phase 20: Validation Strategy (Nyquist)

## Dimension 1: State & UI Synchronization
- [ ] Changing TimeRange from 7N -> 30N -> 3T correctly triggers data reloading and re-renders the charts without overlapping state.
- [ ] The "Empty State" displays appropriate messaging based on current data length ("Chưa có dữ liệu" vs "Cần thêm X ngày...").

## Dimension 2: Data Persistence & Lifecycle
- [ ] Weekly aggregations for 3T correctly pull 90 days of data and summarize without hanging the main thread.
- [ ] Modifying data triggers a refresh in `ProgressTabView` appropriately.

## Dimension 3: Edge Cases & Error Handling
- [ ] Very high calorie days do not break the `yAxisDomain` scaling.
- [ ] A user with only 1 day of weight entry does not break the `catmullRom` line interpolation.

## Dimension 4: User Experience & Design Contracts
- [ ] Calorie chart uses dynamic bar spacing (thinner bars on 30N).
- [ ] Weight chart uses Teal/Cyan gradient.
- [ ] Week axis uses T2-CN abbreviations. Month uses 1, 5, 10, 15, 20, 25, 30.
- [ ] Chart animations use 0.35s easeInOut on transition.
