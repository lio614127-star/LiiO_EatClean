# Phase 10: AI-Powered Meals Tab — Context

**Gathered:** 2026-05-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Build the Meals tab as the "daily eating control center" — a fully functional meal management + AI-powered suggestion interface. The tab currently shows a placeholder. This phase transforms it into: (1) a detailed meal log with full CRUD, (2) proactive AI suggestions based on remaining calories/preferences/health conditions, (3) a persistent memory system for user health data, (4) a learning system that extracts insights from user behavior, and (5) actionable AI output with direct meal logging.

This is NOT an AI chatbot tab — it's a tracking workspace enhanced with AI. The AI Coach tab (Phase 9) remains the conversational interface.

</domain>

<decisions>
## Implementation Decisions

### Memory Architecture
- **D-01:** Expand existing `UserProfileMemory` struct (Codable + UserDefaults). No CoreData migration needed for v1.
- **D-02:** New structure (AI-friendly, flat, not deeply nested):
  ```
  UserMemory
   ├── Identity (age, gender, goal)
   ├── HealthConditions[]
   │     ├── name (e.g., "fatty liver")
   │     ├── avoidFoods[] (e.g., ["fried food", "alcohol"])
   │     ├── notes (dietary guidance)
   ├── Preferences
   │     ├── likes[] (e.g., ["phở", "cơm gà"])
   │     ├── dislikes[] (e.g., ["rau mùi"])
   ├── DietaryNotes[] (general notes)
  ```
- **D-03:** `avoidFoods` MUST be per-condition (not global). Global dislikes stay in `Preferences.dislikes`.
- **D-04:** Data must be structured (not raw chat text). Easy to convert to prompt. Keep size small — injected every AI call.
- **D-05:** Memory is independent from chat history — persists across chat resets.

### Meals Tab Layout
- **D-06:** Layout = "Meals Log + AI Section". Top: detailed meal list. Bottom: proactive AI suggestion section.
- **D-07:** Today's Meals = Detailed List grouped by meal type (Sáng/Trưa/Tối/Vặt). Each item shows: food name + kcal + P/C/F macro mini display.
- **D-08:** Swipe actions: left = delete, right = edit (native iOS pattern). Tap = edit quantity/meal type.
- **D-09:** AI Section is PROACTIVE — auto-suggests based on remaining calories without requiring user tap. Shows: "Bạn còn X kcal" + 1-2 suggestion cards + "Gợi ý thêm" button.
- **D-10:** Role separation: Home = quick overview, Meals = workspace/management, AI Coach = conversation.

### Learning System (Hybrid)
- **D-11:** Level 1 (simple, client-side): Keyword/regex scan for patterns like "thích X", "ghét Y", "không ăn Z". No AI call needed.
- **D-12:** Level 2 (complex, AI extract): For sentences like "bác sĩ bảo hạn chế đồ chiên vì gan nhiễm mỡ" → send extraction prompt to AI.
- **D-13:** ALWAYS popup confirm before saving to memory. Never auto-save. ("Bạn có muốn lưu thông tin này không?" + [Lưu] [Bỏ qua])
- **D-14:** Standardized `memory_update` JSON format: `{"type": "add_condition"|"add_dislike"|"add_preference", "value": "...", "avoid": [...]}`.
- **D-15:** Only extract long-term/repeating information. "Hôm nay tôi ăn phở" is NOT a preference — don't extract.

### Context Builder Strategy
- **D-16:** Refactor `ContextBuilder` to Strategy Pattern. Core builder + enum-based strategies.
- **D-17:** Four strategies for v1:
  - `.chat` — Goal + basic memory (existing behavior)
  - `.mealSuggestion` — Remaining calories + meal type + preferences + dislikes + health conditions + strict avoid rules
  - `.healthAdvice` — Full health conditions + dietary notes + longer explanations allowed
  - `.progressAnalysis` — 7-day history + weight trend + goal progress
- **D-18:** Meal suggestion strategy PRIORITY ORDER: 1) Avoid foods (bệnh lý) → 2) Calorie constraint → 3) Preferences. If violated, AI suggestions are dangerous.
- **D-19:** Implementation: enum + switch for v1. Don't over-engineer with protocols/abstract classes.

### Actionable AI (from Phase 9, extended)
- **D-20:** Reuse `AISuggestedFood` model and `ActionableMessageView` pattern from Chat tab.
- **D-21:** Each suggestion card has "Log Ngay" button → saves directly to meal log without leaving Meals tab.
- **D-22:** AI returns structured JSON output (same format as Phase 9 chat actions).

</decisions>

<canonical_refs>
## Canonical References

### Prior Phase Context
- `.planning/phases/09-ai-nutritionist-chat/09-CONTEXT.md` — Chat architecture, ContextBuilder, MemoryManager, ActionableMessageView decisions.
- `.planning/phases/07-profile-ai/07-CONTEXT.md` — AIService architecture, JSON parsing, multi-key rotation.
- `.planning/phases/05-meal-logging/05-CONTEXT.md` — Meal saving mechanisms, MealRepository.

### Project Context
- `.planning/ROADMAP.md` — Phase 10 success criteria
- `.planning/PROJECT.md` — Core value and constraints

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets (MUST reuse, not duplicate)
- `ContextBuilder` (`Features/AI/ContextBuilder.swift`) — Refactor to Strategy Pattern, don't create new class.
- `MemoryManager` (`Services/MemoryManager.swift`) — Extend with new `UserProfileMemory` structure.
- `UserProfileMemory` (`Data/Models/UserProfileMemory.swift`) — Expand from 3 fields to full structure.
- `AIService` (`Features/AI/AIService.swift`) — Reuse `suggestMeals()` and `parseChatResponse()`.
- `AISuggestedFood` (in `AIService.swift`) — Reuse for suggestion cards.
- `ActionableMessageView` (`Features/Chat/Components/ActionableMessageView.swift`) — Adapt card design for Meals tab.
- `MealCardView` (`Features/Home/Components/MealCardView.swift`) — Reference for meal display patterns.
- `MealRepository` (`Data/Repositories/MealRepository.swift`) — Reuse for saving logged meals.

### Integration Points
- `MealsView` (`Features/Meals/MealsView.swift`) — Currently placeholder, will be completely rebuilt.
- `ContentView` (`App/ContentView.swift`) — Tab 1 (Meals) already wired.
- `HomeViewModel` — Reference for loading meals by type, remaining calories calculation.

### Patterns to Follow
- `@Observable` macro (not ObservableObject) — per project rules.
- Repository protocols — never access CoreData directly from ViewModels.
- `MealFoodModel` snapshot pattern for historical accuracy.

</code_context>

<deferred>
## Deferred Ideas
- Voice input for learning system (extracted preferences from speech).
- Confidence scoring for auto-accept high-confidence memory updates.
- Memory management UI (view/edit/delete saved memories) — could be part of Profile settings.
- Workout-aware meal suggestions (integrating exercise data).
- Fasting plan strategy for ContextBuilder.
</deferred>

---

*Phase: 10-ai-meals-tab*
*Context gathered: 2026-05-04*
