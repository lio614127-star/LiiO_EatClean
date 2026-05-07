# Phase 16: Discussion Log

**Date:** 2026-05-07
**Phase:** 16-api-infrastructure-context-compression

## Areas Discussed

### 1. Giao diện quản lý Key Pool
- **Options presented:** A) Danh sách inline trong Settings, B) Màn hình riêng API Key Manager, C) Paste comma-separated
- **User selected:** B) Màn hình riêng
- **Reasoning:** App đang build "AI platform" không phải "AI demo app". Cần real infrastructure UX cho multi-key, auto swap, priority, health tracking. Inline list sẽ quá chật khi scale.

### 2. Chiến lược Auto-Swap
- **Options presented:** A) Instant Rotation + Cooldown, B) Round-Robin đều, C) Priority-based + Fallback
- **User selected:** A + C kết hợp (Priority-based + Instant Rotation + Cooldown)
- **Reasoning:** Free API keys có quota không ổn định, cần ưu tiên key tốt nhất trước (không random đều). Cooldown theo loại lỗi: 401→disable, 429→60s, timeout→15-30s.

### 3. Hành vi Parallel Request
- **Options presented:** A) Race Mode toggle, B) Smart Parallel theo ngữ cảnh, C) Parallel mọi lúc
- **User selected:** B + Distributed Parallel Generation
- **Reasoning:** Không duplicate request (tốn quota). Thay vào đó, chia nhỏ workload lớn (meal plan) và gửi song song tới nhiều key. VD: Key A→Breakfast, Key B→Lunch, Key C→Dinner.

### 4. Phương pháp nén Context
- **Options presented:** A) Sliding Window + Core Lock, B) Token Budget System, C) On-demand Compression
- **User selected:** A + B + Persistent AI Identity Layer
- **Reasoning:** Core Memory (bệnh lý, dị ứng, personality) KHÔNG BAO GIỜ nén. Chat history dùng sliding window (5-10 messages). Token budget phân bổ dynamic. Context rebuild từ CoreData → AI identity không phụ thuộc model session.

## Deferred Ideas
- Health score auto-sort suggestion
- Cloud sync for API keys (v2.0)
