# Research: AI Rebalance & Smart Correction (Phase 28)

## 1. AI Prompt Engineering for Rebalance

The core challenge is providing the AI with a concise yet complete context of the day's intake versus the plan, while enforcing strict rules (Anti-Repeat, Practical Portion).

### Context Structure
- **Core Info:** Daily target (Cal/Protein), Current Time.
- **Truth (Actual):** List of foods eaten + unplanned meals.
- **Intent (Plan):** List of remaining planned meals + statuses.
- **Constraints:** Avoid foods (Allergies), Personality, Rebalance Preference.

### Expected Output Schema
```json
{
  "summary": "Tóm tắt ngắn gọn thay đổi",
  "reason": "Lý do AI điều chỉnh (VD: Bù đạm cho bữa trưa)",
  "changedMeals": [
    {
      "plannedMealId": "UUID",
      "changeType": "portionAdjusted | swapped | removed",
      "newName": "Tên món mới (nếu đổi)",
      "newCalories": 350,
      "newProtein": 25,
      "portionRatio": 0.8,
      "reason": "Giải thích riêng cho bữa này"
    }
  ]
}
```

## 2. CoreData & Model Extensions

We need to track if a plan was rebalanced to provide context for future insights.

### DailyPlan entity updates:
- `isRebalanced`: Boolean
- `rebalanceReason`: String?
- `rebalancedAt`: Date?
- `previousPlanSnapshot`: Binary Data (JSON representation of the plan before rebalance for potential Undo).

### PlannedMeal entity updates:
- `isLocked`: Boolean (User can lock a meal to prevent AI from swapping/adjusting it).

## 3. UI/UX: Before vs After Preview

A vertical comparison is preferred. We need a way to visualize the "Delta".

### Component Ideas:
- `RebalancePreviewSheet`: A sheet with `presentationDetents([.large])`.
- `ComparisonHeader`: Shows "Before" vs "After" totals (Calories/Protein).
- `DiffMealCard`: A card that shows the old meal (strikethrough or faded) and the new suggested meal.

## 4. Rebalance Trigger Logic

We need a centralized service to check if a rebalance is needed.

### `RebalanceService.checkStatus()`
- Input: `DailyNutritionRecord`.
- Logic:
    - If `totalActual + remainingPlan > target * 1.10` -> `return .overLimit(diff)`.
    - If `time > 18:00` and `totalActual < target * 0.55` -> `return .underLimit(diff)`.
    - If `unplannedMealLogged > 250` -> `return .unplannedDeviation(diff)`.

## 5. Risk Assessment
- **AI Hallucination:** Ensure AI doesn't hallucinate that an "eaten" meal can be changed.
- **Performance:** Complex prompts might increase latency. Consider using a faster model (Gemini Flash) for rebalancing if appropriate.
- **UI Complexity:** Showing too much info in the preview might overwhelm the user. Stick to "What changed" + "Why".
