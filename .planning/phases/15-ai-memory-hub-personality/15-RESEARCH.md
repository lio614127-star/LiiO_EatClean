# Phase 15: AI Memory Hub & Personality - Research

## Context
Migrate `MemoryManager` from `UserDefaults` to CoreData using `AIMemoryRepository`. Create a new full-screen AI Memory Hub, deprecate old meals tab components, and implement a global AI personality prompt tuning system.

## Data Schema & Migration
1. **Core Data Entities Required**:
   - `AIMemory` (Root): relationships to other entities, personality setting.
   - `HealthCondition`: `id`, `name`, `dietaryNotes`.
   - `AvoidFood`: `id`, `name`.
   - `FoodPreference`: `id`, `name`, `type` (like/dislike).
   - `DietaryNote`: `id`, `content`.
   - `AIInsight`: `id`, `content`, `date`.
   
   Need to modify `LiiO_EatClean.xcdatamodeld` to add these entities and relationships.

2. **Migration Logic**:
   - At launch, check if `UserDefaults.standard.data(forKey: "com.liio.EatClean.userMemory")` exists.
   - If yes, decode into `UserProfileMemory` struct.
   - Map properties to new CoreData entities using `AIMemoryRepository.shared` or `PersistenceController`.
   - Delete UserDefaults key.
   - Display toast: "🧠 AI Memory đã được đồng bộ an toàn" (2s).
   - Implement this in `LiiO_EatCleanApp` or `AppViewModel`.

3. **Repository Pattern**:
   - `AIMemoryRepositoryProtocol` and `AIMemoryRepository`.
   - Deprecate `MemoryManager`.
   - Methods needed: fetch, add/remove condition, add/remove preference, set personality.

## AI Personality
- Add enum `AIPersonalityTone` with 5 cases: friendly, expert, disciplined, chill, humorous.
- Need a `AIPersonality` wrapper or just store the raw string in `AIMemory` entity.
- Inject into `ContextBuilder`. Currently `ContextBuilder` strategies get `UserProfileMemory`. Now they need to query `AIMemoryRepository` and `UserRepository`.
- "Instant save + Sample preview bubble": requires a custom toast/bubble view that appears on top of the personality card.

## UI Architecture
1. **Memory Hub View**:
   - A `ScrollView` with grouped cards.
   - Empty state check: if no memory/preferences exist, show `Illustration + CTA` -> `Guided Setup Sheet` (5 steps).
   - Read-only cards with an "Edit" button.
   - Personality Picker card at the bottom.
2. **Meals Tab Badge**:
   - Replace `MemorySummaryCard` with a mini capsule badge `AIMemoryBadgeView`.
3. **Navigation**:
   - `.fullScreenCover(isPresented:)` triggered by Brain icon in ChatView or Badge in MealsView.

## Validation Architecture
- Schema push: None required since using CoreData (xcdatamodeld handles it), but need to add entities to data model.
- Tests needed to ensure migration doesn't lose data.
