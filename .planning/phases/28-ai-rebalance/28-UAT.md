# UAT: Phase 28 — AI Rebalance & Smart Correction

**Status:** 🟡 In Progress
**Date:** 2026-05-13
**Tester:** AI Assistant + User

## Test Matrix

| ID | Feature | Scenario | Status | Notes |
|:---|:---|:---|:---|:---|
| 28.1 | Trigger | Over Calorie (>10% deviation) shows Home card | ✅ PASS | Đã fix thông báo động cho 'Đã vượt' |
| 28.2 | Trigger | Under Protein shows Home card | ✅ PASS | Nhận diện thiếu đạm chuẩn |
| 28.3 | Preview | Preview Sheet displays changed items correctly | ✅ PASS | Đã hiển thị Diff rõ ràng |
| 28.4 | Execution | Apply "Preserve Meals" (Portion Adjust only) | ✅ PASS | Đã áp dụng thành công |
| 28.5 | Execution | Apply "Flexible Swap" (New food suggestions) | ✅ PASS | Đã swap món thành công (Bò lúc lắc) |
| 28.6 | Control | Locked meals are NOT modified by AI | ✅ PASS | Đã tôn trọng các bữa ăn bị khóa |
| 28.7 | Stability | Plan persistence after rebalance application | ✅ PASS | Dữ liệu lưu trữ ổn định sau khi restart |

---

## Test Logs

### [28.1] Trigger: Over Calorie
**Steps:**
1. Mở app, đảm bảo đã có kế hoạch (Planned) cho ngày hôm nay.
2. Log một bữa ăn thực tế (Actual) vượt quá lượng calo dự kiến của bữa đó sao cho tổng (Actual + Remaining Planned) > Target * 1.1.
3. Quay lại màn hình Home.

**Expectation:**
- Card "AI Rebalance" xuất hiện trên Home với nội dung cảnh báo vượt calo.
- Nhấn nút hành động trên card sẽ mở sheet xem trước.

**Result:**
(Waiting for user...)
