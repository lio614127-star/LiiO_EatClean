---
phase: 1
slug: project-foundation
status: pending
created: 2026-04-29
---

# Phase 1 — Validation Strategy

> This document defines how the implementation of Phase 1 will be validated against requirements and design contracts.

---

## 1. Goal-Backward Verification
> Proving the phase's core objective was met.

**Phase Goal:** Xcode project chạy được với CoreData schema + Repository pattern + tab navigation skeleton

**Must-Haves:**
- App compiles and runs without crashing
- 4 primary tabs visible and navigable
- CoreData stack initializes successfully
- Repositories can fetch and save data

---

## 2. Requirement Traceability
> Ensuring every REQUIREMENT-ID from REQUIREMENTS.md is covered.

| ID | Requirement | Verification Method |
|---|---|---|
| FOUND-01 | Xcode project with SwiftUI, iOS 17+, CoreData | Verify `LiiO_EatClean.xcodeproj` exists and targets iOS 17.0+ |
| FOUND-02 | CoreData schema (7 entities) | Verify `LiiO_EatClean.xcdatamodeld` contains exactly 7 entities with correct properties |
| FOUND-03 | Repository pattern | Verify `MealRepository`, `FoodRepository`, `UserRepository` protocols and implementations exist |
| FOUND-04 | App navigation structure | Verify `ContentView.swift` or `App.swift` contains a `TabView` with 4 distinct tabs |

---

## 3. UI-SPEC Alignment
> Checking implementation against the visual and interaction contract.

| Dimension | Spec Value | Verification |
|---|---|---|
| Colors | Primary: #4CAF50, Backgrounds: System | Verify `Assets.xcassets` contains `Primary` color |
| Typography | SF Pro | Native iOS default, no custom font loaded |
| Icons | house.fill, fork.knife, etc. | Verify `TabView` items use the exact SF Symbols specified |

---

## 4. Anti-Pattern Prevention
> Actively checking that known project pitfalls were avoided.

| Pitfall | Prevention Check |
|---|---|
| CoreData Threading | Verify Repository methods use `context.perform` and return structs (not NSManagedObjects) |
| Hardcoded Magic Strings | Verify entity names and relationship keys use static constants or enum wrappers (or are handled safely) |
| Int for Nutrition | Verify all schema properties for macros/calories use `Double` |
