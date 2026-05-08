# Phase 19: Offline Mode & Custom Foods - Context

**Gathered:** 2026-05-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Xây dựng Offline Mode cho app hoạt động đầy đủ khi không có internet (dashboard, lịch sử, meal logging từ local DB/custom foods) và Custom Food Builder để user tạo món ăn cá nhân hoá với macro tracking. Bao gồm network monitoring infrastructure, graceful degradation cho AI features, và pending chat queue.

Requirements: OFFL-01, OFFL-02, CFOD-01, CFOD-02

</domain>

<decisions>
## Implementation Decisions

### 1. Offline Detection & Network Monitoring

- **D-01:** Dùng `NWPathMonitor` singleton — tạo `NetworkMonitor` class publish `isConnected`, `connectionType` (wifi/cellular/ethernet/unknown), `isExpensive`. Chuẩn Apple, zero-dependency, real-time detection.
- **D-02:** Centralized check — tất cả services route qua `NetworkMonitor` singleton hoặc `@EnvironmentObject`. KHÔNG mỗi service tự check internet riêng.
- **D-03:** App-wide consistency — `AIService`, `MealsView`, `ChatView`, `MealPlanViewModel` đều subscribe cùng 1 source of truth.

### 2. Offline UI/UX — Degradation Strategy

- **D-04:** Feature availability matrix:
  | Feature | Offline |
  |---------|---------|
  | View meals/dashboard | ✅ |
  | Add meals manually | ✅ |
  | View summaries | ✅ |
  | Memory Hub | ✅ |
  | Custom Food Builder | ✅ |
  | AI Coach | ❌ |
  | Meal generation | ❌ |
  | Barcode AI scan | ❌ |
  | Voice (cloud) | ❌ |

- **D-05:** Floating offline banner — subtle top banner "📡 Không có kết nối mạng", auto-hide khi online. KHÔNG popup. Khi online lại: "🟢 Đã kết nối lại".
- **D-06:** AI buttons disabled state — opacity 0.45-0.6, saturation giảm, tap animation off. Nút vẫn visible nhưng grayed out.
- **D-07:** Context-aware toast khi tap disabled button — "📡 Meal Plan cần AI để phân tích dinh dưỡng" (KHÔNG generic "No internet"). Duration 1.5-2s.
- **D-08:** Chat input vẫn gõ được khi offline — send button disabled, nhưng user soạn trước. Online lại → gửi ngay.
- **D-09:** Speech recognition: on-device (Apple Speech) vẫn cho record khi offline; cloud-based AI features disable hoàn toàn.

### 3. Connection Recovery

- **D-10:** Khi online lại: auto-retry pending chat messages, refresh daily summaries, resume uploads.
- **D-11:** Recovery banner: "🟢 Đã kết nối lại" — auto-hide sau 2-3s.

### 4. Custom Food Builder — Entry Point & UX

- **D-12:** Entry point trong FoodSearchView:
  - Header: nút "+" subtle "Tạo món riêng"
  - Empty state: CTA lớn "✨ Tạo món mới" khi search không tìm thấy
- **D-13:** Sheet presentation — `CustomFoodBuilderSheet`, KHÔNG push navigation. Nhanh hơn.
- **D-14:** Required fields: Name, Calories, Protein, Carbs, Fat
- **D-15:** Optional fields: Serving size, Notes, Category, Brand, Photo
- **D-16:** Auto-calculate calories: `Calories = 4×Protein + 4×Carbs + 9×Fat` — realtime khi user nhập macros.
- **D-17:** Realtime validation — cảnh báo "⚠️ Macro calories không khớp" nếu manual calories lệch quá nhiều so với formula.
- **D-18:** Dual save buttons: "Lưu món" + "Lưu & thêm vào bữa" — tránh user phải quay lại search chọn lại.

### 5. Custom Food Management — Edit/Delete

- **D-19:** Primary: Swipe left trên custom food trong search → Edit / Delete
- **D-20:** Secondary: Long press context menu → ✏️ Chỉnh sửa / 📄 Nhân bản / 🗑 Xóa
- **D-21:** Duplicate feature — clone món → sửa nhanh (ví dụ: "Cơm gà 500g" → "Cơm gà 300g")
- **D-22:** Delete UX — Swipe delete + undo toast "🗑 Đã xóa món [Hoàn tác]". KHÔNG alert popup.
- **D-23:** Edit flow — mở lại CustomFoodBuilderSheet với prefilled data.
- **D-24:** Model additions: thêm `createdAt`, `updatedAt` cho FoodItemModel.

### 6. Custom Food trong Search — Display & Priority

- **D-25:** Section riêng "⭐ Món của bạn" luôn trên cùng search results.
- **D-26:** Section order: ⭐ Món của bạn → 🕘 Gần đây → 📦 Dữ liệu offline → 🌐 CalorieNinjas
- **D-27:** Chỉ hiện section khi có data — KHÔNG hiện section rỗng.
- **D-28:** Visual distinction: ⭐ icon + subtle tint + "Custom" pill cho custom foods.
- **D-29:** Search priority: exact custom → exact recent → exact local → fuzzy local → API.
- **D-30:** Save animation: "✨ Đã thêm vào Món của bạn" + item animate vào section.

### 7. Offline Queueing — Chat Only (v1)

- **D-31:** Queue chỉ Chat messages cho v1. Meal Plan, Voice, Suggestions → disable + block + notify.
- **D-32:** `PendingChatMessage` model: `id: UUID`, `text: String`, `createdAt: Date`, `conversationID: UUID`.
- **D-33:** Persist trong CoreData — queue sống sót app restart. KHÔNG chỉ in-memory.
- **D-34:** Pending UI: chat bubble "🕘 Đang chờ kết nối..." → online → auto-send → streaming response.
- **D-35:** Retry UX: "Đã gửi" hoặc "Không gửi được • Thử lại".
- **D-36:** Chỉ queue user-generated content. KHÔNG queue AI state, streaming, orchestration.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Context
- `.planning/REQUIREMENTS.md` — Phase 19 requirements (OFFL-01, OFFL-02, CFOD-01, CFOD-02)
- `.planning/PROJECT.md` — App values, native iOS design constraints

### Prior Phase Context
- `.planning/phases/18-advanced-insights-health-aware-ai/18-CONTEXT.md` — Health-aware AI decisions (safety layers, insight types)
- `.planning/phases/16-api-infrastructure-context-compression/16-CONTEXT.md` — API key pool, context compression, parallel request architecture

### Food System (Primary refactor targets)
- `LiiO_EatClean/Data/Models/FoodItemModel.swift` — Current model with `isCustom: Bool` (unused). Needs `createdAt`, `updatedAt`.
- `LiiO_EatClean/Data/Protocols/FoodRepositoryProtocol.swift` — Repository protocol, needs custom food CRUD methods.
- `LiiO_EatClean/Data/Repositories/FoodRepository.swift` — CoreData-backed implementation, needs custom food queries + priority sorting.
- `LiiO_EatClean/Features/Meals/FoodSearchView.swift` — Current search UI with 2 sections (offline, API). Needs 4-section layout + custom food entry point.
- `LiiO_EatClean/Features/Meals/FoodSearchViewModel.swift` — Search logic with debounce + auto-cache. Needs custom food priority + section separation.
- `LiiO_EatClean/Services/FoodAPIService.swift` — CalorieNinjas API with silent fail. Needs network-aware guard.

### AI & Chat System (Offline integration targets)
- `LiiO_EatClean/Features/AI/AIService.swift` — Current AI service. Needs `NetworkMonitor` guard before API calls.
- `LiiO_EatClean/Features/Chat/ChatViewModel.swift` — Chat logic. Needs pending message queue integration.
- `LiiO_EatClean/Features/Meals/MealPlanViewModel.swift` — Meal plan generation. Needs offline disable.

### Dashboard
- `LiiO_EatClean/Features/Home/HomeViewModel.swift` — Dashboard loads from CoreData (already offline-compatible). Needs offline banner state.
- `LiiO_EatClean/Features/Home/HomeView.swift` — Dashboard UI. Needs floating offline banner.

### CoreData
- `LiiO_EatClean/Data/Persistence/Persistence.swift` — PersistenceController singleton. May need schema update for PendingChatMessage.
- `LiiO_EatClean/LiiO_EatClean.xcdatamodeld/` — CoreData model. Needs PendingChatMessage entity + FoodItem attribute updates.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `FoodItemModel` already has `isCustom: Bool` field — just needs activation + `createdAt`/`updatedAt` additions.
- `FoodRepository.saveFood()` already handles upsert logic (check by name, create or update) — extend for custom food CRUD.
- `FoodRepository.seedDatabaseIfNeeded()` uses `VietnameseFoods.json` — custom foods live alongside seeded data.
- `FoodSearchView` already has sectioned List layout (local + API sections) — extend to 4 sections.
- `FoodSearchViewModel.normalizeToSinglePortion()` — reusable for custom food portion normalization.
- `HapticManager` — available for all feedback (save, delete, offline tap).
- `AIActivityCenter` — can be extended for offline status broadcasting.

### Established Patterns
- Repository Pattern: All data access through protocol → implementation. New `NetworkMonitor` should follow singleton pattern like `PersistenceController`.
- `@Observable` ViewModels for SwiftUI reactivity — `NetworkMonitor` should use `@Observable` or `ObservableObject`.
- Sheet presentation: `.sheet(isPresented:)` for modals (consistent with AddMealView, BarcodeScanView).
- Swipe-to-delete: Already used in cart items (AddMealView) — extend to custom foods.
- Toast/banner: Can leverage existing `MilestonePopupView` animation pattern for offline banner.

### Integration Points
- `AIService.performRequest()` — add `guard networkMonitor.isConnected` before any HTTP call.
- `FoodSearchViewModel.performSearch()` — skip API search when offline (already silent-fails, but should skip entirely).
- `ChatViewModel` — add pending message queue logic before `sendMessage()`.
- `AddMealView.aiSuggestionBar` — disable AI/Voice/Barcode buttons based on `NetworkMonitor.isConnected`.
- `MealPlanSheet` — disable generation buttons when offline.
- `ContentView` / root view — inject `NetworkMonitor` as environment object + floating banner overlay.

</code_context>

<specifics>
## Specific Ideas

- **Offline banner design:** Floating top banner, subtle, auto-hide. Giống Apple system alerts style.
- **Custom food icon:** ⭐ star icon, subtle green tint to match app brand (#4CAF50).
- **Toast messages:** Context-aware, ví dụ: "📡 Meal Plan cần AI để phân tích dinh dưỡng" — không generic.
- **Auto-calculate UX:** Khi user nhập protein/carbs/fat → calories field auto-updates realtime. User có thể override manual → warning nếu lệch.
- **"Lưu & Log ngay":** 1-tap save + add to cart — đặc biệt quan trọng cho flow "search → không có → tạo → log".
- **Connection recovery:** "🟢 Đã kết nối lại" banner + auto-retry pending chats — feels cực smart.

</specifics>

<deferred>
## Deferred Ideas

- "My Foods" management screen trong Profile — batch management khi user có 50+ custom foods (future)
- Queue meal plans, voice uploads offline → v2 (quá phức tạp cho v1, stale context risk)
- Chip filter bar trong search (All | Mine | Recent) — future enhancement
- Auto-adjust macro ranges theo goal type trong custom food — future
- Cloud sync custom foods → v2.0 với CloudKit
- Remote health_food_mapping.json updates — future versioning
- `isExpensive` network detection → warn before heavy AI operations on cellular (nice-to-have)

</deferred>

---

*Phase: 19-offline-mode-custom-foods*
*Context gathered: 2026-05-08*
