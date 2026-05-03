# Phase 9: AI Nutritionist Chatbox - Context

**Gathered:** 2026-05-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Build a dedicated "AI Coach" feature in a new Tab (Tab 5). This is a conversational AI assistant acting as a friendly, supportive nutritionist. It remembers user preferences, intelligently injects health context (7-day summary) only when relevant, and provides actionable responses (e.g., logging meals directly from chat). The goal is to evolve the app from a calorie tracker into a true AI nutrition assistant.

</domain>

<decisions>
## Implementation Decisions

### Entry Point
- **D-01:** Dedicated Chat Tab: The Chatbot will live in its own tab. It is a major feature, not a quick action. This ensures stable UI, preserves chat history without cluttering other flows, and separates "tracking" from "coaching" (similar to MyFitnessPal).

### Context Injection (Hybrid Approach)
- **D-02:** Default Injections: The prompt will ALWAYS include the user's Goal (lose/maintain/gain) and Daily Calories target.
- **D-03:** Intent-based Summary Injection: The app will NOT send the full 7-day data on every message to save tokens and speed up response. Only when the app detects a relevant intent (e.g., "How am I doing lately?", "Am I losing weight?"), will it inject a 7-day summary (calories, macros, water, weight).
- **D-04:** Controlled Memory (`UserProfileMemory`): The app will not store the full chat history for long-term AI memory. Instead, it will maintain a structured `UserProfileMemory` (preferences, dislikes, dietary notes) that is sent with the context.

### Actionable Chat (The Core Value)
- **D-05:** JSON Action Blocks: The AI will return structured JSON blocks alongside regular text. The Chat UI will parse this JSON and render interactive UI elements (e.g., a Card with `[ Phở bò - 400 kcal ]` and a `[ Log Meal ]` button).
- **D-06:** Instant Logging: Tapping an action button in the chat must instantly log the item/meal without navigating away from the chat screen.

### Persona
- **D-07:** Friendly & Supportive: The AI must act as an encouraging personal coach. No judgment or scolding. (e.g., "Hôm nay bạn hơi vượt nhẹ, ngày mai mình cân bằng lại nhé 👍"). This aligns with Apple Health's supportive mindset.

### App Awareness (System Prompt)
- **D-08:** Concise App Manual: The system prompt will briefly inform the AI of its capabilities (can suggest meals, can log meals via JSON, can reference goals) and the app's features (Track calories, water, progress). Do not waste tokens describing UI elements.

</decisions>

<canonical_refs>
## Canonical References

### Prior Phase Context
- `.planning/phases/07-profile-ai/07-CONTEXT.md` — AI Service architecture and JSON parsing patterns.
- `.planning/phases/05-meal-logging/05-CONTEXT.md` — Meal saving mechanisms.

### Project Context
- `.planning/REQUIREMENTS.md` — CHAT-01 to CHAT-05
- `.planning/ROADMAP.md` — Phase 9 success criteria

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `AIService`: Will need to be extended or wrapped (e.g., `AIChatService`) to support conversational history (`messages` array) instead of one-shot generation.
- `AISuggestedFood`: Can be reused for the actionable meal cards in chat.

### Integration Points
- `TabView` in `ContentView`: Needs a 5th tab for the Chat feature.
- `ContextBuilder` (New): Needed to construct the prompt with intent-based hybrid injection.
- `MemoryManager` (New): Needed to manage `UserProfileMemory` in CoreData or UserDefaults.

</code_context>

<specifics>
## Specific Ideas

- **Architecture:**
  ```text
  Chat Tab
   → ChatViewModel
     → AIService (Extended for chat)
       → ContextBuilder (Builds prompt dynamically)
       → MemoryManager (Fetches preferences)
       → APIKeyManager (Reused from Phase 7)
  ```
- **Actionable JSON Format Example:**
  The AI might respond with text followed by:
  ```json
  {
    "action": "suggest_meal",
    "items": [
      { "name": "Phở bò", "calories": 400, "protein": 30, "carbs": 50, "fat": 10, "servingSize": 1 }
    ]
  }
  ```

</specifics>

<deferred>
## Deferred Ideas
- Voice input/output for the chatbot.
- Deep integration with HealthKit for the 7-day summary (currently relies on local app data).
</deferred>

---

*Phase: 09-ai-nutritionist-chat*
*Context gathered: 2026-05-03*
