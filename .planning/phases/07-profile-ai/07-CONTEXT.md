# Phase 7: Profile & AI Meal Suggestions - Context

**Gathered:** 2026-04-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Build the "Profile" tab for managing user settings, goals, and API keys. Integrate generative AI (OpenAI/Gemini) to act as a dietary assistant. The AI will provide actionable meal suggestions in the form of structured JSON, which the app will parse and present as loggable items directly inside the Add Meal flow.

</domain>

<decisions>
## Implementation Decisions

### AI Trigger Placement
- **D-01:** Add Meal Sheet Integration: The "Hỏi AI" button will be placed inside the `AddMealView`. This triggers the AI exactly when the user is deciding what to eat, minimizing cognitive load and keeping the Home screen clean.

### API Key Onboarding
- **D-02:** Lazy Prompting: The app will not block initial onboarding with API key requests. Instead, when the user first taps "Hỏi AI", if no key is found, the app will show an alert/popup directing them to the Profile page to enter their API Key.

### UI Profile
- **D-03:** Standard iOS Form: The `ProfileView` will utilize SwiftUI's standard `Form` and `Section` elements for a clean, native, and highly maintainable settings interface.

### AI Response Parsing
- **D-04:** Strict JSON Actionable Responses: The AI integration must strictly instruct the LLM to return valid JSON (e.g., an array of suggested foods with macros). The app will parse this JSON and render interactive cards. If parsing fails, it must fallback gracefully (e.g., show text) without crashing.
- **D-05:** "Log Ngay" Flow: The parsed JSON items will be displayed with a "Log" button, allowing users to add the AI's suggestion to their meal instantly. "AI for action, not just chat."

</decisions>

<canonical_refs>
## Canonical References

### Prior Phase Context
- `.planning/phases/01-project-foundation/01-CONTEXT.md` — CoreData schema (APIKey entity)
- `.planning/phases/05-meal-logging/05-CONTEXT.md` — Meal logging Cart architecture (for "Log Ngay")

### Project Context
- `.planning/REQUIREMENTS.md` — PROF-01 to PROF-04, AI-01 to AI-04
- `.planning/ROADMAP.md` — Phase 7 success criteria

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `UserRepository` — Needs implementation of `fetchAPIKeys()` and `saveAPIKey(_:)`.
- `AddMealViewModel` — Already handles the Cart state; the parsed AI items will simply be added to this Cart when the user taps "Log".

### Integration Points
- `AddMealView`: Needs a new "Hỏi AI" button and an area to display the AI's suggestions.
- `ProfileView`: Needs to be fleshed out with `Form` sections for Personal Info, Goals, and API Keys.

</code_context>

<specifics>
## Specific Ideas

- **Prompt Engineering:** The prompt sent to the LLM must include:
  1. User's remaining calories.
  2. The specific meal type (e.g., Bữa trưa).
  3. A strict JSON schema request.
  4. An instruction to prioritize Vietnamese foods.
- **JSON Schema Example:**
  ```json
  [
    { "name": "Phở gà", "calories": 350, "protein": 25, "carbs": 45, "fat": 8, "servingSize": 1 }
  ]
  ```

</specifics>

<deferred>
## Deferred Ideas

- Advanced AI chat interface (conversational memory beyond the single query).
- Automatic image generation for suggested foods.

</deferred>

---

*Phase: 07-Profile-AI*
*Context gathered: 2026-04-29*
