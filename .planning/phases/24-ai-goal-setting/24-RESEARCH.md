# Phase 24 Research: Adaptive Metabolic Engines

## Core Components

### 1. Adaptive TDEE Engine
- **Formula:** `Estimated TDEE = Avg Calories In + (Weight Change * 7700 / Days)`.
- **Refinement:** Use EMA (Exponential Moving Average) to smooth out fluctuations.
- **Data Source:** `DailyLogModel`, `WeightEntryModel`.

### 2. Adherence Analytics
- **Calorie Adherence:** `abs(Actual - Target) / Target`.
- **Consistency:** Standard deviation of logging times and completion.
- **Macro Balance:** Alignment with protein targets (key for metabolic health).

### 3. Plateau Detection
- **Signal:** Weight trend slope ≈ 0 over 14 days.
- **Filter:** Data Reliability Layer must confirm weight logs were taken at consistent times (e.g., morning).

### 4. CoreData Strategy
- **New Entities:** `MetabolicProfile`, `GoalHistory`, `DailyTargetProjection`.
- **Relationships:** `User` -> `MetabolicProfile` -> `GoalHistory` (1-to-many).

## External Benchmarks
- **MacroFactor:** Adherence-neutral, purely metabolic.
- **Carbon Diet Coach:** Check-in based, deterministic adjustments.
- **RP Diet:** Goal-phase specific coaching.

## Technical Risks
- **Data Scarcity:** AI over-reacting to 2 days of logs. (Mitigation: Confidence Score threshold).
- **Chart Lag:** Drawing target lines through 100+ goal versions. (Mitigation: Projection Cache).
- **CoreData Migration:** Adding versioned entities to an existing schema.
