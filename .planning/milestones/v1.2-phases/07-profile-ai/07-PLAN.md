# Phase 7: Profile & AI Meal Suggestions

## Goal Description
Implement the "Profile" tab to allow users to update their personal details, goals, and API keys. Build a native Swift `AIService` that connects to the Gemini (primary) and OpenAI (fallback) APIs using `URLSession`. Integrate an "Hỏi AI" action button inside the `AddMealView` that fetches AI meal suggestions dynamically formatted as JSON and displays them as loggable items in the Cart UI.

## User Review Required
> [!IMPORTANT]
> - Since we are building `AIService` natively using `URLSession`, we avoid heavy 3rd-party dependencies.
> - The prompt will be hardcoded in the `AIService` to ensure it always returns a structured JSON array of foods with macros matching the `FoodItemModel`.
> - If no API key is set, the user is lazily directed to the Profile tab. Do you approve this architecture?

## Open Questions
- None.

## Proposed Changes

### 1. Data Layer Enhancements
Update user and API key persistence.
#### [MODIFY] [UserRepository.swift](file:///c:/Users/K2HPC/OneDrive/Desktop/CodeToolLiiO/LiiO_EatClean/LiiO_EatClean/Data/Repositories/UserRepository.swift)
- Fully implement `fetchAPIKeys()` and `saveAPIKey(_:)` using CoreData.
- Fully implement `saveUser(_:)` to update weight, height, and goals.

### 2. Core Service
Implement the AI networking layer.
#### [NEW] [AIService.swift](file:///c:/Users/K2HPC/OneDrive/Desktop/CodeToolLiiO/LiiO_EatClean/LiiO_EatClean/Features/AI/AIService.swift)
- Provide a robust method `func suggestMeals(remainingCalories: Double, mealType: String) async throws -> [FoodItemModel]`.
- Handle rotating from Gemini API to OpenAI API if the primary fails.
- Implement strict JSON parsing fallback and regex cleaning.

### 3. UI: Profile
#### [MODIFY] [ProfileView.swift](file:///c:/Users/K2HPC/OneDrive/Desktop/CodeToolLiiO/LiiO_EatClean/LiiO_EatClean/Features/Profile/ProfileView.swift)
- Create a `Form` with sections for Personal Info, Goals, and AI API Keys.
- Bind form text fields to `UserRepository` to persist automatically.
#### [NEW] [ProfileViewModel.swift](file:///c:/Users/K2HPC/OneDrive/Desktop/CodeToolLiiO/LiiO_EatClean/LiiO_EatClean/Features/Profile/ProfileViewModel.swift)
- Handle state logic for Profile UI.

### 4. UI: AI Integration in Add Meal
#### [MODIFY] [AddMealView.swift](file:///c:/Users/K2HPC/OneDrive/Desktop/CodeToolLiiO/LiiO_EatClean/LiiO_EatClean/Features/Meals/AddMealView.swift)
- Add a "✨ Gợi ý bằng AI" button.
- Display a shimmer/loading indicator during the AI fetch.
- Render the `[FoodItemModel]` array returned by the AI with "Thêm" (Log) buttons.
#### [MODIFY] [AddMealViewModel.swift](file:///c:/Users/K2HPC/OneDrive/Desktop/CodeToolLiiO/LiiO_EatClean/LiiO_EatClean/Features/Meals/AddMealViewModel.swift)
- Calculate `remainingCalories`.
- Manage AI loading state and hold `suggestedFoods`.

## Verification Plan

### Automated Tests
- N/A for MVP.

### Manual Verification
1. Open Profile tab, ensure User details can be edited and saved.
2. Enter a valid Gemini API Key in Profile.
3. Open Add Meal Sheet -> Tap "Hỏi AI". Verify that a loading state appears and structured meal items (Phở, Cơm, etc.) are rendered.
4. Tap "Thêm" on an AI suggestion, ensure it goes into the Cart accurately.
5. Remove API Key -> Tap "Hỏi AI" -> Verify graceful alert requesting a key.
