# Phase 7: Profile & AI Meal Suggestions — Summary

**Executed:** 2026-04-29
**Status:** Completed ✅

## Implementation Summary

Phase 7 completes the user-facing intelligence layer of LiiO EatClean, turning it from a calorie tracker into a smart dietary assistant.

### Data Layer Enhancements
- **`UserRepository`**: Fully implemented `fetchAPIKeys()`, `saveAPIKey(_:)`, and `deleteAPIKey(provider:)` using CoreData. Upsert logic: saves a new key or overwrites the existing key for the same provider (Gemini or OpenAI).

### AIService (Native URLSession)
- **No third-party SDK required.** `AIService.swift` makes raw HTTP POST calls to:
  - **Primary:** Google Gemini `gemini-1.5-flash` REST API.
  - **Fallback:** OpenAI `gpt-4o-mini` (triggers automatically on HTTP 429/401).
- **Strict Prompt Engineering:** The system prompt forces the LLM to return a JSON array of `[{name, calories, protein, carbs, fat, servingSize}]` with no additional text.
- **Robust JSON Parsing:** Strips markdown code fences (` ```json `) before decoding. If decoding fails, throws `AIError.invalidResponse` instead of crashing.

### ProfileView
- Standard iOS `Form` with three sections:
  1. **Thông tin cá nhân** (Name, Age, Height, Weight)
  2. **Mục tiêu** (Goal picker, daily calorie target)
  3. **AI API Keys** — Masked display of active keys + secure inline input for adding/removing Gemini/OpenAI keys.

### AI Integration in AddMealView
- **"✨ Hỏi AI" button** displayed in a context bar showing remaining calories for the day.
- **Lazy API Key Gate:** If no key is saved, tapping "Hỏi AI" shows an alert directing the user to Profile — zero onboarding friction otherwise.
- **Suggestion Cards:** Each AI-returned food is rendered as a card with macros. The **"+ Log"** button immediately adds the item to the Cart at qty=1.
- **Progressive Disclosure:** The AI section is collapsible ("Ẩn") and stays out of the way if not used.

## Full AI Flow
```
Add Meal Sheet
  → Bấm "✨ Hỏi AI"
  → [Chưa có key] → Alert → Profile để nhập key
  → [Có key] → Gọi Gemini API
     → Thành công → Render card [Phở Bò 400 kcal] [+ Log]
     → Lỗi quota → Auto retry OpenAI
     → Lỗi parse → Alert thân thiện, không crash
  → Bấm "+ Log" → Vào Cart → Hoàn tất → Lưu CoreData
```

## Next Steps
Phase 8: Water Tracking + Smart Reminders + Final Polish (MVP completion!)
