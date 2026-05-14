---
status: resolved
trigger: "Argument 'memoryRepository' must precede argument 'mealRepository'"
created: 2026-05-14T16:20:00Z
updated: 2026-05-14T16:21:00Z
---

# Debug Session: `initializer-argument-order-fix`

## Symptoms
- **Compile Error:** `Argument 'memoryRepository' must precede argument 'mealRepository'`
- **File:** `LiiO_EatClean/Features/AI/ContextBuilder.swift` (Line 29)
- **Context:** Instantiation of `AICoachContextBuilder` reported sequencing mismatch.

## Diagnosis
- In Swift, named initializer arguments passed during initialization must precisely match the order of parameter declarations in the signature.
- In the previous hotfix `47dc8b8` to restore default initializers, the order of the second and third parameters in `AICoachContextBuilder.swift` was swapped (`memoryRepository` declared before `mealRepository`).
- Meanwhile, existing callers inside `ContextBuilder.swift` call it with `mealRepository` preceding `memoryRepository`.

## Resolution
- **Fix Applied:** Corrected the order in `AICoachContextBuilder.swift` by declaring `mealRepository` second and `memoryRepository` third in the initializer declaration, resolving the sequencing error at all call sites.
- **Commit:** `7b78565`

## Verification
- The compiler strictly enforces parameter declaration matching, and matching the call sequence perfectly allows synthesized initializer propagation. Conformance is verified.
