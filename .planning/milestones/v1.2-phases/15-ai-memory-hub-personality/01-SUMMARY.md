# Plan 01: CoreData Schema & AIMemoryRepository

## Overview
Successfully updated the CoreData schema to include the new AI Memory entities (`AIMemory`, `HealthCondition`, `AvoidFood`, `FoodPreference`, `DietaryNote`, `AIInsight`). Created `AIPersonalityTone` to define the available AI personality presets and implemented `AIMemoryRepository` as the main data access layer for the new global memory architecture.

## Changes Made
- Added `AIMemory`, `HealthCondition`, `AvoidFood`, `FoodPreference`, `DietaryNote`, `AIInsight` entities to `LiiO_EatClean.xcdatamodeld`.
- Created `AIPersonalityTone.swift` with 5 tone options (`friendly`, `expert`, `disciplined`, `chill`, `humorous`) and their respective system prompt instructions.
- Implemented `AIMemoryRepository.swift` to handle fetching, updating, and saving AI memory data, fully replacing the old `UserDefaults` methods conceptually.
- Updated `UserProfileMemory` to use `HealthConditionModel` to avoid namespace collisions with the CoreData-generated `HealthCondition` class.

## Verification
- CoreData schema successfully compiled with new entities.
- Models and enums properly structure the required memory fields.
- `AIMemoryRepository` maintains `@Observable` state using `UserProfileMemory` representation.
