# Phase 24 Plan: AI Goal Setting & Metabolic Intelligence

## Overview
Build the foundational engines and user flows for an adaptive coaching experience.

## Wave 0: Metabolic Foundation & Simulation (The Core)
- [x] Task 0.1: CoreData Migration - Add `MetabolicProfile` and `GoalHistory` (Full Context Snapshot).
- [x] Task 0.2: `MetabolicRepository` - Implement versioned CRUD and history management.
- [x] Task 0.3: `MetabolicSimulationService` - Create a sandbox to test scenarios (water retention, plateaus).
- [x] Task 0.4: `DataReliabilityAnalyzer` - Logic to filter noise from signal in logs.
- [x] Task 0.5: Initial Migration - Create baseline metabolic profiles from existing user data.

## Wave 1: Adaptive Engines & Projection (The Brain)
- [ ] Task 1.1: `AdaptiveTDEEEngine` - Implement EMA-based TDEE learning.
- [ ] Task 1.2: `AdherenceEngine` - Implement weighted adherence scoring.
- [ ] Task 1.3: `PlateauEngine` - Implement noise-aware trend slope detection.
- [ ] Task 1.4: `TargetProjectionLayer` - Build cache for high-performance chart rendering.

## Wave 2: Orchestration & Coaching Flow (The Interaction)
- [x] Task 2.1: `InterventionSeveritySystem` - State machine for goal types (SOFT, RECOVERY, etc.).
- [x] Task 2.2: `GoalOrchestrator` - Deterministic math layer to calculate proposed adjustments.
- [x] Task 2.3: `AICoachCommunicator` - Logic to translate math results into human coaching language.
- [x] Task 2.4: Coaching Cards UI - Home screen integration for AI insights and suggestions.

## Wave 3: Weekly Review & Flex Coaching (The UX)
- [x] Task 3.1: "Weekly Reflection" UX - Full-screen summary and check-in flow.
- [x] Task 3.2: Soft Weekly Budget Coaching - Non-punitive flex calorie management.
- [x] Task 3.3: Goal History View - Allow users to see their progress milestones.

## Verification
- Run simulations for 5 core scenarios (Plateau, Water, Poor Adherence, Binge Weekend, Rapid Loss).
- Verify target line rendering on charts across multiple goal versions.
- Confirm non-exhaustive switch safety and CoreData integrity.
