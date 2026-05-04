# Plan 10D: Learning System + Memory Management

**Wave:** 3 (depends on Plan 10A memory system + Plan 10B/10C for integration)
**Requirements:** AIMEAL-05, AIMEAL-06, AIMEAL-07
**Depends on:** Plan 10A, Plan 10B

## Objective

Xây dựng Learning System hybrid: client-side keyword scan (Level 1) + AI extraction (Level 2) để tự trích xuất sở thích/bệnh lý từ chat. Luôn xác nhận với user trước khi lưu. Tích hợp Memory Management UI vào Meals tab.

## Task 1: Create LearningService (Hybrid Extraction)

<read_first>
- LiiO_EatClean/Services/MemoryManager.swift (after Plan 10A upgrade)
- LiiO_EatClean/Data/Models/UserProfileMemory.swift (new structure)
- LiiO_EatClean/Features/AI/AIService.swift
- .planning/phases/10-ai-meals-tab/10-CONTEXT.md (decisions D-11 to D-15)
</read_first>

<action>
Create `LiiO_EatClean/Services/LearningService.swift`:

```swift
class LearningService {
    static let shared = LearningService()
    
    private let memoryManager: MemoryManagerProtocol
    private let aiService = AIService.shared
    
    // MARK: - Level 1: Client-side keyword scan
    
    struct ExtractionResult {
        let updates: [MemoryUpdate]
        let confidence: ExtractionConfidence
    }
    
    enum ExtractionConfidence {
        case high    // Level 1: keyword match, no AI needed
        case needsAI // Level 2: complex sentence, needs AI extraction
        case none    // No actionable info detected
    }
    
    func analyzeMessage(_ message: String) -> ExtractionConfidence {
        let lower = message.lowercased()
        
        // Level 1 patterns (high confidence, local only)
        let likePatterns = ["thích ăn", "thích món", "tôi thích", "mình thích"]
        let dislikePatterns = ["ghét", "không thích", "không ăn được", "dị ứng"]
        let conditionPatterns = ["bị bệnh", "mắc bệnh", "bị gan", "bị tiểu đường", 
                                  "huyết áp", "cholesterol"]
        
        if likePatterns.contains(where: { lower.contains($0) }) ||
           dislikePatterns.contains(where: { lower.contains($0) }) {
            return .high
        }
        
        if conditionPatterns.contains(where: { lower.contains($0) }) {
            return .needsAI  // Complex → needs AI for proper extraction
        }
        
        return .none
    }
    
    // Level 1: Extract from simple patterns
    func extractLocal(_ message: String) -> [MemoryUpdate] { ... }
    
    // Level 2: Send to AI for extraction
    func extractWithAI(_ message: String) async throws -> [MemoryUpdate] {
        // Build a minimal extraction prompt:
        // "Trích xuất thông tin sức khỏe từ câu sau. Trả về JSON..."
        // Parse response into [MemoryUpdate]
    }
    
    // Combined: analyze → extract → return updates for confirmation
    func processMessage(_ message: String) async -> [MemoryUpdate] {
        let confidence = analyzeMessage(message)
        switch confidence {
        case .high: return extractLocal(message)
        case .needsAI: return (try? await extractWithAI(message)) ?? []
        case .none: return []
        }
    }
}
```

**CRITICAL RULES:**
- Only extract LONG-TERM info. "Hôm nay tôi ăn phở" is NOT a preference.
- "Tôi thích phở" IS a preference (repeating/permanent).
- Structured output only — never store raw text.
</action>

<acceptance_criteria>
- File `Services/LearningService.swift` exists
- Contains `enum ExtractionConfidence` with `.high`, `.needsAI`, `.none`
- Contains `func analyzeMessage(_ message: String) -> ExtractionConfidence`
- Contains `func extractLocal(_ message: String) -> [MemoryUpdate]`
- Contains `func extractWithAI(_ message: String) async throws -> [MemoryUpdate]`
- Contains `func processMessage(_ message: String) async -> [MemoryUpdate]`
- Level 1 patterns include like/dislike/condition Vietnamese keywords
</acceptance_criteria>

## Task 2: Create MemoryUpdateConfirmationView

<read_first>
- LiiO_EatClean/Data/Models/UserProfileMemory.swift
</read_first>

<action>
Create `LiiO_EatClean/Features/Meals/Components/MemoryUpdateConfirmationView.swift`:

A popup/sheet for confirming extracted memory updates before saving.

```swift
struct MemoryUpdateConfirmationView: View {
    let updates: [MemoryUpdate]
    let onConfirm: ([MemoryUpdate]) -> Void
    let onDismiss: () -> Void
    
    // Each update shown as a toggleable row:
    // ☑ "Thích: Phở bò"
    // ☑ "Bệnh lý: Gan nhiễm mỡ → Tránh: Đồ chiên, Rượu bia"
    // ☐ "Không thích: Rau mùi"
    //
    // [Lưu] [Bỏ qua]
}
```

UI style:
- Card-style bottom sheet (`.presentationDetents([.medium])`)
- Header: "💡 Phát hiện thông tin mới"
- Each update as a selectable row with checkbox
- Green "Lưu" button + gray "Bỏ qua" button
- Clean, non-intrusive design
</action>

<acceptance_criteria>
- File `Features/Meals/Components/MemoryUpdateConfirmationView.swift` exists
- Shows each MemoryUpdate as a toggleable row
- Has "Lưu" and "Bỏ qua" buttons
- Uses `.presentationDetents([.medium])` for sheet sizing
- onConfirm callback passes selected updates
</acceptance_criteria>

## Task 3: Integrate Learning System into ChatViewModel

<read_first>
- LiiO_EatClean/Features/Chat/ChatViewModel.swift
- LiiO_EatClean/Services/MemoryManager.swift
</read_first>

<action>
Update `ChatViewModel` to use `LearningService` after each user message:

```swift
// In sendMessage(), after user message is sent:
func sendMessage(_ text: String) {
    // ... existing code ...
    
    // Learning System: analyze user message for memory updates
    Task {
        let updates = await LearningService.shared.processMessage(trimmed)
        if !updates.isEmpty {
            await MainActor.run {
                self.pendingMemoryUpdates = updates
                self.showMemoryConfirmation = true
            }
        }
    }
}

// New properties:
var pendingMemoryUpdates: [MemoryUpdate] = []
var showMemoryConfirmation = false

func confirmMemoryUpdates(_ updates: [MemoryUpdate]) {
    for update in updates {
        MemoryManager.shared.applyMemoryUpdate(update)
    }
    pendingMemoryUpdates = []
    showMemoryConfirmation = false
}
```

In `ChatView.swift`, add sheet for `MemoryUpdateConfirmationView` triggered by `showMemoryConfirmation`.
</action>

<acceptance_criteria>
- ChatViewModel.swift contains `var pendingMemoryUpdates: [MemoryUpdate]`
- ChatViewModel.swift contains `var showMemoryConfirmation = false`
- ChatViewModel.swift contains `func confirmMemoryUpdates(_ updates: [MemoryUpdate])`
- ChatView.swift has `.sheet` for `MemoryUpdateConfirmationView`
- After user sends message with preference keywords → confirmation popup appears
- Confirmed updates are saved via MemoryManager
</acceptance_criteria>

## Task 4: Add Memory Summary to Meals Tab

<read_first>
- LiiO_EatClean/Features/Meals/MealsView.swift (after Plan 10B)
</read_first>

<action>
Add a compact "Memory Summary" card at the top of the AI Suggestion Section, showing what the AI knows about the user:

```swift
// Compact memory indicator (only shows if memory has content)
if !memory.healthConditions.isEmpty || !memory.likes.isEmpty || !memory.dislikes.isEmpty {
    VStack(alignment: .leading, spacing: 4) {
        HStack {
            Image(systemName: "brain.head.profile")
                .foregroundColor(.green)
            Text("AI nhớ về bạn")
                .font(.caption.bold())
            Spacer()
            NavigationLink("Chỉnh sửa") {
                MemoryEditorView()
            }
            .font(.caption)
        }
        
        // Compact tags: conditions + key preferences
        FlowLayout {
            ForEach(memory.healthConditions) { condition in
                Tag(condition.name, color: .red.opacity(0.1))
            }
            ForEach(memory.likes.prefix(3), id: \.self) { like in
                Tag("❤️ " + like, color: .green.opacity(0.1))
            }
            ForEach(memory.dislikes.prefix(3), id: \.self) { dislike in
                Tag("✗ " + dislike, color: .gray.opacity(0.1))
            }
        }
    }
    .padding(12)
    .background(Color(.tertiarySystemBackground))
    .cornerRadius(12)
}
```

Create a simple `MemoryEditorView` that allows viewing and deleting memory entries (health conditions, likes, dislikes, notes). Navigation push from the "Chỉnh sửa" link.
</action>

<acceptance_criteria>
- Memory summary card appears in Meals tab when memory has content
- Shows health condition tags (red tint), likes (green tint), dislikes (gray tint)
- "Chỉnh sửa" link navigates to MemoryEditorView
- MemoryEditorView allows viewing and deleting memory entries
- Memory card hidden when memory is empty
</acceptance_criteria>

## Verification

### Manual Verification
1. Build project — no compile errors.
2. In Chat tab, type "Tôi thích ăn phở" → confirmation popup appears with "Thích: Phở".
3. Tap "Lưu" → memory saved. Open Meals tab → memory summary shows "❤️ Phở".
4. In Chat tab, type "Tôi bị gan nhiễm mỡ nên không ăn đồ chiên" → AI extraction runs → popup shows condition + avoid foods.
5. Confirm → Meals tab shows health condition tag.
6. In Chat tab, type "Hôm nay tôi ăn cơm gà" → NO extraction popup (not long-term info).
7. Tap "Chỉnh sửa" in memory summary → MemoryEditorView opens → can delete entries.
8. After adding health condition, AI suggestions in Meals tab avoid the restricted foods.
