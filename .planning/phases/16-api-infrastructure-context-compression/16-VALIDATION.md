# Phase 16: API Infrastructure & Context Compression - Validation Strategy

**Created:** 2026-05-07

## Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest |
| Config file | none — see Wave 0 |
| Quick run command | `xcodebuild test -scheme LiiO_EatClean -destination "platform=iOS Simulator,name=iPhone 15"` |

## Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| APIK-01 | API Key Storage & CoreData Schema | unit | `xcodebuild test ... -only-testing:LiiO_EatCleanTests/APIKeyRepositoryTests` | ❌ |
| APIK-02 | Auto-swap, Priority & Cooldown | unit | `xcodebuild test ... -only-testing:LiiO_EatCleanTests/APIKeyPoolManagerTests` | ❌ |
| APIK-03 | Parallel Requests (TaskGroup) | unit | `xcodebuild test ... -only-testing:LiiO_EatCleanTests/AIServiceParallelTests` | ❌ |
| COMP-01 | Context Budget & Truncation | unit | `xcodebuild test ... -only-testing:LiiO_EatCleanTests/ContextBuilderTests` | ❌ |

## Sampling Rate
- **Per task commit:** Run specific unit test related to the task.
- **Per wave merge:** Run full XCTest suite.
- **Phase gate:** Full suite green before `/gsd-verify-work`

## Wave 0 Gaps
- [ ] Setup `APIKeyPoolRepositoryTests.swift` with in-memory CoreData.
- [ ] Setup `APIKeyPoolManagerTests.swift` to mock network responses for 401/429.
- [ ] Setup `ContextBuilderTests.swift` to assert prompt lengths.
