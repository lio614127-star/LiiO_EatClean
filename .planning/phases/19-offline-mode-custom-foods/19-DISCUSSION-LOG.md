# Phase 19: Offline Mode & Custom Foods - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-08
**Phase:** 19-offline-mode-custom-foods
**Areas discussed:** Offline Detection & Degradation, Custom Food Builder UX, Custom Food trong Search & Priority, Offline Queueing cho AI Features

---

## Area 1: Offline Detection & Degradation

### Q1: Cách detect network status

| Option | Description | Selected |
|--------|-------------|----------|
| A — NWPathMonitor singleton | Tạo `NetworkMonitor` class, publish `isConnected` reactive. Chuẩn Apple, lightweight. | ✓ |
| B — Passive fail-detect | Không chủ động monitor. Khi API fail → set flag. Retry để check lại. | |
| C — You decide | Agent chọn approach phù hợp nhất. | |

**User's choice:** A — NWPathMonitor singleton
**Notes:** User provided detailed architecture: `isConnected`, `connectionType` enum (wifi/cellular/ethernet/unknown), `isExpensive`. Centralized — tất cả services route qua 1 singleton. Feature availability matrix clearly defined. Floating banner (not popup). PendingTaskQueue for recovery. Connection recovery events (auto-retry).

### Q2: AI buttons khi offline

| Option | Description | Selected |
|--------|-------------|----------|
| A — Disabled + tooltip | Nút grayed out, tap → context-aware toast. | ✓ |
| B — Hidden hoàn toàn | Ẩn tất cả nút AI. | |
| C — Hiển thị bình thường | Chỉ báo lỗi khi tap. | |

**User's choice:** A — Disabled + subtle feedback
**Notes:** Opacity 0.45-0.6, saturation giảm. Context-aware toast (not generic "no internet") 1.5-2s. Chat input vẫn gõ được khi offline (send disabled). Speech: on-device vẫn record, cloud disable. Consistent state toàn app via @EnvironmentObject.

---

## Area 2: Custom Food Builder UX

### Q1: Entry point

| Option | Description | Selected |
|--------|-------------|----------|
| A — Nút "+" trong FoodSearchView | "+" header + CTA empty state "Tạo món mới". Flow tự nhiên. | ✓ |
| B — Tab/Section riêng trong AddMealView | Segment "Món của tôi" toggle. | |
| C — Từ Profile/Settings | "Quản lý món ăn" trong Profile. | |

**User's choice:** A — Entry trực tiếp trong FoodSearchView
**Notes:** Sheet presentation (CustomFoodBuilderSheet). Required: Name/Cals/P/C/F. Optional: Serving size/Notes/Category/Brand/Photo. Auto-calculate `4P+4C+9F`. Realtime validation. "Lưu & Log ngay" dual button. Custom foods sync into AI context.

### Q2: Edit/delete custom foods

| Option | Description | Selected |
|--------|-------------|----------|
| A — Swipe actions trong search | Swipe left → Edit/Delete. | ✓ (primary) |
| B — "Món của tôi" trong Profile | Management screen. | deferred |
| C — Long press context menu | Edit/Duplicate/Delete popup. | ✓ (secondary) |

**User's choice:** A + C combo
**Notes:** Primary: swipe. Secondary: long press with Duplicate feature (clone → modify). Delete: swipe + undo toast (not alert). Edit: opens prefilled CustomFoodBuilderSheet. Model: add createdAt/updatedAt. "My Foods" in Profile deferred to future.

---

## Area 3: Custom Food trong Search & Priority

### Q1: Section display

| Option | Description | Selected |
|--------|-------------|----------|
| A — Section riêng "⭐ Món của bạn" | Luôn trên cùng, 3+ sections rõ ràng. | ✓ |
| B — Mix với local results + badge | Chung section, badge phân biệt. | |
| C — Floating chip bar filter | "Tất cả / Món của tôi / Gần đây" chips. | |

**User's choice:** A — Section riêng "⭐ Món của bạn"
**Notes:** Section order: ⭐ Custom → 🕘 Recent → 📦 Offline → 🌐 API. Only show when has data. Visual: ⭐ icon + tint + "Custom" pill. Save animation. Search priority: exact custom → exact recent → exact local → fuzzy → API. Chip filter deferred.

---

## Area 4: Offline Queueing cho AI Features

### Q1: Queue scope

| Option | Description | Selected |
|--------|-------------|----------|
| A — Chỉ queue Chat messages | Lightweight, high ROI. | ✓ |
| B — Queue tất cả AI actions | Chat + Meal + Voice. Complex. | |
| C — Không queue, chỉ block | User tự bấm lại khi online. | |

**User's choice:** A — Queue chỉ Chat messages
**Notes:** PendingChatMessage model (id, text, createdAt, conversationID). Persist CoreData (survives restart). Pending bubble "🕘 Đang chờ kết nối...". Auto-send on reconnect. Retry: "Đã gửi" or "Thử lại". Only user content — no AI state. Meal Plan/Voice/Suggestions → disable only (v1).

---

## Agent's Discretion

None — user provided detailed decisions for all areas.

## Deferred Ideas

- "My Foods" management screen trong Profile (future, khi 50+ custom foods)
- Queue meal plans, voice uploads offline → v2
- Chip filter bar search (All | Mine | Recent) → future
- `isExpensive` detection → warn before heavy AI on cellular
- Cloud sync custom foods → v2.0 CloudKit
