# Phase 17: Voice Chat (VCHT) — Context

**Domain:** Tích hợp Apple Speech-to-Text (On-device) vào màn hình Chat để người dùng nhập liệu bằng giọng nói.

## Canonical Refs
- [REQUIREMENTS.md](file:///Users/liio/TooL_LiiO/LiiO_EatClean/.planning/REQUIREMENTS.md)

## Decisions

### 1. Vị trí & UX của nút Mic (1A)
- Nằm bên trong ô nhập text (góc phải), thay thế nút "Send" khi ô chat trống.
- Khi người dùng bắt đầu gõ chữ, nút Mic tự động animate (scale/fade transition mượt mà) chuyển thành nút Send.
- UX chuẩn theo iMessage, ChatGPT, Zalo.

### 2. Giao diện khi đang thu âm (2B - Premium UX)
- **Bottom Sheet Mini:** Khi tap Mic -> bật lên một Bottom Sheet dạng blur nổi lên (~120-160pt) thay vì full screen.
- **Animation:** Có Mic glow + Waveform animation chạy realtime dựa trên âm lượng mic thật (không fake random).
- **Live Transcript:** Hiển thị text transcript chạy dần từng chữ realtime (VD: "Hôm nay..." -> "Hôm nay tôi ăn...").
- **Haptic Feedback:** 
  - Start listening: `light`
  - Stop listening: `soft`
  - Transcript success: `success`
  - Error/No speech: `warning`
- **Gestures & Control:**
  - Tap mic: Bắt đầu thu âm.
  - Tap lần nữa: Dừng thu âm.
  - Swipe down sheet: Cancel (Hủy thu âm).
  - Tự động dừng (Auto-stop) sau 2s im lặng.

### 3. Luồng xác nhận văn bản (3A)
- **Live to Input:** Sau khi thu âm hoặc bấm dừng, Transcript tự động điền thẳng vào ô chat. Không dùng popup xác nhận rườm rà.
- User có thể bấm Send ngay lập tức, hoặc tự dùng bàn phím sửa text trước khi gửi. Đảm bảo flow tự nhiên và liền mạch.

### 4. Xử lý cấp quyền (4A - Best Practice)
- Chỉ xin quyền Mic & Speech Recognition khi người dùng thực sự tap vào nút Mic lần đầu tiên (Tránh làm phiền, giảm tỷ lệ deny).

## Code Context & Architecture
- **Architecture Flow:** `SpeechRecognizer` (Service) -> `Live Transcript Stream` -> `ChatInputView Binding` (UI) -> `User Review/Edit` -> `Send Message`.

## Deferred Ideas
- **Ngắt lời AI (Interrupt AI):** Khi AI đang trả lời (streaming), hiển thị UI "Tap để ngắt AI và nói tiếp" (có thể defer sang bản nâng cấp sau hoặc khi triển khai thực sự giống ChatGPT Voice).
