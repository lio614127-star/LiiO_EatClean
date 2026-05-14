# Phase 31: Global Context Builder cho AI Coach - Context

**Gathered:** 2026-05-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Tích hợp sâu Context Engine toàn năng (`AICoachContextBuilder`) vào prompt của AI. Triển khai cơ chế **Adaptive Context Timeout** (Voice 1.2s vs Chat 3.0s), cơ chế **Multi-Intent** đa ý định (`Set<ContextIntent>`) giúp load tối ưu chính xác các Section dữ liệu cần thiết không trùng lặp, và hệ thống ứng biến thông minh **Hybrid Response Policy** khi dữ liệu bị thiếu hụt theo ngữ cảnh sử dụng.

</domain>

<decisions>
## Implementation Decisions

### 1. Cơ cấu Modes & Timeout (Adaptive Timing)
- **D-01 (Mode Enum):** Khai báo `enum AICoachContextMode` gồm 4 case: `.voice`, `.chat`, `.planning`, `.rebalance`.
- **D-02 (Timeouts):** Thiết lập `voiceContextTimeout` = 1.2s và `chatContextTimeout` = 3.0s.
- **D-03 (Fast-path Fallback):** Nếu chạm timeout, ngay lập tức trả về Snapshot hiện hữu, cho phép Task ngầm tiếp tục nạp ấm Cache thay vì cancel thô bạo.

### 2. Xử lý Thiếu dữ liệu Thông minh (Hybrid Missing Data)
- **D-04 (Reason Enum):** Khai báo `MissingDataReason` gồm: `.notProvidedByUser`, `.notCreatedYet`, `.notLoggedYet`, `.timedOut`, `.unavailable`, `.permissionOrStorageError`.
- **D-05 (Voice Mode Policy):** Trả lời ngắn gọn, trung thực, chỉ kèm tối đa 1 câu CTA gợi ý hành động trực tiếp siêu liên quan (Không giảng giải, không hỏi dồn).
- **D-06 (Chat Mode Policy):** Proactive hơn, có thể đưa ra gợi ý chi tiết và kèm nút hành động CTA (Mở hồ sơ, Thêm cân nặng, Lên thực đơn).
- **D-07 (Planning/Rebalance Policy):** Tuyệt đối không block flow. Nếu thiếu Allergy/Preferences, dùng cấu hình an toàn mặc định, thông báo nhanh cho user và tiếp tục thực thi.
- **D-08 (Prompt Mapping Rules):** Đẩy trực tiếp `MissingDataReason` vào prompt để AI phân loại câu trả lời chuẩn xác theo thiết kế: Không coi `.notLoggedYet` là lỗi, giải thích rõ `.timedOut` là đang trả lời nhanh, và khuyến khích điền nếu `.notProvidedByUser`.

### 3. Cấu trúc Đa ý định & Tối ưu nạp Dữ liệu (Multi-Intent Architecture)
- **D-09 (Multi-Intent Detection):** Nâng cấp API từ single-intent lên `detectContextIntents(from:currentTab:mode:) -> [DetectedIntent]`.
- **D-10 (Confidence Filtering):** Chỉ nạp intent có confidence >= 0.75 (hoặc 0.45-0.74 nếu query rõ). Fallback sang `generalChat` nếu không nhận diện được gì.
- **D-11 (Intent-to-Section Mapping):** Định nghĩa `enum ContextSection` (bộ phận dữ liệu). Map mỗi `ContextIntent` ra các `ContextSection` cần thiết.
- **D-12 (Union & De-duplication):** Tính Union tất cả các section cần thiết (`requiredSections`), loại bỏ trùng lặp (De-duplicate) để mỗi Repository Task chỉ chạy duy nhất 1 lần.
- **D-13 (Structured Mixed Response):** Chỉ thị AI phản hồi rõ ràng theo từng mảng nội dung ngắn tương ứng với các intent được phát hiện, không trộn lẫn lộn xộn.

### 4. Caching Engine & Invalidation
- **D-14 (AICoachContextCache):** Xây dựng lớp cache gọn nhẹ lưu trữ Today Minimal Snapshot, Today Plan, Trend Summary và Metabolic Summary.
- **D-15 (Invalidation Event):** Tự động invalidate cache dựa trên các event trong app: thay đổi MealLog, PlannedMeal, cân nặng hoặc foreground refresh.

### the agent's Discretion
- Thuật toán và ngưỡng confidence chi tiết cho việc matching keywords trong `IntentDetector`.
- Thời gian hết hạn cụ thể (TTL) của từng vùng dữ liệu trong `AICoachContextCache`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### 1. Core Planning & Context Architectures
- `.planning/REQUIREMENTS.md` §VOICE-05 — Định nghĩa yêu cầu Context Engine tích hợp prompt.
- `LiiO_EatClean/Features/AI/AICoachContextBuilder.swift` — File builder gốc cần nâng cấp Task Group, Multi-Intent mapping.
- `LiiO_EatClean/Features/AI/AICoachContextSnapshot.swift` — Bổ sung `contextQuality`, `MissingDataReason` enum.
- `LiiO_EatClean/Features/AI/ContextBuilder.swift` — Cần tích hợp logic `detectContextIntents` thay thế single selector.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `UserRepositoryProtocol`, `MealRepositoryProtocol`, `AIMemoryRepositoryProtocol`: Sẵn sàng để gọi bất đồng bộ đồng thời.

### Established Patterns
- Structured Concurrency Task Cancellation Guard: Vẫn giữ Task ngầm nạp Cache khi TaskGroup tổng thể return sớm do Timeout.

### Integration Points
- `ChatViewModel.swift` & `GlobalVoiceAssistantManager.swift`: Tích hợp mode và Tab hiện tại vào tham số gọi Prompt.

</code_context>

<specifics>
## Specific Ideas
- **Mixed Intent Segmented UI/Text**: AI tự ngắt quãng phân đoạn trả lời *"Về hôm nay... Về cân nặng 7 ngày..."* để user dễ đọc và AI TTS dễ phát âm.
- **Action + Info Edge Case**: Nếu user vừa yêu cầu Action (Lên thực đơn) vừa hỏi Info (Cân nặng thế nào), hệ thống sẽ ưu tiên Action chính trong Voice Mode để tránh độ trễ.

</specifics>

<deferred>
## Deferred Ideas
None — discussion stayed within phase scope.
</deferred>

---

*Phase: 31-Global Context Builder cho AI Coach*
*Context gathered: 2026-05-14*
