---
status: complete
phase: 17-voice-chat
source: [17-SUMMARY.md, 17-01-SUMMARY.md, 17-02-SUMMARY.md, 17-03-SUMMARY.md]
started: 2026-05-08T10:05:00+07:00
updated: 2026-05-08T10:59:27+07:00
---

## Current Test

[testing complete]

## Tests

### 1. Mic/Send Button Toggle
expected: Mở tab AI Coach. Khi ô nhập text trống, nút bên phải hiển thị icon mic (🎤). Gõ bất kỳ ký tự nào vào ô text, icon chuyển thành nút Send (➤) với hiệu ứng animation mượt mà. Xoá hết text, icon chuyển lại thành mic.
result: pass

### 2. Permission Request on First Mic Tap
expected: Nhấn nút mic lần đầu tiên. Hệ thống hiện popup yêu cầu quyền Microphone và Speech Recognition. Cấp quyền → voice sheet xuất hiện. Nếu từ chối → hiện thông báo lỗi yêu cầu cấp quyền trong Cài đặt.
result: pass

### 3. Voice Recording Sheet Appearance
expected: Sau khi cấp quyền và nhấn mic, một bottom sheet (~220pt) nổi lên từ dưới với hiệu ứng spring animation. Sheet có nền blur (glassmorphism), hiển thị text "Đang nghe...", thanh waveform, và nút mic đỏ với hiệu ứng glow.
result: pass

### 4. Real-time Waveform & Transcript
expected: Khi đang thu âm, nói vào mic → thanh waveform phản hồi realtime theo cường độ âm thanh (các thanh cao thấp khác nhau). Đồng thời, text transcript hiện dần từng chữ trên sheet khi bạn nói tiếng Việt.
result: pass

### 5. Auto-stop on Silence & Transcript Fill
expected: Ngừng nói khoảng 2 giây → sheet tự đóng, text đã nhận diện tự động điền vào ô nhập tin nhắn. Có haptic feedback nhẹ (success) khi sheet đóng. Bạn có thể sửa text trước khi bấm Send.
result: pass

### 6. Manual Stop & Swipe-down Cancel
expected: Trong khi đang thu âm: (a) Nhấn nút mic đỏ trên sheet → dừng thu âm, transcript điền vào ô text. (b) Vuốt sheet xuống → huỷ thu âm, transcript vẫn điền vào ô text nếu có. Có haptic feedback khi thao tác.
result: pass

## Summary

total: 6
passed: 6
issues: 0
pending: 0
skipped: 0

## Gaps

[none]
