# Phase 16: API Infrastructure & Context Compression - Context

**Gathered:** 2026-05-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Nâng cấp toàn bộ hạ tầng gọi AI API từ mô hình sequential fallback đơn giản sang hệ thống multi-key pool chuyên nghiệp với auto-swap, priority rotation, distributed parallel generation, và cooldown system. Đồng thời xây dựng Context Compression Engine với Persistent AI Identity Layer — đảm bảo AI không bao giờ mất ngữ cảnh người dùng dù đổi key, đổi model, hay reset chat.

Requirements: APIK-01, APIK-02, APIK-03, COMP-01, COMP-02

</domain>

<decisions>
## Implementation Decisions

### API Key Manager UI
- **D-01:** Tạo màn hình riêng "API Key Manager" truy cập từ Profile/Settings. Full-screen, chuyên biệt. KHÔNG inline list trong Settings, KHÔNG paste comma-separated.
- **D-02:** Mỗi key hiển thị dạng Card: Provider icon, key (masked ••••sk-abc123), trạng thái (🟢 Active / 🟡 Cooling down / 🔴 Invalid / ⚪ Idle), "Last used" timestamp.
- **D-03:** Hỗ trợ kéo thả (drag-to-reorder) để user tự sắp xếp thứ tự ưu tiên (priority) của các key.
- **D-04:** Nút "+" để thêm key mới (chọn provider Gemini/OpenAI + paste key). Vuốt để xóa.

### Auto-Swap Strategy: Priority-based + Instant Rotation + Cooldown
- **D-05:** Hệ thống luôn thử key ưu tiên cao nhất (theo thứ tự user sắp xếp) trước.
- **D-06:** Khi key lỗi → instant rotate sang key tiếp theo trong pool, không gián đoạn UX.
- **D-07:** Cooldown theo loại lỗi:
  - `401 Invalid` → disable vĩnh viễn, đánh dấu đỏ, skip khỏi pool. User phải sửa thủ công.
  - `429 Quota` → cooldown 60 giây rồi tự enable lại.
  - `Timeout/Network` → cooldown 15-30 giây.
- **D-08:** Health score cho từng key (tỷ lệ thành công). Hiển thị trong API Key Manager.

### Parallel Request: Smart Parallel + Distributed Workload
- **D-09:** Request thường (chat, memory, meal suggestion đơn giản) → Sequential + Priority Rotation. Tiết kiệm quota.
- **D-10:** Request lớn (Meal Plan Day/Week) → tự bật Distributed Parallel Generation:
  - Meal Plan Day: Chia theo bữa (Key A → Breakfast+Snack, Key B → Lunch, Key C → Dinner).
  - Meal Plan Week: Chia theo ngày (Key A → T2-T3, Key B → T4-T5, Key C → T6-T7).
  - App tự chia calorie budget trước → gửi song song → merge kết quả → validate → render.
- **D-11:** KHÔNG dùng always-parallel duplicate requests (gửi cùng 1 request tới nhiều key). Tốn quota không cần thiết.
- **D-12:** Nếu 1 key fail trong distributed parallel → instant rotate sang key khác cho phần đó, không ảnh hưởng toàn bộ plan.

### Context Compression: Sliding Window + Core Lock + Token Budget + Persistent Identity
- **D-13:** Core Memory = NEVER COMPRESS. Luôn inject đầy đủ dù đổi API key, đổi model, context overflow, chat reset, swap provider. Bao gồm: bệnh lý, dị ứng, món kiêng, likes/dislikes, calorie target, BMR/TDEE, AI personality, health warnings.
- **D-14:** Chat History = Sliding Window. Giữ 5-10 messages gần nhất nguyên vẹn. Messages cũ hơn → summarize thành memory summary → lưu vào CoreData.
- **D-15:** Token Budget System với dynamic allocation:
  - Core Memory: 35-40%
  - Recent Chat: 25-30%
  - Health Insights: 15-20%
  - Meal History: 10-15%
  - Reserved Buffer: 10%
- **D-16:** Khi context gần đầy: (1) summarize old conversation, (2) lưu summary vào CoreData, (3) clear active window, (4) rebuild optimized context, (5) swap API key/model nếu cần, (6) tiếp tục chat seamless.
- **D-17:** Persistent AI Identity Layer — context được rebuild từ CoreData, không phụ thuộc model session. Dù restart app, đổi provider, hay reset chat → AI vẫn biết user là ai, bệnh gì, ghét món gì, đang theo mục tiêu nào.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Context
- `.planning/REQUIREMENTS.md` — Phase 16 requirements (APIK-01 to APIK-03, COMP-01, COMP-02)
- `.planning/PROJECT.md` — App values and native iOS design constraints

### Prior Phase Context
- `.planning/phases/15-ai-memory-hub-personality/15-CONTEXT.md` — AI Memory Hub decisions (D-01 to D-13)

### Existing API Infrastructure
- `LiiO_EatClean/Features/AI/AIService.swift` — Current sequential fallback implementation (Gemini → OpenAI). Core refactor target.
- `LiiO_EatClean/Data/Models/APIKeyModel.swift` — Existing key model (id, provider, key, isActive). Needs extension for health/cooldown.
- `LiiO_EatClean/Data/Repositories/UserRepository.swift` — Current key storage (fetchAPIKeys, saveAPIKey).
- `LiiO_EatClean/Data/Protocols/UserRepositoryProtocol.swift` — Repository protocol for key operations.

### Context & Memory Infrastructure
- `LiiO_EatClean/Features/AI/ContextBuilder.swift` — Current prompt builder. Refactor target for token budget system.
- `LiiO_EatClean/Data/Repositories/AIMemoryRepository.swift` — CoreData-backed memory (source of Persistent AI Identity).
- `LiiO_EatClean/Data/Models/UserProfileMemory.swift` — Memory struct (health conditions, preferences, personality).

### UI Integration Points
- `LiiO_EatClean/Features/Profile/ProfileViewModel.swift` — Current key management UI logic (lines 112-123).
- `LiiO_EatClean/Features/Meals/MealPlanViewModel.swift` — Meal plan generation (target for distributed parallel).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `APIKeyModel` struct already exists with `id`, `provider`, `key`, `isActive` fields — extend with `healthScore`, `lastUsed`, `cooldownUntil`, `priority`.
- `performRequest()` in AIService already handles HTTP status codes (429, 401) — wrap with rotation logic.
- `HapticManager` for drag-to-reorder feedback in API Key Manager.
- `MemoryCard` component from Phase 15 for consistent card styling.

### Established Patterns
- Repository Pattern: Create `APIKeyPoolRepository` for key pool management with cooldown/health tracking.
- `@Observable` ViewModels for SwiftUI reactivity.
- `.fullScreenCover` for premium modal presentation (used in Memory Hub).

### Integration Points
- Refactor `AIService.suggestMeals()`, `generateText()`, `sendChatMessage()` to route through new key pool manager.
- Update `MealPlanViewModel` to use distributed parallel for day/week plans.
- Update `ContextBuilder` to respect token budget before building prompts.

</code_context>

<specifics>
## Specific Ideas

- **Key Manager Card Design:** cornerRadius 16, soft shadow, provider icon (Gemini blue/OpenAI green), masked key display, health percentage bar.
- **Cooldown Visual:** Circular countdown timer overlay on key card during cooldown period.
- **Context Rebuild:** On provider swap, ContextBuilder reads CoreData → rebuilds full prompt → sends to new provider seamlessly.
- **Token Counter:** Internal utility to estimate token count before sending (rough: 1 token ≈ 4 chars for English, ≈ 2 chars for Vietnamese).

</specifics>

<deferred>
## Deferred Ideas

- Health score auto-sort suggestion (auto-reorder keys by health) — future enhancement after v1.2.
- Cloud sync for API keys — deferred to v2.0 with CloudKit.

</deferred>

---

*Phase: 16-api-infrastructure-context-compression*
*Context gathered: 2026-05-07*
