# Phase 9: AI Nutritionist Chatbox

## Goal Description
This phase introduces a dedicated AI Chatbot acting as a friendly nutritionist. It handles hybrid context injection, maintains user preferences, and most importantly, parses actionable JSON from the AI to let users log meals directly from the chat interface.

## User Review Required
> [!IMPORTANT]
> - **Memory Storage:** For `UserProfileMemory` (preferences, dislikes), I plan to use `UserDefaults` for v1 to keep it lightweight and avoid CoreData migrations. Is this acceptable?
> - **JSON Parsing:** Returning JSON blocks intermixed with text can be tricky for some LLMs. We will use a strict system prompt instructing the AI to output actions inside standard markdown JSON blocks.

## Open Questions
- Do you want to use a specific markdown parser library for SwiftUI (e.g. `MarkdownUI`), or just rely on native iOS 15+ basic Markdown support in `Text()`?

## Proposed Changes

### 1. Data & Context Layer
#### [NEW] [UserProfileMemory.swift](file:///Users/liio/TooL_LiiO/LiiO_EatClean/LiiO_EatClean/Data/Models/UserProfileMemory.swift) — Struct to hold preferences, dislikes, and notes.
#### [NEW] [MemoryManager.swift](file:///Users/liio/TooL_LiiO/LiiO_EatClean/LiiO_EatClean/Services/MemoryManager.swift) — Service to save/load memory locally.
#### [NEW] [ContextBuilder.swift](file:///Users/liio/TooL_LiiO/LiiO_EatClean/LiiO_EatClean/Features/AI/ContextBuilder.swift) — Builds the dynamic system prompt with default injections and intent-based 7-day summaries.

### 2. AI Service Update
#### [NEW] [ChatMessage.swift](file:///Users/liio/TooL_LiiO/LiiO_EatClean/LiiO_EatClean/Data/Models/ChatMessage.swift) — Model representing a chat message with role and optional actions.
#### [MODIFY] [AIService.swift](file:///Users/liio/TooL_LiiO/LiiO_EatClean/LiiO_EatClean/Features/AI/AIService.swift) — Add `sendChatMessage` method to support conversation history and JSON parsing.

### 3. Chat Feature (UI)
#### [NEW] [ChatViewModel.swift](file:///Users/liio/TooL_LiiO/LiiO_EatClean/LiiO_EatClean/Features/Chat/ChatViewModel.swift) — Manages state, intent detection, and "Log Meal" action handling.
#### [NEW] [ChatView.swift](file:///Users/liio/TooL_LiiO/LiiO_EatClean/LiiO_EatClean/Features/Chat/ChatView.swift) — Main chat interface with ScrollView and text input.
#### [NEW] [ActionableMessageView.swift](file:///Users/liio/TooL_LiiO/LiiO_EatClean/LiiO_EatClean/Features/Chat/Components/ActionableMessageView.swift) — Renders message bubbles and interactive Action Cards.

### 4. App Integration
#### [MODIFY] [ContentView.swift](file:///Users/liio/TooL_LiiO/LiiO_EatClean/LiiO_EatClean/App/ContentView.swift) — Add ChatView as the 5th tab.

## Verification Plan
### Automated Tests
- None required for MVP.

### Manual Verification
1. Open the Chat Tab.
2. Send "Chào bác sĩ". AI should reply in a friendly tone without logging anything.
3. Send "Tôi vừa ăn 1 bát phở bò". AI should reply and the UI should render an actionable card for Phở bò.
4. Tap "Log Ngay" on the card. Verify the meal is added to today's log without switching tabs.
5. Ask "Dạo này tôi ăn thế nào?". Verify the AI correctly references recent calorie history via ContextBuilder injection.
