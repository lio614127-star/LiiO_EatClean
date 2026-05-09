# Plan 10A: Memory System Upgrade + Context Strategy Refactor

**Wave:** 1 (Foundation — no dependencies)
**Requirements:** AIMEAL-01, AIMEAL-02, AIMEAL-07
**Depends on:** None

## Objective

Nâng cấp `UserProfileMemory` model từ 3 fields đơn giản lên hệ thống memory đầy đủ (bệnh lý, kiêng cữ theo bệnh, sở thích chi tiết) và refactor `ContextBuilder` sang Strategy Pattern với 4 strategies.

## Task 1: Expand UserProfileMemory Model

<read_first>
- LiiO_EatClean/Data/Models/UserProfileMemory.swift
- LiiO_EatClean/Services/MemoryManager.swift
- .planning/phases/10-ai-meals-tab/10-CONTEXT.md (decisions D-01 to D-05)
</read_first>

<action>
Replace the current `UserProfileMemory` struct with the expanded AI-friendly structure:

```swift
struct HealthCondition: Codable, Identifiable {
    var id = UUID()
    var name: String              // e.g., "Gan nhiễm mỡ"
    var avoidFoods: [String]      // e.g., ["Đồ chiên", "Rượu bia"]
    var dietaryNotes: String      // e.g., "Hạn chế chất béo, tăng rau xanh"
}

struct UserProfileMemory: Codable {
    var healthConditions: [HealthCondition] = []
    var likes: [String] = []           // replaces old preferences
    var dislikes: [String] = []        // keep existing
    var dietaryNotes: [String] = []    // replaces old notes
    
    // Computed: flatten all avoidFoods from all conditions for quick lookup
    var allAvoidFoods: [String] {
        healthConditions.flatMap { $0.avoidFoods }
    }
}
```

Key rules:
- `avoidFoods` is PER CONDITION (not global). Global dislikes stay in `dislikes` field.
- Keep Codable for UserDefaults serialization.
- Keep struct small — injected every AI call.
</action>

<acceptance_criteria>
- UserProfileMemory.swift contains `struct HealthCondition: Codable, Identifiable` with `name`, `avoidFoods`, `dietaryNotes`
- UserProfileMemory.swift contains `var healthConditions: [HealthCondition]`
- UserProfileMemory.swift contains `var likes: [String]`
- UserProfileMemory.swift contains `var allAvoidFoods: [String]` computed property
- `MemoryManager` continues to compile and serialize/deserialize the new structure via UserDefaults
</acceptance_criteria>

## Task 2: Update MemoryManager with New Helpers

<read_first>
- LiiO_EatClean/Services/MemoryManager.swift
</read_first>

<action>
Add helper methods to `MemoryManager` for the learning system and memory updates:

```swift
func addHealthCondition(_ condition: HealthCondition)
func removeHealthCondition(id: UUID)
func addLike(_ food: String)
func addDislike(_ food: String)
func removeLike(_ food: String)
func removeDislike(_ food: String)
func addDietaryNote(_ note: String)
func applyMemoryUpdate(_ update: MemoryUpdate)
```

Add `MemoryUpdate` struct for standardized updates from the learning system:

```swift
struct MemoryUpdate: Codable {
    enum UpdateType: String, Codable {
        case addCondition = "add_condition"
        case addLike = "add_like"
        case addDislike = "add_dislike"
        case addNote = "add_note"
    }
    let type: UpdateType
    let value: String
    var avoid: [String]? = nil
    var dietaryNotes: String? = nil
}
```
</action>

<acceptance_criteria>
- MemoryManager.swift contains `func addHealthCondition(_ condition: HealthCondition)`
- MemoryManager.swift contains `struct MemoryUpdate: Codable`
- MemoryManager.swift contains `func applyMemoryUpdate(_ update: MemoryUpdate)`
- All methods save to UserDefaults after modification
</acceptance_criteria>

## Task 3: Refactor ContextBuilder to Strategy Pattern

<read_first>
- LiiO_EatClean/Features/AI/ContextBuilder.swift
- LiiO_EatClean/Features/Chat/ChatViewModel.swift (current consumer)
- .planning/phases/10-ai-meals-tab/10-CONTEXT.md (decisions D-16 to D-19)
</read_first>

<action>
Refactor `ContextBuilder` to use Strategy Pattern with enum:

```swift
enum ContextStrategy {
    case chat                    // Goal + basic memory (existing behavior)
    case mealSuggestion          // Remaining cals + meal type + prefs + health conditions
    case healthAdvice            // Full health conditions + dietary notes
    case progressAnalysis        // 7-day history + weight + goal progress
}
```

Refactor `buildSystemPrompt(for:)` into `buildSystemPrompt(for:strategy:remainingCalories:mealType:)`.

For `.mealSuggestion` strategy, enforce PRIORITY ORDER:
1. **Avoid foods** (from healthConditions) — FIRST in prompt, marked as [CẤM]
2. **Calorie constraint** — remaining calories + target
3. **Preferences** — likes (ưu tiên) + dislikes (tránh)

For `.chat` strategy — keep existing behavior (goal + basic memory + intent-based 7-day injection).

For `.healthAdvice` — inject full healthConditions with detailed notes.

For `.progressAnalysis` — inject 7-day calorie + weight data always (not intent-based).

**IMPORTANT:** Do NOT break ChatViewModel — it must still work with the refactored ContextBuilder. ChatViewModel should pass `.chat` strategy.
</action>

<acceptance_criteria>
- ContextBuilder.swift contains `enum ContextStrategy` with 4 cases
- ContextBuilder.swift has method signature `buildSystemPrompt(for:strategy:remainingCalories:mealType:)`
- `.mealSuggestion` strategy prompt contains `[CẤM]` section for avoid foods BEFORE calorie section
- ChatViewModel.swift compiles and passes `.chat` strategy to ContextBuilder
- Existing Chat tab functionality is not broken
</acceptance_criteria>

## Verification

### Manual Verification
1. Build project — no compile errors.
2. Open Chat tab — verify AI responses still work normally (`.chat` strategy backward compatible).
3. In Xcode console, verify `MemoryManager.shared.fetchMemory()` returns the new structure.
4. Add a test HealthCondition via debug code — verify it serializes to UserDefaults and deserializes correctly.
