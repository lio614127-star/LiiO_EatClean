# Phase 18: Advanced Insights & Health-Aware AI — Context

**Date:** 2026-05-08
**Phase:** 18
**Codes:** HLTH, INSE

## Domain

Nâng cấp hệ thống AI để (1) cấm tuyệt đối gợi ý thực phẩm trái với bệnh lý/kiêng cữ qua 3-layer safety, (2) ưu tiên gợi ý thực phẩm hỗ trợ sức khoẻ qua hybrid knowledge base, và (3) mở rộng InsightDetector phát hiện pattern "ăn lặp món" & "lệch macro dài ngày" với severity-based UI.

## Requirements

- **HLTH-01**: ContextBuilder ràng buộc cứng — cấm tuyệt đối đề xuất món trái bệnh lý
- **HLTH-02**: Gợi ý ưu tiên thực phẩm hỗ trợ sức khoẻ
- **INSE-01**: Phát hiện "ăn lặp món" (≥3 lần trong 5 ngày)
- **INSE-02**: Phát hiện lệch macro dài ngày (3 ngày liên tiếp vượt range)

## Decisions

### 1. Health Safety — 3-Layer Architecture (HLTH-01)

**Decision: C — Prompt + Post-validation + Minimal Re-ask**

#### Layer 1 — Prompt Protection
- Thêm `[ABSOLUTE RESTRICTION]` block vào **tất cả** ContextBuilder strategies: chat, mealSuggestion, mealPlan, healthAdvice, dailySummary
- Language cứng hơn hiện tại, dùng `NEVER` / `FORBIDDEN` / `TUYỆT ĐỐI CẤM`

#### Layer 2 — Output Validation
- **JSON output**: Scan `items[].name` against avoidFoods + Food Alias Dictionary
- **Free-text chat**: Light Safety Scanner — detect forbidden food keywords trong response text
- Normalize text trước khi match (lowercase, bỏ dấu, synonym lookup)

#### Layer 3 — Auto Repair (Minimal Re-ask)
- **JSON**: Nếu phát hiện vi phạm → chỉ regenerate MÓN BỊ LỖI (partial repair, KHÔNG full regenerate)
  - Re-ask prompt minimal: chỉ gửi requirements của món cần thay (calories range, style, restrictions)
  - KHÔNG gửi lại full context
- **Free-text**: Nếu phát hiện vi phạm → auto-rewrite bằng 1 API call nhỏ: "Replace [món cấm] with safe alternative"

#### Food Alias Dictionary
- File: `health_food_mapping.json` (dùng chung cho Area 2)
- Mapping synonym: hải sản → tôm, cua, mực, sò, nghêu; sữa → cheese, butter, yogurt; gluten → mì, bánh mì
- Dùng cho cả validation lẫn prompt injection

---

### 2. Health Food Recommendations — Hybrid Architecture (HLTH-02)

**Decision: C — Hybrid (JSON mapping + AI reasoning + dietaryNotes fallback)**

#### Layer 1 — Medical Knowledge Base (JSON)
- File: `health_food_mapping.json` (versioned, `"version": 1`)
- Hardcoded cho 5-7 bệnh phổ biến: tiểu đường, cao huyết áp, gout, dị ứng hải sản, cholesterol cao, trào ngược dạ dày, dị ứng sữa
- Schema:
  ```json
  {
    "version": 1,
    "conditions": {
      "Tiểu đường": {
        "recommended": ["rau xanh", "cá", "yến mạch", "ngũ cốc nguyên hạt"],
        "avoid": ["nước ngọt", "kẹo", "bánh ngọt", "đường"],
        "aliases": {"đường": ["sugar", "syrup", "mật ong"]},
        "risk_tags": ["high_sugar", "high_gi"]
      }
    }
  }
  ```
- Reusable across: meal plan, chat advice, barcode warning, food logging, daily summary

#### Layer 2 — AI Reasoning
- AI xử lý: contextualization, personalization, meal composition, cultural adaptation
- Inject `recommended` foods vào prompt: "Ưu tiên gợi ý: [recommended foods]"

#### Layer 3 — dietaryNotes Fallback
- Cho bệnh hiếm, custom diet, doctor recommendations
- Dùng field `HealthConditionModel.dietaryNotes` hiện có

---

### 3. New Insight Types (INSE-01, INSE-02)

#### 3a. Ăn lặp món — B + Lite Fuzzy (INSE-01)

**Decision: B + lite fuzzy normalize**

- **Threshold**: ≥3 lần trong rolling window 5 ngày (không cần liên tiếp)
- **Normalize pipeline**:
  1. lowercase
  2. Bỏ dấu tiếng Việt (cơm → com)
  3. Bỏ stop words: "phần", "vừa", "mini", "đặc biệt", "sốt", "cay", "xào", "chiên", "nướng"
  4. Extract keyword chính
  - Ví dụ: "Cơm Gà Xé (phần vừa)" → `com ga`
- **New InsightType**: `.repeatedMeals`

#### 3b. Lệch macro dài ngày — Flexible Range (INSE-02)

**Decision: E — Flexible range thresholds**

- **Ranges**: Protein 20-35%, Carbs 35-55%, Fat 20-35%
- **Trigger**: Vượt range ≥3 ngày liên tiếp
- **Warning threshold**: Cách mép range 5% mới warning (tránh spam). Ví dụ: Fat > 40% mới cảnh báo, không cảnh báo ở 36%
- **New InsightType**: `.macroImbalance`
- **Future-ready**: Auto-adjust range theo goal type (keto, high-protein, weight loss...)

#### Severity System (Nâng cấp)
- Thay thế `InsightSeverity` hiện tại (.warning, .alert) bằng 3 cấp:
  - `.low` — ăn lặp món (informational)
  - `.medium` — lệch macro ngắn hạn, low water
  - `.high` — lệch nghiêm trọng + goal conflict, health violation
- Dùng cho: Daily Summary Card, AI Coach context, future push notifications

---

### 4. UI/UX Hiển thị

#### 4a. Insight Cards — Separate Cards (B)

**Decision: B — Separate Insight Cards**

- **Layout**: Daily Summary Card (giữ gọn: calories, macros, progress) → Insight Cards riêng bên dưới
- **Design**:
  - cornerRadius: 18-22
  - padding lớn, icon trái, title + description
  - Subtle border theo severity, KHÔNG solid background
  - 🟢 `.low` — xanh nhạt
  - 🟡 `.medium` — vàng nhạt
  - 🔴 `.high` — đỏ nhạt
- **Interaction**:
  - Swipe dismiss hoặc nút X
  - Persist dismissed IDs (UserDefaults)
  - Auto-expire: repeated meals → 3 ngày, macro imbalance → khi user fix
  - **Tap card → Auto open AI Coach** với context question (ví dụ: "Làm sao giảm chất béo nhưng vẫn no lâu?")

#### 4b. Health Violation Badge — Subtle Badge (E)

**Decision: E — Subtle badge**

- **Normal severity**: "🛡 Đã điều chỉnh phù hợp với kiêng cữ và sức khỏe của bạn"
  - Font nhỏ, xanh nhẹ, opacity thấp, icon shield
- **High severity**: "🛑 Một số món đã bị loại bỏ để đảm bảo an toàn sức khỏe"
  - Vàng hoặc đỏ nhẹ, KHÔNG popup
- Hiển thị dưới meal suggestion / meal plan results

---

## Canonical Refs

- `LiiO_EatClean/Features/AI/ContextBuilder.swift` — Current prompt builder, needs ABSOLUTE RESTRICTION upgrade
- `LiiO_EatClean/Services/InsightDetector.swift` — Current 4 insight types, extend with repeatedMeals + macroImbalance
- `LiiO_EatClean/Data/Models/UserProfileMemory.swift` — healthConditions, avoidFoods, dietaryNotes
- `LiiO_EatClean/Features/Home/HomeViewModel.swift` — Dashboard data loading, insight integration
- `LiiO_EatClean/Features/Home/Components/DailySummaryCardView.swift` — Current insight display

## Code Context

### Reusable Assets
- `ContextBuilder` already has `avoidFoods` injection with `⛔ CẤM` marker
- `InsightDetector` already groups meals by day and analyzes 7-day windows
- `UserProfileMemory.healthConditions` stores `HealthConditionModel(name, dietaryNotes)`
- `buildMemoryBlock()` already injects health conditions into prompts
- `HapticManager` available for feedback on insight interactions

### New Components Needed
- `health_food_mapping.json` — Medical knowledge base
- `FoodSafetyValidator` — Output validation + alias matching
- `InsightCardView` — New UI component for separate insight cards
- `RepeatedMealDetector` — Normalize + detect repeated meals
- `MacroBalanceDetector` — Flexible range analysis

## Deferred Ideas

- Push notifications for high-severity insights (future phase)
- Auto-adjust macro ranges based on goal type (future enhancement)
- Remote update of health_food_mapping.json (future versioning)
- Barcode scan health warning integration (separate feature)

---
*Context captured: 2026-05-08 during Phase 18 discussion*
