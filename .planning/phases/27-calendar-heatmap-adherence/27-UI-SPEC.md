---
phase: 27
slug: calendar-heatmap-adherence
status: draft
shadcn_initialized: false
preset: none
created: 2026-05-13
---

# Phase 27 — UI Design Contract

> Visual and interaction contract for frontend phases.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | SwiftUI Native |
| Preset | Apple Human Interface Guidelines (HIG) |
| Component library | none |
| Icon library | SF Symbols |
| Font | San Francisco (System) |

---

## Spacing Scale

Declared values (must be multiples of 4):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon gaps, inline padding |
| sm | 8px | Compact element spacing |
| md | 16px | Default element spacing |
| lg | 24px | Section padding |
| xl | 32px | Layout gaps |
| 2xl | 48px | Major section breaks |

---

## Typography

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | 17pt | Regular | Native |
| Label | 13pt | Medium | Native |
| Heading | 22pt | Bold | Native |
| Display | 34pt | Semibold | Native |

---

## Color (Discrete Heatmap)

| Role | Value | Usage |
|------|-------|-------|
| Excellent (>=90) | Color.mint | Heatmap square (Tier 5) |
| Good (75-89) | Color.green | Heatmap square (Tier 4) |
| Fair (60-74) | Color.yellow | Heatmap square (Tier 3) |
| Poor (40-59) | Color.orange | Heatmap square (Tier 2) |
| Critical (<40) | Color.red | Heatmap square (Tier 1) |
| No Data | Color.gray.opacity(0.2) | Heatmap square (Empty) |

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Legend Item 1 | Tuyệt vời (>= 90) |
| Legend Item 2 | Rất tốt (75-89) |
| Legend Item 3 | Bám sát plan (60-74) |
| Legend Item 4 | Cần chú ý (40-59) |
| Legend Item 5 | Lệch mục tiêu (< 40) |
| Detail CTA | Xem chi tiết Journal |
| Empty Month | Chưa có dữ liệu tuân thủ cho tháng này. |

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| Native SwiftUI | all | not required |

---

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: PASS
- [ ] Dimension 2 Visuals: PASS
- [ ] Dimension 3 Color: PASS
- [ ] Dimension 4 Typography: PASS
- [ ] Dimension 5 Spacing: PASS
- [ ] Dimension 6 Registry Safety: PASS

**Approval:** pending
