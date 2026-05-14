# Phase 31: Global Context Builder cho AI Coach - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-14
**Phase:** 31-Global Context Builder cho AI Coach
**Areas discussed:** 
1. Tối ưu hóa tốc độ phản hồi (Adaptive Timeout for Voice vs Chat)
2. Chiến lược phản hồi khi thiếu dữ liệu (Hybrid Strategy & MissingReason)
3. Cơ chế phân loại ý định hỗn hợp (Multi-Intent / ContextSection Mapping)

---

## Vùng xám 1: Tối ưu hóa tốc độ phản hồi (Adaptive Timeout)

| Option | Description | Selected |
|--------|-------------|----------|
| 1.0 giây | Siêu tốc nhưng có tỷ lệ timeout quá cao trên máy thật dẫn đến mất dữ liệu cục bộ. | |
| 1.5 giây | An toàn hơn cho data query nhưng khiến Voice assistant bị trì trệ khi cộng dồn AI+TTS. | |
| 1.2 giây | Điểm cân bằng vàng giữa phản hồi tự nhiên thời gian thực và cơ hội load Priority 0/1. | ✓ |

**User's choice:** Thiết lập timeout động: `.voice` = 1.2s, `.chat` = 3.0s. Fast-path fallback nạp Compact Snapshot.
**Notes:** Do Kiến trúc sư trưởng chốt để giữ cảm xúc hội thoại luôn "Real-time".

---

## Vùng xám 2: Phản hồi khi thiếu dữ liệu (Passive vs Proactive)

| Option | Description | Selected |
|--------|-------------|----------|
| Passive (Bị động) | AI chỉ thông báo cụt lủn, tránh lan man làm phiền người dùng. | |
| Proactive (Chủ động) | Luôn tìm cách hướng người dùng điền profile, log món, lên plan liên tục. | |
| Hybrid Context-Aware | **Voice:** Passive-first + tối đa 1 câu CTA trực diện. **Chat:** Proactive chi tiết + Nút bấm. | ✓ |

**User's choice:** Hybrid Strategy. Bổ sung `MissingDataReason` phân loại rõ nguyên nhân (timedOut, notProvided, v.v.).
**Notes:** Giải pháp xuất sắc cân bằng giữa tốc độ của Voice và tính chất "Huấn luyện viên chủ động" trong Chat.

---

## Vùng xám 3: Phân loại ý định hỗn hợp (Mixed Intent Handling)

| Option | Description | Selected |
|--------|-------------|----------|
| Single Intent + General Fallback | Đơn giản nhưng dễ lãng phí token hoặc load sai ngữ cảnh khi user hỏi đa đề tài. | |
| Multi-Intent `Set<ContextIntent>` | Nâng cấp API nhận diện nhiều intent song song. Union các Section dữ liệu để load. | ✓ |

**User's choice:** Multi-Intent + De-duplicated Section Union mapping.
**Notes:** Giải pháp kỹ thuật triệt để nhất, tối ưu hiệu năng tối đa vì không bao giờ chạy trùng Repository Task dù nạp hàng chục Intent khác nhau.

---

## the agent's Discretion
- Thiết lập chi tiết bộ keyword matching cho `IntentDetector`.
- Cài đặt thời gian hết hạn Cache cụ thể.

## Deferred Ideas
None.
