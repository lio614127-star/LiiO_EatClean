# Plan 02: Data Migration & ContextBuilder Update

## Overview
Successfully implemented the data migration layer moving AI Memory data from `UserDefaults` to the new CoreData `AIMemoryRepository`. Updated the `ContextBuilder` to fetch memory from the new repository and correctly embed the AI Personality instructions into the system prompt.

## Changes Made
- Added `performAIMemoryMigration()` to `LiiO_EatCleanApp.swift` which reads the old `UserDefaults` JSON, maps it properly to the new `UserProfileMemory` (including extracting the old `avoidFoods` from `HealthCondition` and moving them to the global `avoidFoods`), saves it to `AIMemoryRepository`, and removes the `UserDefaults` key.
- Replaced `MemoryManagerProtocol` with `AIMemoryRepositoryProtocol` in `ContextBuilder.swift`.
- Modified `buildMemoryBlock()` to inject `memory.personalityTone.promptInstruction` at the very top of the generated prompt memory block to ensure the LLM strictly follows the requested tone.
- Ensured proper `async/await` handling during app startup for migrations and database seeding.

## Verification
- Code successfully maps the old structure `OldUserProfileMemory` and `OldHealthCondition` seamlessly without decode failures.
- `ContextBuilder` now provides personality context properly integrated before any other user preferences.
