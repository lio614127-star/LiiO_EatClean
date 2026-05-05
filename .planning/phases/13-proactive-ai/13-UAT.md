---
status: testing
phase: 13-proactive-ai
source: 13-SUMMARY.md
started: 2026-05-05T09:54:00+07:00
updated: 2026-05-05T09:54:00+07:00
---

## Current Test

number: 1
name: Daily Summary Card Visible on Home
expected: |
  Mở app → Home screen. Dưới Streak card (hoặc dưới Macro Bars nếu chưa có streak), 
  bạn sẽ thấy Daily Summary card hiển thị "📊 Hôm nay: X / Y kcal" với icon ✅ hoặc ⚠️.
  Nếu chưa có bữa ăn nào hôm nay, card vẫn hiện (hoặc hiện skeleton loading).
awaiting: user response

## Tests

### 1. Daily Summary Card Visible on Home
expected: Mở app → Home. Dưới Streak card thấy "📊 Hôm nay: X / Y kcal" với icon trạng thái
result: [pending]

### 2. Compact State (No Insights)
expected: Khi không có insight (ví dụ mới log ít data), card ở trạng thái gọn 1 dòng. Tap vào card → expand ra thấy macros (P/C/F), AI comment, AI suggestion
result: [pending]

### 3. Auto-Expand When Insights Exist
expected: Nếu có cảnh báo insight (ví dụ thiếu protein, bỏ bữa sáng, vượt calo...), card TỰ ĐỘNG expand khi mở Home — không cần tap. Hiển thị icon warning + message + gợi ý
result: [pending]

### 4. Macro Progress Bars Display
expected: Khi card expanded, thấy 3 thanh progress nhỏ cho Protein (xanh dương), Carbs (tím), Fat (cam) với số gram bên cạnh
result: [pending]

### 5. AI Comment & Suggestion
expected: Cuối card expanded có section "✨ AI Nhận Xét" với comment bằng tiếng Việt + 1 gợi ý "👉 ..." cho ngày mai. Tone tích cực nếu đạt goal, nhẹ nhàng nếu chưa đạt
result: [pending]

### 6. Card Animation Smooth
expected: Tap card compact → expand mượt mà (spring animation ~0.3s). Tap lại → thu gọn mượt. Không giật, không lag
result: [pending]

### 7. Card Position in Layout
expected: Thứ tự trên Home: CalorieRing → MacroBars → StreakCard → **DailySummaryCard** → WaterCard → MealSections. Summary card nằm đúng vị trí giữa Streak và Water
result: [pending]

### 8. Push Notification Scheduled
expected: Vào Profile → bật Reminders → notification daily summary được đăng ký lúc 20:00 hàng ngày (kiểm tra trong Settings hoặc confirm code logic đã gọi scheduleDailySummaryReminder)
result: [pending]

### 9. Build Stability
expected: App build thành công không lỗi, không crash khi mở Home
result: [pending]

## Summary

total: 9
passed: 0
issues: 0
pending: 9
skipped: 0
blocked: 0

## Gaps
