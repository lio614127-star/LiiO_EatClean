---
wave: 1
depends_on: []
files_modified:
  - LiiO_EatClean.xcdatamodeld/LiiO_EatClean.xcdatamodel/contents
  - LiiO_EatClean/Data/Repositories/AIMemoryRepository.swift
  - LiiO_EatClean/Data/Models/AIPersonalityTone.swift
autonomous: true
requirements: [MEMH-03, PERS-01]
---

# Plan 01: CoreData Schema & AIMemoryRepository

<objective>
Update the CoreData schema (xcdatamodeld) to include the new AI Memory entities and implement the `AIMemoryRepository` protocol to provide data access for the AI context.
</objective>

<action>
1. Modify `LiiO_EatClean.xcdatamodeld` to add the following entities:
   - `AIMemory` (Root): 
     - Attributes: `id` (UUID), `personalityTone` (String, default: "friendly")
     - Relationships (To Many): `healthConditions`, `avoidFoods`, `foodPreferences`, `dietaryNotes`, `insights`
   - `HealthCondition`:
     - Attributes: `id` (UUID), `name` (String), `dietaryNotes` (String)
     - Relationships (To One): `memory` (Inverse of `AIMemory.healthConditions`)
   - `AvoidFood`:
     - Attributes: `id` (UUID), `name` (String)
     - Relationships (To One): `memory`
   - `FoodPreference`:
     - Attributes: `id` (UUID), `name` (String), `type` (String - "like" or "dislike")
     - Relationships (To One): `memory`
   - `DietaryNote`:
     - Attributes: `id` (UUID), `content` (String)
     - Relationships (To One): `memory`
   - `AIInsight`:
     - Attributes: `id` (UUID), `content` (String), `date` (Date)
     - Relationships (To One): `memory`

2. Create `AIPersonalityTone.swift` in `Data/Models`:
   ```swift
   enum AIPersonalityTone: String, Codable, CaseIterable {
       case friendly = "🌿 Thân thiện & Động viên"
       case expert = "👨‍⚕️ Chuyên gia Nghiêm túc"
       case disciplined = "🔥 Kỷ luật cao"
       case chill = "🌈 Chill & Thoải mái"
       case humorous = "😄 Vui vẻ & Hài hước"
       
       var promptInstruction: String {
           switch self {
           case .friendly: return "Sử dụng giọng điệu nhẹ nhàng, tích cực, khích lệ và không tạo áp lực."
           case .expert: return "Sử dụng giọng điệu logic, chuyên môn chuẩn dinh dưỡng, ít dùng emoji."
           case .disciplined: return "Sử dụng giọng điệu thúc đẩy mạnh mẽ, tập trung vào mục tiêu và kỷ luật cao."
           case .chill: return "Sử dụng giọng điệu thoải mái, ít áp lực, cân bằng cuộc sống và anti-guilt."
           case .humorous: return "Sử dụng giọng điệu dí dỏm, hài hước nhẹ nhàng, nhiều cảm xúc."
           }
       }
   }
   ```

3. Create `AIMemoryRepository.swift` in `Data/Repositories` with protocol `AIMemoryRepositoryProtocol`:
   - Methods to fetch the single `AIMemory` instance (create if not exists).
   - Methods to add/remove conditions, preferences, avoid foods, notes.
   - Method to update `personalityTone`.
   - Ensure it uses `@Observable` or publishes changes so UI can react.
</action>

<read_first>
- LiiO_EatClean/Data/Repositories/MealRepository.swift (for repository patterns)
- LiiO_EatClean.xcdatamodeld/LiiO_EatClean.xcdatamodel/contents (XML format for adding entities safely)
</read_first>

<acceptance_criteria>
- `LiiO_EatClean.xcdatamodeld` contains definitions for `AIMemory`, `HealthCondition`, `AvoidFood`, `FoodPreference`, `DietaryNote`, and `AIInsight` entities with correct relationships.
- `AIMemoryRepository.swift` is created and implements fetching and updating the new CoreData entities.
- `AIPersonalityTone` enum is defined with 5 specific cases and system prompt instructions.
</acceptance_criteria>
