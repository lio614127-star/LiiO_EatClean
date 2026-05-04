---
status: investigating
trigger: AI suggested "Cháo gà xé phay" with 250 portions and 64,500 kcal.
updated: 2026-05-03
---

# Symptoms
- AI Suggestion returns extremely high portion counts (e.g., 250.0).
- Total calories are multiplied by this incorrect portion count, resulting in massive numbers (64,500 kcal).
- Likely happening during the parsing of AI response or the normalization of food items.

# Current Focus
- hypothesis: The AI is returning the weight in grams but the app is interpreting it as "portions", or there is a decimal point error in the AI service logic.
- next_action: Examine the AI service response parsing and the Food model mapping.

# Evidence
- (To be populated)
