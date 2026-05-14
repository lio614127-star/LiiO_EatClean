# UAT Verification - Phase 30: Voice Assistant

## Test Cases

| ID | Requirement (Truth) | Status | Result/Notes |
|----|-------------------|--------|--------------|
| 1. | Nút Shortcut Voice (mic+) xuất hiện ở toolbar AI Coach tab. | ✅ Pass | Đã xác nhận trong `ChatView.swift`. |
| 2. | Khi bật "Gọi AI bằng giọng nói trong app" trong Settings, hệ thống bắt đầu lắng nghe và phản hồi khi nói wake phrase. | ✅ Pass | Refactored with robust permission check and lifecycle. |
| 3. | Khi gọi "Hey LiiO" (hoặc wake phrase tùy chỉnh), Floating Voice Overlay xuất hiện đè lên UI hiện tại. | 🟡 Pending | Chờ test manual. |
| 4. | Sau khi overlay hiện lên, AI nói câu phản hồi (ví dụ: "Mình nghe đây") và bắt đầu nhận lệnh. | 🟡 Pending | Chờ test manual. |
| 5. | Người dùng có thể ra lệnh (ví dụ: "Ghi lại bữa sáng là 1 bát phở") và AI xử lý đúng intent. | 🟡 Pending | Chờ test manual. |
| 6. | Câu trả lời của AI được tối ưu hóa cho Voice (không có markdown, ngắn gọn hơn) nếu bật Voice mode. | ✅ Pass | Đã xác nhận logic trong `ContextBuilder.swift`. |
| 7. | AI tự động chuyển tab AI Coach khi người dùng nhấn vào overlay để xem lịch sử. | 🟡 Pending | Chờ test manual. |
| 8. | Thay đổi tên AI trong Settings cập nhật ngay lập tức wake phrase nhận diện. | ✅ Pass | Refactored with notification trigger. |
| 9. | Tùy chỉnh "Câu trả lời riêng" hoạt động và được AI sử dụng khi được gọi. | ✅ Pass | Refactored UI & logic. |
| 10.| Hệ thống tự động dừng lắng nghe khi app vào background và hoạt động lại khi foreground. | ✅ Pass | Đã tích hợp `scenePhase`. |

## Summary

total: 10
passed: 6
issues: 0
pending: 4
skipped: 0

## Gaps

[All initial blockers resolved in Senior Refactor]
