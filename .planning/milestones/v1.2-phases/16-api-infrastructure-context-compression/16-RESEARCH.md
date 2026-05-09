# Phase 16: API Infrastructure & Context Compression - Research

**Researched:** 2026-05-07
**Domain:** Network API Infrastructure, Swift Concurrency, CoreData Schema Migration
**Confidence:** HIGH

## Summary

This research phase focuses on the technical implementation of a multi-key AI provider infrastructure and a context compression engine. The implementation heavily relies on Swift Concurrency (`TaskGroup` for parallel requests, `actor` for safe key rotation state) and CoreData for persistent AI identity and key storage. 

**Primary recommendation:** Use an `actor`-based `APIKeyPoolManager` to handle concurrency-safe key health, cooldowns, and rotation, and use Swift's `TaskGroup` to distribute workloads (like weekly meal plans) across multiple providers without duplicating requests. Update the CoreData `APIKey` entity to support the new metadata (health, priority, cooldown).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| API Key Storage | CoreData Repository | — | `UserRepository` (or new `APIKeyPoolRepository`) handles CRUD for keys. |
| Key Pool Management | Service Layer (Actor) | — | Needs to be concurrency-safe. An `actor` prevents race conditions when swapping keys globally. |
| Request Distribution | Service Layer (`AIService`) | — | Uses `TaskGroup` to spawn concurrent network requests for meal plans. |
| Context Window Mgt | Service Layer (`ContextBuilder`) | Repository | Reads full CoreData context, applies token budget, summarizes older chunks. |
| Memory Storage | CoreData Repository | — | `AIMemoryRepository` maintains the Persistent AI Identity (never compressed). |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Swift Concurrency | iOS 17+ | Parallel network requests, actor state | Built-in, safe state management. |
| CoreData | iOS 17+ | Persistent memory & key metadata | Existing project data layer. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| CoreData `APIKey` | Keychain | Keychain is more secure but harder to model relational data like health scores, priority, and cooldowns. Since these are free keys, CoreData is acceptable and easier to manage with SwiftUI. |
| `TaskGroup` | `Combine` Zip | `Combine` is being phased out in favor of `async/await` and `TaskGroup`. |

## Architecture Patterns

### Pattern 1: Actor-based Key Pool Manager
**What:** An `actor` that holds the state of the API keys (health, cooldown) and vends the best available key for a request.
**When to use:** When multiple concurrent AI requests might encounter a 429 error and need to globally swap the key or put it on cooldown.
**Example:**
```swift
actor APIKeyPoolManager {
    private var keys: [APIKeyModel] = []
    
    func getBestKey() -> APIKeyModel? {
        return keys.filter { $0.isActive && ($0.cooldownUntil == nil || $0.cooldownUntil! < Date()) }
                   .sorted { $0.priority > $1.priority }
                   .first
    }
    
    func reportError(keyID: UUID, statusCode: Int) {
        // update cooldown, reduce health, or disable if 401
    }
}
```

### Pattern 2: Distributed Parallel Generation
**What:** Using `withThrowingTaskGroup` to fan out requests to multiple keys, each handling a different chunk of data.
**When to use:** For large requests like generating a 7-day meal plan.

### Anti-Patterns to Avoid
- **Always-Parallel Duplicate Requests:** Sending the exact same prompt to 3 different keys to see who answers first. Wastes free tier quotas rapidly.
- **Compressing Core Memory:** Allowing the token budget to truncate medical conditions or diet goals. Core memory must be locked and prioritized.

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | `APIKey` entity in `LiiO_EatClean.xcdatamodeld` | Needs schema update: add `healthScore` (Int16), `priority` (Int16), `cooldownUntil` (Date). |
| Live service config | None | |
| OS-registered state | None | |
| Secrets/env vars | None | |
| Build artifacts | None | |

## Common Pitfalls

### Pitfall 1: CoreData Schema Migration Crash
**What goes wrong:** App crashes on launch after adding new attributes to `APIKey`.
**Why it happens:** Lightweight migration fails or the model version wasn't bumped.
**How to avoid:** Create a new CoreData model version before modifying the `APIKey` entity. Set default values for new attributes (`healthScore = 100`, `priority = 0`).

### Pitfall 2: Infinite Fallback Loops
**What goes wrong:** A recursive retry loop that burns through all keys instantly when the network is down.
**Why it happens:** No backoff or the error handling doesn't distinguish between a 429 (quota) and a general network error (e.g., airplane mode).
**How to avoid:** Only swap keys on 401, 403, and 429. For URLSession network errors (-1009 offline), fail gracefully.

## Code Examples

### Distributed Meal Plan Fetching
```swift
func generateWeeklyMealPlan(keys: [APIKeyModel]) async throws -> [MealPlanDay] {
    return try await withThrowingTaskGroup(of: [MealPlanDay].self) { group in
        for (index, chunk) in days.chunked(into: 2).enumerated() {
            let key = keys[index % keys.count]
            group.addTask {
                return try await fetchChunk(chunk, using: key)
            }
        }
        
        var allDays: [MealPlanDay] = []
        for try await chunkResult in group {
            allDays.append(contentsOf: chunkResult)
        }
        return allDays
    }
}
```

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest |
| Config file | none — see Wave 0 |
| Quick run command | `xcodebuild test -scheme LiiO_EatClean -destination "platform=iOS Simulator,name=iPhone 15"` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| APIK-01 | API Key Storage | unit | `xcodebuild test ... -only-testing:LiiO_EatCleanTests/APIKeyRepositoryTests` | ❌ |
| APIK-02 | Auto-swap & Cooldown | unit | `xcodebuild test ... -only-testing:LiiO_EatCleanTests/APIKeyPoolManagerTests` | ❌ |
| APIK-03 | Parallel Requests | unit | `xcodebuild test ... -only-testing:LiiO_EatCleanTests/AIServiceParallelTests` | ❌ |
| COMP-01 | Context Budget | unit | `xcodebuild test ... -only-testing:LiiO_EatCleanTests/ContextBuilderTests` | ❌ |

### Wave 0 Gaps
- [ ] CoreData test environment setup for `APIKeyPoolRepositoryTests`.

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | Native Swift error handling |
| V6 Cryptography | no | — |

### Known Threat Patterns for iOS
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Plaintext Key Exposure | Info Disclosure | In a production setting, keys should be in Keychain. However, since the user is providing their own API keys to query OpenAI/Gemini directly from the client, CoreData is acceptable, but the keys must be obfuscated in the UI (`••••sk-abc`). |

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - `TaskGroup` and `actor` are Apple's recommended concurrency patterns.
- Architecture: HIGH - Fits perfectly into the existing MVVM + Repository pattern.
- Pitfalls: HIGH - Schema migration and infinite loops are standard concerns.

**Research date:** 2026-05-07
