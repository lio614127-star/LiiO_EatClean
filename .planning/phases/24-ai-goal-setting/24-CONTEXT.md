# Phase 24 Context: AI Personalized Goal Setting & Metabolic Intelligence

## Goal
Transition LiiO from a static calorie tracker to an adaptive "Metabolic Operating System" that proactively coaches users based on biological feedback and adherence.

## Decisions

### 1. Interaction Model (Autonomy)
- **Level:** Collaborative-first.
- **Mechanism:** AI observes data -> Detects trends -> Proposes adjustment -> Explains "Why" -> User approves/applies.
- **Safety:** No automatic profile modification without user consent.

### 2. Evaluation Strategy (Rolling Window)
- **Cycle:** Rolling 7-day evaluation (not fixed weekly).
- **Trigger:** Data Density (Confidence Score).
- **Confidence Score (0-100):**
    - HIGH: >= 6 food logs + >= 4 weight logs (7d).
    - MEDIUM: >= 4 food logs + >= 2 weight logs (7d).
    - LOW: Skip intervention.

### 3. Analytics Engines (The Core)
- **Adaptive TDEE Engine:** Calculates "Real TDEE" using `Intake + Weight Trend + Rate of Change`. Use EMA smoothing (max ±40 kcal/day adjustment).
- **Plateau Engine:** Uses rolling average trends and slope analysis to detect biological stalls, filtering out daily water/sodium noise.
- **Adherence Engine:** Weighted score (Calories 40%, Protein 30%, Consistency 30%).
- **Data Reliability Layer:** Filters "noisy" data (outliers, inconsistent weighing times) from "signal" data.

### 4. Intervention Logic
- **Severity Levels:** SOFT, MEDIUM, HARD, RECOVERY, DIET_BREAK, MAINTENANCE.
- **Cooldown:** Intervention lock of 7-21 days depending on change magnitude and adherence.
- **Safety Rails:** Enforce calorie floors (1200/1500) and max weekly loss percentages.

### 5. Data Infrastructure (GoalHistory)
- **Model:** Immutable Snapshot Timeline. No row overwriting.
- **Payload:** Full metabolic context (weight averages, TDEE estimates, adherence, reason, confidence).
- **Versioning:** `calculationVersion` tracking for algorithm debugging.

### 6. AI Role
- **Role:** Communication & EQ Layer.
- **Constraint:** AI does NOT perform math. Math is deterministic and hardcoded. AI explains the math results in a supportive, human-friendly tone.

## Reusable Assets
- `CalorieCalculator`: Existing MSJ formula as baseline.
- `UserRepository`: To be expanded with MetabolicProfile.
- `ProgressChart`: To be updated with Target Projection Layer.
