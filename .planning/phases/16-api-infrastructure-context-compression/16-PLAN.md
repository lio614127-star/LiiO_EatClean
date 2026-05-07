---
wave: 1
depends_on: []
files_modified:
  - "LiiO_EatClean/Data/Models/APIKeyModel.swift"
  - "LiiO_EatClean/Data/Repositories/UserRepository.swift"
  - "LiiO_EatClean/LiiO_EatClean.xcdatamodeld"
autonomous: true
---

# Wave 1: CoreData Schema Migration & Data Layer

This wave updates the CoreData schema to support the expanded `APIKey` entity required for the Key Pool Manager, ensuring persistence of health scores, priorities, and cooldown timestamps.

## Tasks

```xml
<task id="schema-migration" type="execute">
  <read_first>
    - LiiO_EatClean/Data/Models/APIKeyModel.swift
    - LiiO_EatClean/Data/Repositories/UserRepository.swift
  </read_first>
  <action>
    Update the CoreData model `LiiO_EatClean.xcdatamodeld`:
    1. Create a new model version (`Model v2` or whatever is next).
    2. Add new attributes to the `APIKey` entity:
       - `healthScore` (Integer 16, default: 100)
       - `priority` (Integer 16, default: 0)
       - `cooldownUntil` (Date, optional)
    3. Ensure the current model version is set to the new one.
    
    Update `APIKeyModel.swift`:
    1. Add properties: `var healthScore: Int`, `var priority: Int`, `var cooldownUntil: Date?`
    2. Update the `init` to accept these new properties with default values.
  </action>
  <acceptance_criteria>
    - `LiiO_EatClean.xcdatamodeld` contains the new version with `healthScore`, `priority`, and `cooldownUntil` attributes on `APIKey`.
    - `APIKeyModel` struct contains the 3 new properties.
  </acceptance_criteria>
</task>

<task id="repository-updates" type="execute">
  <read_first>
    - LiiO_EatClean/Data/Repositories/UserRepository.swift
  </read_first>
  <action>
    Update `UserRepository.swift`:
    1. In `fetchAPIKeys()`, ensure the results are mapped to `APIKeyModel` including `healthScore`, `priority`, and `cooldownUntil`. Order by `priority` descending instead of `provider` ascending.
    2. In `saveAPIKey(_:)`, update the `coreDataKey` mapping to include `healthScore`, `priority`, and `cooldownUntil`.
  </action>
  <acceptance_criteria>
    - `UserRepository.fetchAPIKeys` maps the 3 new properties and sorts by `priority` descending.
    - `UserRepository.saveAPIKey` persists the 3 new properties to CoreData.
  </acceptance_criteria>
</task>
```

---
wave: 2
depends_on: [1]
files_modified:
  - "LiiO_EatClean/Features/AI/APIKeyPoolManager.swift"
autonomous: true
---

# Wave 2: APIKey Pool Manager Service

This wave introduces the `actor`-based `APIKeyPoolManager` to safely handle key selection, auto-swap priority logic, and cooldown tracking across concurrent AI requests.

## Tasks

```xml
<task id="pool-manager-actor" type="execute">
  <read_first>
    - LiiO_EatClean/Data/Models/APIKeyModel.swift
  </read_first>
  <action>
    Create a new file `LiiO_EatClean/Features/AI/APIKeyPoolManager.swift`:
    1. Define `actor APIKeyPoolManager`.
    2. It should have a dependency on `UserRepositoryProtocol` to load/save keys.
    3. Maintain an internal state `private var keys: [APIKeyModel] = []`.
    4. Method `func loadKeys() async throws` to fetch keys from the repository.
    5. Method `func getBestKey() -> APIKeyModel?`:
       - Filter out inactive keys (`isActive == false`).
       - Filter out keys currently on cooldown (`cooldownUntil > Date()`).
       - Return the first key (they are already sorted by priority from Wave 1).
    6. Method `func reportError(keyID: UUID, statusCode: Int) async throws`:
       - Find the key in the array.
       - If `statusCode == 401` or `403` (Invalid): set `isActive = false`, set `healthScore = 0`.
       - If `statusCode == 429` (Quota): set `cooldownUntil = Date().addingTimeInterval(60)` (60s cooldown).
       - If `statusCode == -1001` (Timeout): set `cooldownUntil = Date().addingTimeInterval(30)`.
       - Decrease `healthScore` by 5 on any error (min 0).
       - Save the updated key to the repository via `UserRepositoryProtocol`.
    7. Method `func reportSuccess(keyID: UUID) async throws`:
       - Increase `healthScore` by 1 (max 100).
       - Set `cooldownUntil = nil`.
       - Update `lastUsed = Date()`.
       - Save to repository.
  </action>
  <acceptance_criteria>
    - `APIKeyPoolManager.swift` defines an `actor`.
    - `getBestKey()` correctly skips cooling down or inactive keys.
    - `reportError()` applies the correct cooldown intervals (60s for 429, permanent disable for 401).
  </acceptance_criteria>
</task>
```

---
wave: 3
depends_on: [2]
files_modified:
  - "LiiO_EatClean/Features/AI/ContextBuilder.swift"
autonomous: true
---

# Wave 3: Context Compression Engine

This wave refactors the `ContextBuilder` to implement the Token Budget System and Sliding Window for chat history, ensuring the Core Memory (Persistent AI Identity) is never compressed.

## Tasks

```xml
<task id="token-budget-system" type="execute">
  <read_first>
    - LiiO_EatClean/Features/AI/ContextBuilder.swift
  </read_first>
  <action>
    Update `ContextBuilder.swift`:
    1. Add a token estimation utility `private func estimateTokens(for text: String) -> Int` (heuristic: `text.count / 4`).
    2. Set a strict budget: `let maxTokens = 6000` (leaving room for response).
    3. Modify `buildMemoryBlock(memory:)` to bypass token compression (Core Memory = NEVER COMPRESS). It must always be included in full.
    4. Implement Sliding Window for Chat History:
       - Keep the last 10 messages intact.
       - For older messages, we will need to inject a summarized block. 
       - If total tokens > `maxTokens`, truncate the oldest non-summarized messages.
    5. Expose a method `func summarizeHistory(messages: [ChatMessage]) -> String` to generate a lightweight text representation of older chats (this will later be fed to the AI for actual summarization, but for now, generate the prompt block to request summarization).
  </action>
  <acceptance_criteria>
    - `ContextBuilder.swift` contains token estimation logic.
    - Core Memory (medical conditions, preferences) is never truncated regardless of token count.
    - Chat history enforces a sliding window (e.g., last 10 messages).
  </acceptance_criteria>
</task>
```

---
wave: 4
depends_on: [2, 3]
files_modified:
  - "LiiO_EatClean/Features/AI/AIService.swift"
autonomous: true
---

# Wave 4: Parallel Workload Distribution & Auto-Swap

This wave wires the `APIKeyPoolManager` into `AIService`, replacing the hardcoded sequential fallback. It also introduces `TaskGroup` to execute requests concurrently using multiple keys.

## Tasks

```xml
<task id="aiservice-auto-swap" type="execute">
  <read_first>
    - LiiO_EatClean/Features/AI/AIService.swift
    - LiiO_EatClean/Features/AI/APIKeyPoolManager.swift
  </read_first>
  <action>
    Refactor `AIService.swift`:
    1. Inject `APIKeyPoolManager`. Remove the direct fetch of single keys from `UserRepository`.
    2. Update `performRequest()` to use `poolManager.getBestKey()`.
    3. Wrap network calls in a retry loop (e.g., max 3 retries):
       - If HTTP response is 401/403/429/timeout, call `poolManager.reportError(keyID:statusCode:)`.
       - Continue to the next iteration to get a new key from `getBestKey()`.
       - If success, call `poolManager.reportSuccess(keyID:)` and return data.
    4. Throw `NoActiveAPIKeyError` if `getBestKey()` returns nil.
  </action>
  <acceptance_criteria>
    - `AIService` no longer uses `key.provider == "gemini"` hardcoding.
    - Errors trigger `reportError` and automatically loop to try the next key.
    - Success triggers `reportSuccess`.
  </acceptance_criteria>
</task>

<task id="aiservice-distributed-parallel" type="execute">
  <read_first>
    - LiiO_EatClean/Features/AI/AIService.swift
  </read_first>
  <action>
    Add a new method `generateDistributedMealPlan(days: Int, dailyCalories: Double) async throws -> [MealPlanDay]` in `AIService`:
    1. Divide the days into chunks (e.g., 2 days per chunk).
    2. Use `withThrowingTaskGroup(of: [MealPlanDay].self)` to fetch chunks concurrently.
    3. Inside the task group, call the standard `suggestMeals()` or the equivalent AI prompt for that specific chunk.
    4. The internal `performRequest()` will naturally use `getBestKey()` for each concurrent task, effectively distributing the workload across available keys without duplicating requests.
    5. Merge the results from the task group and return the full `[MealPlanDay]`.
  </action>
  <acceptance_criteria>
    - `generateDistributedMealPlan` uses `withThrowingTaskGroup`.
    - It chunks the workload and merges the results without duplicating the same prompt.
  </acceptance_criteria>
</task>
```

---
wave: 5
depends_on: [1]
files_modified:
  - "LiiO_EatClean/Features/Profile/ProfileViewModel.swift"
  - "LiiO_EatClean/Features/Profile/ProfileView.swift"
  - "LiiO_EatClean/Features/Profile/APIKeyManagerView.swift"
autonomous: false
---

# Wave 5: API Key Manager UI

This wave creates the full-screen API Key Manager, allowing users to add, reorder (priority), and monitor the health of their keys.

## Tasks

```xml
<task id="api-key-manager-ui" type="execute">
  <read_first>
    - LiiO_EatClean/Features/Profile/ProfileView.swift
  </read_first>
  <action>
    Create `APIKeyManagerView.swift` and update `ProfileView`:
    1. In `ProfileView`, replace the inline API Key text fields with a single button "API Key Manager" that opens `APIKeyManagerView` via `.fullScreenCover`.
    2. `APIKeyManagerView` should display a `List` or `ScrollView` of `APIKeyModel` objects.
    3. For each key, show a `KeyCardView` containing:
       - Provider Logo/Name (Gemini/OpenAI)
       - Masked Key (`••••sk-abc`)
       - Status badge (🟢 Active, 🟡 Cooldown, 🔴 Invalid)
       - Health score bar (0-100)
    4. Implement `.onMove` on the list to allow users to drag-to-reorder keys. Update the `priority` attribute based on the new index (e.g., index 0 = highest priority) and save to `UserRepository`.
    5. Add a "+" button to append a new key via an alert or sheet.
    6. Implement swipe-to-delete.
  </action>
  <acceptance_criteria>
    - `ProfileView` no longer has inline API key fields; uses a button to launch manager.
    - `APIKeyManagerView` supports drag-to-reorder, updating the `priority` field.
    - Key cards display health score and dynamic status based on `cooldownUntil` and `isActive`.
  </acceptance_criteria>
</task>
```
