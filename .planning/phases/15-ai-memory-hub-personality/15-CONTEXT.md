# Phase 15: AI Memory Hub & Personality - Context

**Gathered:** 2026-05-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Nâng cấp hệ thống AI Memory thành một màn hình quản lý tập trung (Memory Hub) truy cập trực tiếp từ icon Chat và tích hợp tính năng tuỳ chỉnh Personality của AI Coach. Phase này thực hiện di chuyển data từ UserDefaults sang CoreData, xây dựng UI Memory Hub theo dạng Grouped Cards đẹp mắt, xoá card cũ ở Meals tab và thay bằng mini badge, đồng thời đảm bảo system prompt của LLM hoạt động tương thích với các personality presets.

</domain>

<decisions>
## Implementation Decisions

### Migration Strategy (UserDefaults → CoreData)
- **D-01:** Sử dụng kiến trúc Multi-Entity normalized. Entities: `AIMemory` (root), `HealthCondition`, `FoodPreference`, `AvoidFood`, `DietaryNote`, `AIInsight`.
- **D-02:** Auto-migrate silent + Toast thông báo. Khi launch app, tự động parse data cũ, map vào CoreData, xoá key UserDefaults và hiện toast 2s: "🧠 AI Memory đã được đồng bộ an toàn".
- **D-03:** Tạo repository mới là `AIMemoryRepository` để thống nhất pattern với `MealRepository`, `FoodRepository`, v.v. Xoá `MemoryManager` cũ. (Tuỳ chọn có `AIMemoryService` cho orchestration).
- **D-04:** Không duplicate thông tin profile (tuổi, cân nặng, chiều cao, calories) vào `AIMemory`. Profile tiếp tục đọc từ `UserRepository`, `AIMemory` chứa phần memory của AI. `ContextBuilder` tổng hợp từ 2 nguồn này.

### Memory Hub UI Layout
- **D-05:** Giao diện theo phong cách Grouped Cards (ScrollView) với các cards có cornerRadius 24, soft shadow, màu xanh nhẹ. Các cards: Profile, Calories & Body Metrics, Health Conditions, Food Preferences, Avoid Foods, AI Notes, AI Insights.
- **D-06:** Cards mặc định ở chế độ view-only (đẹp, premium). Edit thông qua nút "Chỉnh sửa".
  - Profile Card: Tap vào điều hướng tới màn hình Profile.
  - Các cards khác: Mở sheet editor riêng.
- **D-07:** Empty State cho người mới dùng sử dụng Illustration + CTA. Gồm hình vẽ não, mô tả "AI chưa hiểu rõ về bạn", và nút "Bắt đầu thiết lập AI Memory" mở flow hướng dẫn từng bước. Sau khi hoàn thành mới hiện UI cards.
- **D-08:** Ở màn hình Meals, thay thế card "AI nhớ về bạn" cũ bằng một Mini Badge gọn gàng, cao tầm 44-52pt. Hiển thị thông báo nhỏ, ví dụ: "🧠 AI đang cá nhân hoá theo hồ sơ sức khoẻ của bạn".

### AI Personality UX
- **D-09:** Personality Picker đặt thành một Card ở phía dưới trong Memory Hub. Không cần đặt ở Settings chung của app.
- **D-10:** Hỗ trợ 5 Personality Presets:
  1. 🌿 Thân thiện & Động viên (Default)
  2. 👨‍⚕️ Chuyên gia Nghiêm túc
  3. 🔥 Kỷ luật cao
  4. 🌈 Chill & Thoải mái
  5. 😄 Vui vẻ & Hài hước
- **D-11:** Khi user chạm vào một preset, sẽ áp dụng thay đổi (haptic nhẹ + card auto-scale), và hiển thị một bong bóng chat minh hoạ (sample preview bubble) nổi lên trong 2-3s trước khi tự tắt.

### Entry Point & Navigation
- **D-12:** Nhấn vào icon Brain từ tab Chat sẽ mở Memory Hub bằng `.fullScreenCover`, mang lại cảm giác không gian riêng và cao cấp thay vì dùng `.sheet` hay Push Navigation.
- **D-13:** Nhấn vào Mini Badge ở Meals tab cũng sẽ mở Memory Hub thông qua `.fullScreenCover` trực tiếp, đảm bảo trải nghiệm AI Hub là toàn cục (global) và liền mạch.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Context
- `.planning/REQUIREMENTS.md` — Phase 15 requirements (MEMH-01 to MEMH-04, PERS-01, PERS-02)
- `.planning/PROJECT.md` — App values and native iOS design constraints

### Existing AI/Memory Infrastructure
- `LiiO_EatClean/Data/Models/UserProfileMemory.swift` — Current struct-based model that needs converting to CoreData entities.
- `LiiO_EatClean/Services/MemoryManager.swift` — Current UserDefaults implementation (to be deprecated).
- `LiiO_EatClean/Features/AI/ContextBuilder.swift` — Where AIMemoryRepository and UserRepository need to be injected to construct prompts.
- `LiiO_EatClean/Data/Repositories/UserRepository.swift` — Current source for fetching user metrics.

### UI Integration Points
- `LiiO_EatClean/Features/Chat/ChatView.swift` — Entry point for brain icon (line 91-97).
- `LiiO_EatClean/Features/Meals/MealsView.swift` — Location for replacing MemorySummaryCard with Mini Badge.
- `LiiO_EatClean/Features/Meals/Components/MemorySummaryCard.swift` & `LiiO_EatClean/Features/Meals/Components/MemoryEditorView.swift` — Old UI components to deprecate or repurpose.
- `LiiO_EatClean/Features/Home/Components/StreakCardView.swift` — Reference for card styling.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Card styling components in `LiiO_EatClean/Features/Home/Components/` (e.g., `DailySummaryCardView`, `StreakCardView`) for building the Grouped Cards layout.
- `MealPlanSheet` for `.fullScreenCover` presentation patterns.
- `HapticManager` for subtle vibration feedback when switching personality.

### Established Patterns
- Repository Pattern: Create `AIMemoryRepositoryProtocol` and `AIMemoryRepository` utilizing `PersistenceController.shared.container.viewContext`.
- `@Observable` views for SwiftUI ViewModels.
- UI Components are extracted into separate files within `Components` folders to keep main Views clean.

### Integration Points
- Update `ChatView` toolbar button action to present MemoryHubView.
- Replace `MemorySummaryCard` in `MealsView` with a new `AIMemoryBadgeView`.
- Refactor `ChatViewModel` and `AIService` to read the selected Personality and append the correct style instruction into the System Prompt.

</code_context>

<specifics>
## Specific Ideas

- **Guided Setup State:** For new users, 5 simple steps: (Bệnh lý → Kiêng → Thích → Ghét → Lưu ý).
- **Personality Preview:** The sample preview should float near the selected card for a few seconds showing a quote in that personality.
- **Card Design:** cornerRadius: 24, soft shadow, light green accent (#4CAF50).

</specifics>

<deferred>
## Deferred Ideas

- None — discussion stayed within phase scope

</deferred>

---

*Phase: 15-ai-memory-hub-personality*
*Context gathered: 2026-05-07*
