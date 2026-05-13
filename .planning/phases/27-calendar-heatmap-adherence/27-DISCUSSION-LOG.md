# Phase 27: calendar-heatmap-adherence - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-13
**Phase:** 27-calendar-heatmap-adherence
**Areas discussed:** Color Mapping, Day Interaction, Data Strategy, Empty States

---

## Heatmap Visualization (Color Mapping)

| Option | Description | Selected |
|--------|-------------|----------|
| Discrete | 5 cấp độ màu cố định tương ứng với trạng thái kỷ luật. | ✓ |
| Gradient | Dải màu biến đổi mượt mà dựa trên điểm số chính xác. | |

**User's choice:** Discrete Color Mapping.
**Notes:** User yêu cầu tính trực quan cao, dễ đọc lướt, giống bảng thành tích GitHub nhưng biểu thị chất lượng. Sử dụng 5 cấp độ: Excellent, Good, Slightly Off, Needs Attention, Poor + No Data.

---

## Day Interaction

| Option | Description | Selected |
|--------|-------------|----------|
| Modal Sheet | Mở Half-sheet tóm tắt (Score, Macros, Insight). | ✓ |
| Navigation | Chuyển hướng hẳn sang tab Journal/Planning. | |

**User's choice:** Modal Sheet (PresentationDetents) kèm nút điều hướng sâu.
**Notes:** Giữ ngữ cảnh lịch nhưng cho phép drill-down sâu vào Journal nếu cần.

---

## Data Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Real-time | Tính toán điểm số mỗi khi mở View. | |
| Caching | Lưu Snapshot vào CoreData để tối ưu hiệu năng. | ✓ |

**User's choice:** Hybrid Snapshot Strategy.
**Notes:** Cache ngày cũ để scroll mượt, refresh live cho ngày hôm nay để đảm bảo chính xác. Snapshot lưu trữ đầy đủ context macros và counts.

---

## Empty States & Future States

| Option | Description | Selected |
|--------|-------------|----------|
| Unified | Dùng một màu chung cho ngày không dữ liệu. | |
| Contextual | Phân biệt ngày quá khứ, hôm nay và tương lai (có/không plan). | ✓ |

**User's choice:** Contextual/Hybrid.
**Notes:** Ngày quá khứ không data = Gray. Ngày tương lai có plan = Outline/Dot (indicator). Ngày tương lai không plan = Gray.

---

## the agent's Discretion

- Chi tiết thiết kế UI của Snapshot Service.
- Hiệu ứng chuyển cảnh và animation của Heatmap.

## Deferred Ideas

- Tự động gắn món khi độ khớp > 95% (v1.6).
- HealthKit Integration.
