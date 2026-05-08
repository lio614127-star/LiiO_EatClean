# Plan 18-04: InsightDetector Expansion

## Completed Tasks
- Upgraded `InsightSeverity` to a 3-tier enum (`.low`, `.medium`, `.high`) with `Comparable` conformance for robust sorting.
- Retrofitted existing insight triggers (low protein, skipped meal, calorie overrun, low water) to use the new 3-tier system.
- Implemented `detectRepeatedMeals` utilizing `FoodSafetyValidator`'s normalization and a localized stop-word filter (e.g., "chiên", "xào", "phần vừa") to accurately detect foods eaten $\ge$ 3 times within a 5-day rolling window.
- Implemented `detectMacroImbalance` utilizing flexible macro ranges (focusing primarily on high fat > 40%) that trigger when anomalies persist for $\ge$ 3 consecutive days.
- Injected both new detection methods into the core `detectInsights()` flow.
- Increased the global insight cap from 3 to 5 and sorted them by severity descending.

## Validation
- `InsightDetector` successfully groups daily macros and accurately determines consecutive day breaches.
- Repeated meal normalization correctly deduplicates variations (e.g., "Cơm gà xé" and "Cơm gà chiên" map to the same base entity for detection purposes).
