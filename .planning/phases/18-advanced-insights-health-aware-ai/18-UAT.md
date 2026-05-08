---
status: complete
phase: 18-advanced-insights-health-aware-ai
source:
  - 18-01-SUMMARY.md
  - 18-02-SUMMARY.md
  - 18-03-SUMMARY.md
  - 18-04-SUMMARY.md
  - 18-05-SUMMARY.md
started: 2026-05-08T16:12:00+07:00
updated: 2026-05-08T17:51:00+07:00
---

## Current Test

[testing complete]

## Tests

### 1. Health Food Mapping JSON loads correctly
expected: App khởi động bình thường. Khi user có health condition trong profile, hệ thống load được danh sách avoid foods từ health_food_mapping.json.
result: pass

### 2. ContextBuilder injects ABSOLUTE RESTRICTION into AI prompts
expected: Khi chat với AI Coach hoặc xin gợi ý món, prompt gửi tới AI chứa block ABSOLUTE RESTRICTION liệt kê đầy đủ các foods cần tránh. AI không gợi ý các món bị cấm.
result: pass

### 3. AI Output Validation catches forbidden foods in meal suggestions
expected: Nếu AI vô tình trả về món chứa thực phẩm bị cấm, hệ thống tự động phát hiện và thay thế bằng món an toàn khác — không hiện lỗi, không mất món.
result: pass

### 4. Chat free-text safety scanning works
expected: Trong AI Coach chat, nếu AI mention thực phẩm bị cấm trong câu trả lời text, hệ thống rewrite lại câu trả lời để loại bỏ nội dung không an toàn.
result: pass

### 5. HealthSafetyBadge appears when safety correction is applied
expected: Khi hệ thống đã thực hiện safety correction, badge hiện lên. Nếu AI trả lời đúng từ đầu (Layer 1 đủ mạnh), badge không xuất hiện — cũng OK.
result: pass

### 6. InsightDetector generates repeated meal insight
expected: Nếu user ăn cùng một món ≥3 lần trong 5 ngày, insight card xanh xuất hiện cảnh báo.
result: pass
note: Calorie overrun + repeated meals insights both showing. Fixed duplicate display (removed separate InsightCards, kept inside DailySummaryCard per user preference).

### 7. InsightDetector generates macro imbalance insight
expected: Nếu user có fat > 40% liên tục ≥3 ngày, insight card cam xuất hiện.
result: pass

### 8. Insights display inside DailySummaryCard
expected: Insights nằm gọn bên trong DailySummaryCard (mở ra xem, đóng lại gọn). Không có card riêng biệt bên dưới.
result: pass
note: Consolidated per user decision — insights inside expandable DailySummaryCard only.

### 9. Insight Card dismiss persists across sessions
expected: N/A — Replaced by DailySummaryCard collapse/expand mechanism.
result: skipped
reason: UI consolidated into DailySummaryCard per user decision. Collapse replaces dismiss.

### 10. Insight Card tap navigates to AI Coach
expected: N/A — Insights are now inline in DailySummaryCard.
result: skipped
reason: UI consolidated into DailySummaryCard per user decision. Separate tap navigation not needed.

## Summary

total: 10
passed: 8
issues: 0
pending: 0
skipped: 2

## Gaps

[none]
