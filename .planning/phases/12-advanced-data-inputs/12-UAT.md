---
status: complete
phase: 12-advanced-data-inputs
source: [12-SUMMARY.md]
started: 2026-05-05T01:10:00Z
updated: 2026-05-05T01:43:05Z
---

## Current Test

[testing complete]

## Tests

### 1. Voice mic button trên Home
expected: Ở màn Home, góc phải trên header (cạnh lời chào) có nút mic tròn màu xanh lá. Nhấn vào → hiện sheet VoiceInputView.
result: pass

### 2. Voice mic button trên AddMealView
expected: Trong AddMealView, dải nút gợi ý AI có thêm nút mic màu xanh dương (capsule). Thứ tự: [📸 Scan] [🎤 Voice] [✨ Hỏi AI]. Nhấn mic → hiện sheet VoiceInputView.
result: pass
note: Fixed layout — 3 buttons compacted to fit one line (icon-only circles for Scan/Voice).

### 3. Voice recording + real-time transcript
expected: Khi mở VoiceInputView, app xin quyền Microphone + Speech Recognition (tiếng Việt). Sau khi cho phép, nút mic pulsing (nhấp nháy). Nói tiếng Việt → thấy text hiện real-time bên dưới mic.
result: pass
note: Fixed pulsing animation — switched from frame-based to scaleEffect to prevent layout glitch on physical devices.

### 4. Voice parse → kết quả + xác nhận
expected: Sau khi dừng nói, app hiện loading "Đang phân tích...", rồi hiện danh sách món ăn AI nhận diện được (tên + calo + quantity). Có nút [Xác nhận & Thêm] để add vào cart.
result: pass
note: AI estimation may vary slightly between calls (350-500 kcal for phở bò) — expected behavior. Cache helps for identical text inputs.

### 5. Barcode scan button trên AddMealView
expected: Trong AddMealView, dải nút action bar có nút barcode scan tròn màu cam. Nhấn → hiện sheet camera (half-screen).
result: pass

### 6. Barcode camera + scan guide
expected: Sheet camera hiện preview camera phía sau với overlay guide: hình chữ nhật nét đứt trắng + label "Hướng camera vào mã vạch".
result: pass

### 7. Barcode scan → lookup + result
expected: Quét mã vạch → haptic feedback → tra cứu OpenFoodFacts → hiện kết quả: tên sản phẩm, calories, macros. Có nút [Xác nhận & Thêm] và quantity editor.
result: pass

### 8. Barcode not found fallback
expected: Quét mã vạch không có trong OpenFoodFacts → hiện "Không tìm thấy sản phẩm" + mã vạch + nút [Tìm kiếm thủ công] và [Quét lại].
result: pass

### 9. Permission dialogs tiếng Việt
expected: Lần đầu dùng Voice → dialog xin quyền Microphone và Speech Recognition tiếng Việt. Lần đầu dùng Barcode → dialog xin quyền Camera tiếng Việt.
result: pass

## Summary

total: 9
passed: 9
issues: 0
pending: 0
skipped: 0

## Gaps

[none]
