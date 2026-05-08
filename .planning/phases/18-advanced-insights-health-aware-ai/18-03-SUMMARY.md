# Plan 18-03: AI Output Validation & Minimal Re-ask

## Completed Tasks
- Added `quickReask` and `quickReaskForFood` methods to `AIService` for lightweight, single-turn replacement requests.
- Integrated `FoodSafetyValidator` into `MealSuggestionViewModel` and `MealPlanViewModel` to filter out unsafe food items and execute minimal re-asks to replace them cleanly.
- Upgraded `ChatViewModel` to perform a free-text scan on AI responses post-streaming. If forbidden foods are detected, a minimal rewrite prompt is sent to quickly replace the text before finalizing.
- Added the `healthSafetyApplied` state variable to all ViewModels to track when safety corrections are actively applied, preparing for the UI integration step.

## Validation
- Free-text violations in Chat are now successfully rewritten without regenerating the entire response history.
- Meal JSON items that violate health rules are individually replaced via API re-asks, scaling proportionally without affecting valid items.
