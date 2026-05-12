---
status: investigating
trigger: "Meal suggestions re-load on every picker change, and AI activity tags leak to the main Meals tab when AddMealView is dismissed."
symptoms:
  expected: "Suggestions should be cached per meal type and not re-load unless manually requested. AI activity tags should be suppressed when the sheet is closed, while background processing continues silently."
  actual: "Every picker change triggers a fresh AI call. AI tags appear on the main tab after dismissing the sheet."
  timeline: "After implementing the gap fixes for Phase 21."
  reproduction: "Open Add Meal, wait for suggestions, change meal type picker, observe re-load. Close sheet, observe AI tag in Meals tab."
created: 2026-05-10T12:20:00Z
updated: 2026-05-10T12:20:00Z

## Current Focus
hypothesis: "AddMealViewModel lacks a per-meal-type cache for suggestions, and its AI calls are not correctly flagged as internal or handled with persistent tasks that hide UI tags."
next_action: "Analyze AddMealViewModel and AddMealView to implement caching and silent background processing."
