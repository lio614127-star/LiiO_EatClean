status: resolved
trigger: "AI tasks not batching and key distribution is uneven (only 1 key used instead of 2)"
root_cause: "MealPlanViewModel was calling individual AI requests instead of using the AIOrchestrator, causing the AI Service to pick the same best key for all requests and display separate task boards."
fix: "Refactored MealPlanViewModel to use AIOrchestrator.shared.generateDayPlanBatched and generateWeekPlanBatched. Added meal type normalization to ensure UI consistency."
verification: "Meals are batched by key, and workload is distributed across all available keys in the UI."
files_changed:
  - "/Users/liio/TooL_LiiO/LiiO_EatClean/LiiO_EatClean/Features/AI/ContextBuilder.swift"
  - "/Users/liio/TooL_LiiO/LiiO_EatClean/LiiO_EatClean/Features/Meals/MealPlanViewModel.swift"

# Current Focus
- hypothesis: "RESOLVED"
- next_action: "COMPLETED"
