# Phase 14: AI Meal Planning Engine — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-05
**Phase:** 14-ai-meal-planning
**Areas discussed:** Phạm vi kế hoạch, UI thực đơn, Hành động Áp dụng, AI Generation

---

## Area 1: Phạm vi lên thực đơn — Theo ngày hay theo tuần?

### Q1: Scope kế hoạch cho v1

| Option | Description | Selected |
|--------|-------------|----------|
| Chỉ kế hoạch ngày | AI sinh 3-4 bữa cho hôm nay/ngày mai. Đơn giản, token thấp. | |
| Kế hoạch ngày + preview tuần | Ngày là chính, nhưng có nút "Lên kế hoạch tuần" sinh 7 ngày. | ✓ |
| Full kế hoạch tuần | Luôn sinh 7 ngày, user browse từng ngày. | |

**User's choice:** Option 2 — Kế hoạch ngày (core) + preview tuần (optional)
**Notes:** "Daily decision assistant + optional planning". Default = đơn giản, Advanced = khi user yêu cầu. Ngày = chi tiết, Tuần = overview compact.

### Q2: Phân bổ calorie budget

| Option | Description | Selected |
|--------|-------------|----------|
| AI tự quyết phân bổ | 1 call, AI tự chia tỷ lệ | |
| Tỷ lệ cố định theo template | App chia trước, 4x API calls | |
| AI phân bổ + app validate | AI tự chia, app check tổng ≤ target ±5% | ✓ |

**User's choice:** Option 3 — AI phân bổ + app validate
**Notes:** Trim snack → dinner nếu vượt. "AI đề xuất, App kiểm soát."

---

## Area 2: UI thực đơn — Hiển thị kế hoạch

### Q3: Vị trí hiển thị kế hoạch

| Option | Description | Selected |
|--------|-------------|----------|
| Section mới trong Meals tab | Thêm section giữa Memory và AI Suggestion | |
| Sheet riêng (full-screen) | Nút "✨ Lên kế hoạch" → fullScreenCover | ✓ |
| Tab con trong Meals | Segmented control: "Hôm nay" / "Kế hoạch" | |

**User's choice:** Option 2 — Full-screen sheet riêng
**Notes:** "Planning ≠ Tracking. Flow lớn → tách màn hình. Không nhét vào list."

### Q4: Layout bên trong sheet

| Option | Description | Selected |
|--------|-------------|----------|
| Cards xếp dọc (ScrollView) | Mỗi bữa = 1 card, scroll dọc, CTA per card | ✓ |
| Accordion / expandable sections | 4 collapsed sections, tap expand | |
| Timeline dọc | Line dọc + 4 nodes, visual lộ trình | |

**User's choice:** Option 1 — Cards xếp dọc
**Notes:** Reuse card pattern hiện tại. "UI giúp quyết định nhanh". Max 2-3 món/card. CTA "Log bữa này" rõ ràng.

### Q5: Weekly overview UI

| Option | Description | Selected |
|--------|-------------|----------|
| List compact 7 dòng | Mỗi dòng: ngày + kcal + highlight món. Tap → chi tiết. | ✓ |
| Horizontal scroll 7 cards nhỏ | 7 mini cards scroll ngang. Tap → expand. | |
| Calendar grid mini | Lưới 7 ô, mỗi ô kcal + emoji. Tap → chi tiết. | |

**User's choice:** Option 1 — List compact 7 dòng
**Notes:** "Overview = nhanh + đủ thông tin. Detail = màn riêng." Reuse day plan UI cho chi tiết.

---

## Area 3: Hành động "Áp dụng"

### Q6: Cách log kế hoạch

| Option | Description | Selected |
|--------|-------------|----------|
| Log từng bữa only | Mỗi card có "Log bữa này", không có bulk | |
| Log từng bữa + "Áp dụng tất cả" | Per-card CTA + nút bulk ở cuối + confirm dialog | ✓ |
| Chỉ "Áp dụng tất cả" | 1 nút log toàn bộ, không log riêng | |

**User's choice:** Option 2 — Cả hai
**Notes:** "Nhanh khi cần, linh hoạt khi muốn." Source = "meal_plan" cho tracking. Bắt buộc có confirm dialog cho bulk log.

### Q7: Trạng thái sau khi log

| Option | Description | Selected |
|--------|-------------|----------|
| Card đổi trạng thái visual | Card ✅ + xám + disable CTA. Vẫn ở sheet. | |
| Auto-dismiss sau khi log | Toast → dismiss sheet. Mỗi lần mở = generate mới. | |
| Card trạng thái + auto-dismiss khi hết | ✅ từng card, auto-dismiss khi log hết 4 bữa | ✓ |

**User's choice:** Option 3 — Card trạng thái + auto-dismiss khi log hết
**Notes:** "Đang làm → giữ context. Làm xong → đóng flow." Fade + scale animation. Haptic `.success` per meal, mạnh hơn khi hoàn thành. Disable "Áp dụng tất cả" khi đã log hết.

---

## Area 4: AI Generation

### Q8: ContextBuilder strategy mới

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal (calories + memory cơ bản) | ~300 tokens, AI tự quyết variety | |
| Rich (calories + memory + history + insights) | ~600 tokens, luôn inject tất cả | |
| Adaptive (base + conditional inject) | Base luôn có, thêm history/insights khi có data | ✓ |

**User's choice:** Option 3 — Adaptive
**Notes:** Base = kcal + preferences/avoidFoods. IF ≥3 days history → inject (tránh lặp). IF insights → inject. Max 3-5 history, 1-2 insights. "Chỉ gửi những gì cần thiết."

### Q9: AI output format

| Option | Description | Selected |
|--------|-------------|----------|
| Flat array + mealType field | items[] với mealType per item. Reuse AISuggestedFood. | ✓ |
| Nested object theo bữa | {breakfast:[], lunch:[], ...}. Cần model mới. | |

**User's choice:** Option 1 — Flat array + mealType
**Notes:** Reuse 100% AISuggestedFood model. Action = "meal_plan". "Flat > Nested cho AI output." mealType cần mapping layer (app dùng Vietnamese, cần quyết định English enum vs Vietnamese matching).

---

## Agent's Discretion

- mealType mapping strategy (Vietnamese vs English enum + mapping) — planner decides based on existing patterns
- Exact trim algorithm for calorie validation (proportional scaling vs fixed-priority trim)
- Weekly plan generation: 1 large API call vs 7 individual calls — planner decides based on token budget

## Deferred Ideas

- Weekly plan persistence (lưu kế hoạch tuần để xem lại) — v2
- Meal plan sharing — out of scope
- Meal plan editing (chỉnh sửa từng món trước khi log) — v2
- Meal plan templates (save/reuse) — phase riêng
- AI regenerate specific meal — v2 enhancement
- Grocery list from meal plan — feature mới hoàn toàn
