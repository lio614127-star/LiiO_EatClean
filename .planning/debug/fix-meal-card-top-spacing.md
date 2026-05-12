---
status: investigating
trigger: "Meal card has excessive top spacing above the food name text."
symptoms:
  expected: "Text should be vertically centered or the card height should fit the content more tightly with balanced padding."
  actual: "Large empty area at the top of the card."
  reproduction: "View any meal suggestion card in the Day Plan or Meals tab."
created: 2026-05-10T12:24:00Z
updated: 2026-05-10T12:24:00Z

## Current Focus
hypothesis: "The Meal card view (possibly PlanFoodCard) has a fixed height or an Spacer/VStack alignment issue that pushes content to the bottom."
next_action: "Locate the card view definition and adjust its internal layout/padding."
