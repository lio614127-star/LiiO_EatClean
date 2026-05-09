# Phase 17: Voice Chat (VCHT) — Discussion Log

**Date:** 2026-05-08

### Q1: Vị trí & UX của nút Mic
- **Presented:** [A] Trong ô chat thay thế nút Send / [B] Nổi bật bên ngoài
- **Selected:** 1A
- **Notes:** User chọn UX gọn gàng như iMessage/ChatGPT/Zalo. Ô chat gọn hơn, khi gõ chữ thì hiện nút Send (với transition mượt mà).

### Q2: Giao diện khi đang thu âm
- **Presented:** [A] Đổi màu nút Mic / [B] Bottom Sheet sóng âm
- **Selected:** 2B
- **Notes:** User định hướng làm Premium AI App nên chọn Bottom Sheet (~120-160pt blur), với Mic glow + waveform realtime, live transcript chạy từng chữ. Thêm đầy đủ haptic feedback và gesture support (swipe down cancel, auto-stop 2s).

### Q3: Luồng xác nhận văn bản
- **Presented:** [A] Điền vào ô chat / [B] Popup xác nhận riêng
- **Selected:** 3A
- **Notes:** User không muốn làm cụt flow bằng popup. Flow chuẩn là tự động điền vào ô chat để user bấm Send hoặc tự sửa bằng tay.

### Q4: Xử lý cấp quyền
- **Presented:** [A] Hỏi khi bấm mic lần đầu / [B] Hỏi khi vào màn hình
- **Selected:** 4A
- **Notes:** Áp dụng Apple Best Practice, chỉ hỏi khi người dùng thực sự tap vào Mic lần đầu để tránh tỷ lệ deny cao.

---
*Created by gsd-discuss-phase workflow.*
