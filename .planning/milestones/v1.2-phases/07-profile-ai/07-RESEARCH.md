# Phase 7: Profile & AI Meal Suggestions — Research

**Gathered:** 2026-04-29

## 1. Data Layer (UserRepository & APIKeyModel)
- `UserRepository` currently stubs `fetchAPIKeys` and `saveAPIKey`.
- We need to implement CoreData `APIKey` entity fetching and saving. The CoreData schema already has: `id(UUID), provider(String), key(String), isActive(Bool), createdAt(Date)`.
- We also need to fully implement updating user profile details via `saveUser()` so that changes made in the Profile tab (height, weight, daily target) persist properly.

## 2. AIService Configuration
- **Gemini API:** 
  - Endpoint: `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=\(geminiKey)`
  - JSON Body Format: `{ "contents": [{ "parts": [{"text": "prompt..."}] }] }`
- **OpenAI API:**
  - Endpoint: `https://api.openai.com/v1/chat/completions`
  - Headers: `Authorization: Bearer \(openAIKey)`
  - JSON Body Format: `{ "model": "gpt-4o-mini", "messages": [{"role": "user", "content": "prompt..."}], "response_format": { "type": "json_object" } }`
- We will construct the `AIService` to take the user's `dailyCalorieTarget` and current consumption to compute `RemainingCalories` dynamically before sending the prompt.

## 3. UI Changes
- **ProfileView:** We need a SwiftUI `Form` with 3 sections:
  1. Personal Information (Name, Age, Height, Weight).
  2. Goals (Goal Type, Daily Calories Target).
  3. API Settings (Manage Gemini/OpenAI keys).
- **AddMealView & AddMealViewModel:**
  - `AddMealViewModel` needs `var remainingCalories: Double` calculated from today's meals.
  - `AddMealView` needs a "✨ Hỏi AI" button prominently displayed (perhaps above the search list).
  - When AI returns results, display them in a list or a horizontal scroll view with a "Thêm" (Log) button that instantly invokes `viewModel.addToCart(food: quantity: 1)`.

## 4. Fallback Handling
- The `AIService` will perform a `do-catch` block. 
- If parsing fails, throw `AIError.invalidResponse`.
- If API keys are missing, throw `AIError.missingKey`.
- The `AddMealView` will catch these and present an `.alert` instructing the user to check their API keys or try again.
