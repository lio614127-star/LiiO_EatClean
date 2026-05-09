# Next-Gen Nutrition Architecture & AI Planning 2.0

## 1. Constraint-based Single Pass Planning (Fast Daily Plan)
**Problem:** Master Planner -> sub-agents is too slow (25-50s), wastes tokens, and risks hallucination.
**Solution:**
- **Step 1:** App calculates the calorie framework (e.g., Sáng 25%, Trưa 35%, Tối 30%, Snack 10%).
- **Step 2:** App builds a "candidate pool" from favorites, Vietnamese foods, avoiding user's constraints.
- **Step 3:** AI is called **ONCE** to select and arrange the candidates into the daily plan.
**Result:** Planning time drops to 4-10s with much higher consistency.

## 2. Smart Unit System
**Problem:** Hardcoding units (e.g., cơm = chén) fails for variants like cơm chiên, cơm tấm.
**Solution:**
- Implement `FoodPortionProfile`:
  ```json
  { "food": "Cơm trắng", "defaultUnit": "chén", "gramPerUnit": 200, "allowedUnits": ["gram", "chén", "dĩa"] }
  ```
- Add a **Density Layer** (1 muỗng dầu ≠ 1 muỗng cơm) to scale properly.

## 3. Structured Meal (Ingredient-level detail)
**Problem:** "Cá diêu hồng hấp + cơm + rau" as a single string is limiting.
**Solution:**
- Transition to `Structured Meal`:
  ```json
  {
    "mealName": "Cá diêu hồng hấp gừng hành",
    "components": [
      { "name": "Cá diêu hồng", "grams": 180 },
      { "name": "Cơm trắng", "unit": "1 chén", "grams": 200 }
    ]
  }
  ```
- This unlocks: editing ingredients, swapping, auto grocery list, realtime macro recalculation.

## 4. AI Cooking Assistant
**Problem:** Need guidance on how to cook suggested meals without just dumping text into a chat.
**Solution:**
- **Recipe Context Card:** When tapping "AI dạy nấu ăn", inject a structured payload into the AI Coach chat.
- Switch AI Coach to **cooking instructor** mode.
- **Step Mode:** Step 1/7 -> "Tiếp theo".
- **Voice Mode:** "Lửa lớn hay nhỏ?", "Chiên bao lâu?".

## 5. Editable Meal Plan
**Problem:** User cannot change the AI's plan easily.
**Solution:**
- Meal slots must be editable (e.g., Swap breakfast).
- **Local Recommendation Engine:** Suggest 10 alternatives instantly based on meal category, kcal target, and Vietnamese foods WITHOUT calling AI.
- AI is only used to regenerate the entire plan or for complex reasoning.

## 6. Diversity Engine
**Problem:** Repetitive suggestions (e.g., yến mạch 4 days a week).
**Solution:**
- Add metadata to foods: `proteinType`, `cuisine`, `mealType`, `cookingMethod`.
- **Rules:** Same main ingredient max 2 times/week.
- **Exemptions:** User's favorite foods are allowed to repeat.
