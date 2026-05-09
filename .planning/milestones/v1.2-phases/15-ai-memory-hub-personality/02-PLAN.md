---
wave: 2
depends_on: [01-PLAN.md]
files_modified:
  - LiiO_EatClean/App/LiiO_EatCleanApp.swift
  - LiiO_EatClean/Features/AI/ContextBuilder.swift
  - LiiO_EatClean/Services/MemoryManager.swift
autonomous: true
requirements: [MEMH-03, PERS-02]
---

# Plan 02: Data Migration & ContextBuilder Update

<objective>
Implement the automatic silent migration from UserDefaults to CoreData, display a success toast, and update the AI context pipeline to read from the new `AIMemoryRepository` and `UserRepository`.
</objective>

<action>
1. In `LiiO_EatCleanApp.swift` (or a dedicated `MigrationService.swift` called on app launch):
   - Check if `UserDefaults.standard.data(forKey: "com.liio.EatClean.userMemory")` exists.
   - If it exists, decode it into the old `UserProfileMemory` struct.
   - For each `HealthCondition` in the old struct, add it to `AIMemoryRepository` along with its avoid foods and dietary notes.
   - For each like/dislike, add as `FoodPreference`.
   - Add general `dietaryNotes`.
   - Once successfully saved to CoreData, remove the UserDefaults key.
   - Trigger a global toast or alert: "🧠 AI Memory đã được đồng bộ an toàn" (dismiss after 2s).

2. Deprecate `MemoryManager.swift`:
   - Either delete the file entirely or mark it as `@available(*, deprecated)` and route all its existing calls temporarily to `AIMemoryRepository` if they are heavily used, but ideally remove its usage completely across the app.

3. Update `ContextBuilder.swift`:
   - Inject `AIMemoryRepositoryProtocol` and `UserRepositoryProtocol`.
   - In context building strategies (like `MealLoggingStrategy`, `ChatStrategy`, etc.), fetch the current user profile (age, weight, height, BMR, TDEE, target) from `UserRepository`.
   - Fetch AI specific memory (health conditions, preferences, personality) from `AIMemoryRepository`.
   - Ensure the `personalityTone.promptInstruction` is appended to the system prompt to satisfy PERS-02.
</action>

<read_first>
- LiiO_EatClean/App/LiiO_EatCleanApp.swift
- LiiO_EatClean/Services/MemoryManager.swift
- LiiO_EatClean/Features/AI/ContextBuilder.swift
- LiiO_EatClean/Data/Repositories/UserRepository.swift
</read_first>

<acceptance_criteria>
- Migration logic checks UserDefaults, maps to CoreData, and deletes the old key on success.
- `MemoryManager` logic is effectively replaced by `AIMemoryRepository` in `ContextBuilder`.
- `ContextBuilder` outputs a prompt string that contains both the user's physical profile (from `UserRepository`) and AI preferences/personality (from `AIMemoryRepository`).
- The system prompt includes the instruction from the selected `AIPersonalityTone`.
</acceptance_criteria>
