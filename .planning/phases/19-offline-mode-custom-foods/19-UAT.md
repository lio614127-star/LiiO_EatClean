---
status: complete
phase: 19-offline-mode-custom-foods
source: [19-01-SUMMARY.md, 19-02-SUMMARY.md, 19-03-SUMMARY.md, 19-04-SUMMARY.md, 19-05-SUMMARY.md]
started: 2026-05-08T18:56:00+07:00
updated: 2026-05-08T19:57:00+07:00
---

## Current Test

[testing complete]

## Tests

### 1. Custom Food Builder - Create New Food
expected: Trong FoodSearchView, bấm nút "+" ở toolbar. Sheet "Tạo món mới" hiện ra với trường nhập liệu. Khi nhập macros, calories tự động tính theo công thức (4P + 4C + 9F). Bấm "Lưu món" thành công.
result: pass

### 2. Custom Food Appears in Search (⭐ Section)
expected: Sau khi tạo custom food, quay lại FoodSearchView. Món vừa tạo hiện trong section "⭐ Món của bạn" ở đầu danh sách, có icon ngôi sao và badge "Custom" màu xanh lá.
result: pass

### 3. Custom Food Swipe Actions
expected: Trên row custom food, vuốt sang trái sẽ thấy 2 nút: "Sửa" (✏️) và "Xóa" (🗑). Bấm "Xóa" sẽ xóa món và hiện toast undo "Đã xóa món — Hoàn tác". Bấm "Hoàn tác" khôi phục món.
result: pass

### 4. 4-Section Search Priority Layout
expected: Khi search một từ khóa (vd: "cơm"), kết quả hiện theo 4 section theo thứ tự: ⭐ Món của bạn → 🕘 Gần đây → 📦 Dữ liệu offline → 🌐 API. Mỗi section có header riêng.
result: pass

### 5. Offline Banner Display
expected: Khi tắt WiFi/Data trên điện thoại (hoặc bật Airplane Mode), một thanh banner cam hiện ở trên cùng app hiển thị "Không có kết nối mạng — Một số tính năng AI tạm ngưng". Khi bật lại mạng, banner chuyển xanh lá "Đã kết nối lại" rồi tự ẩn sau ~2.5 giây.
result: pass

### 6. AI Buttons Disabled When Offline
expected: Khi offline, trong AddMealView các nút "✨ Hỏi AI" và "Mic" bị mờ đi (opacity giảm). Bấm vào hiện toast "📡 Gợi ý AI cần kết nối mạng" hoặc "📡 Nhập giọng nói cần kết nối mạng". Không crash, không loading vô hạn.
result: pass

### 7. Meal Plan Disabled When Offline
expected: Khi offline, trong MealPlanSheet nút "Lên kế hoạch tuần" và nút refresh (🔄) bị mờ. Bấm vào hiện toast "📡 Kế hoạch bữa ăn cần AI để phân tích dinh dưỡng". Không gọi API.
result: pass

### 8. Chat Send Disabled When Offline
expected: Khi offline trong ChatView, nút gửi tin nhắn bị disabled/mờ khi đã nhập text. Nút mic khi bấm hiện thông báo "📡 Tính năng giọng nói cần kết nối mạng". Text input vẫn gõ được bình thường.
result: pass

### 9. Pending Chat Queue (Offline Message)
expected: Khi offline, gõ tin nhắn và bấm gửi. Tin nhắn được queue và hiện trong chat với icon đồng hồ "🕘 Đang chờ kết nối...". Khi bật lại mạng, tin nhắn tự động gửi đi và nhận phản hồi AI.
result: pass

### 10. Dashboard & Meal History Work Offline
expected: Khi offline, Home Dashboard vẫn hiển thị đầy đủ dữ liệu calories, meals đã log, progress chart. Không bị trắng hay lỗi. CoreData local hoạt động bình thường.
result: pass

## Summary

total: 10
passed: 10
issues: 0
pending: 0
skipped: 0

## Gaps

[none yet]

## Gaps

[none yet]
