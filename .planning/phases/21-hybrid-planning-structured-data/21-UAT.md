---
status: complete
phase: 21-hybrid-planning-structured-data
source: [.planning/phases/21-hybrid-planning-structured-data/21-SUMMARY.md]
started: 2026-05-10T11:50:00Z
updated: 2026-05-10T12:04:35Z
---

## Current Test

[testing complete]

## Tests

### 1. Turbo Daily Planning
expected: |
  Click "Lên kế hoạch ngày" in the Meals tab.
  Observe 4 meals being generated one by one in a streaming fashion.
  The total calories for the plan should be within ±10% of the daily target.
result: pass

### 2. Smart Unit Recognition
expected: |
  Check the suggested foods in the plan.
  Verify that Vietnamese foods have natural units (e.g., "tô" for Phở, "dĩa" for Cơm tấm).
  Verify that macro breakdown (P/C/F) is visible and realistic based on the gram weights.
result: pass

### 3. Recipe Detail Sheet
expected: | |
  Click on any suggested food item in the Plan list.
  Observe a detail sheet appearing with a list of ingredients and step-by-step cooking instructions.
result: issue
reported: "Các nguyên liệu chính nên xếp từ trên xuống dưới, các gia vị nêm nếm nên để xuống dưới cùng để nhìn nguyên liệu chính dễ hơn"
severity: minor

### 4. Background Enrichment
expected: |
  Log a common food item (e.g., "Phở bò") from the Home or Meals tab.
  Wait a few seconds, then click on the logged item to view details.
  Verify that ingredients and instructions have been automatically populated by the AI background worker.
result: pass

### 5. Navigation Identity Stability
expected: |
  Open the "Add Meal" sheet for "Bữa sáng".
  Close it, then immediately open the "Add Meal" sheet for "Bữa tối".
  Verify that the sheet header and logic correctly reflect "Bữa tối", not the previous selection.
result: issue
reported: "Các gợi ý khi tôi thay đổi buổi ăn nó chỉ mặc định 1 gợi ý chung chứ không tự thay đổi gợi ý theo buổi ăn đã chọn"
severity: major

### 6. Debounced Summary Card
expected: |
  Delete or add several food items rapidly in the Home tab.
  Observe that the "Daily Summary" card shows a loading spinner but doesn't flicker or regenerate until 10 seconds after the LAST modification.
result: pass

### 7. Background Planning Persistence
expected: |
  Start the "Lên kế hoạch ngày" generation.
  While it is loading (spinner visible), close the sheet and navigate to the Home tab.
  Wait 10 seconds, then return to the Meals tab and open "Lên kế hoạch ngày".
  Verify that the plan has completed in the background and is ready for review.
result: pass

## Summary

total: 7
passed: 5
issues: 2
pending: 0
skipped: 0

## Gaps

- truth: "Ingredients should be sorted logically: main ingredients first, then seasonings/condiments at the bottom."
  status: failed
  reason: "User reported: Các nguyên liệu chính nên xếp từ trên xuống dưới, các gia vị nêm nếm nên để xuống dưới cùng để nhìn nguyên liệu chính dễ hơn"
  severity: minor
  test: 3
  artifacts: []
  missing: []

- truth: "Meal suggestions in AddMealView should refresh and match the specific mealType (Breakfast/Lunch/Dinner) when the sheet is opened."
  status: failed
  reason: "User reported: Các gợi ý khi tôi thay đổi buổi ăn nó chỉ mặc định 1 gợi ý chung chứ không tự thay đổi gợi ý theo buổi ăn đã chọn"
  severity: major
  test: 5
  artifacts: []
  missing: []
