# Phase 4: Food Database (Hybrid Search) - Context

**Gathered:** 2026-04-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Build an offline-first, intelligent food database system. This includes seeding a local CoreData database with ~50 common Vietnamese foods (flat JSON list), building a hybrid search UI (debounce, recent/frequent suggestions combined), and integrating the CalorieNinjas API. The system auto-caches API selections into CoreData, gradually building a personalized, offline-capable database.

</domain>

<decisions>
## Implementation Decisions

### Local Database (Vietnamese Foods)
- **D-01:** Data Structure: Use a flat list structure for the initial JSON seed data. Categories are deferred or handled at the UI layer if needed later. Search is fast enough for <1000 items.
- **D-02:** Seed Quantity: Start with ~50 core Vietnamese items (Phở, bún, cơm, bánh mì, popular drinks). Prioritize highly accurate macro/calorie data over a massive but inaccurate dataset.
- **D-03:** Local Database Seeding: The JSON file should be parsed and loaded into CoreData (`FoodItem`) on first launch if the database is empty.

### Hybrid Search Strategy
- **D-04:** Search Flow: 
  1. User types (with 300ms debounce).
  2. Query CoreData immediately. Show local results instantly.
  3. Fire API request in background.
  4. Append API results to the bottom of the list when they return (with a visual indicator like a cloud icon).
- **D-05:** Deduplication: Local data has absolute priority. If the API returns an item that closely matches a local item name, filter the API item out. Do not show duplicates to avoid user confusion and calorie inaccuracies.

### Pre-search Suggestions
- **D-06:** Combined Suggestions List: Before the user types, show a single "Gợi ý" (Suggestions) list combining 5 Recent foods and 5 Frequent foods. Do not use separate tabs to minimize friction.

### API & Caching Logic
- **D-07:** Auto-Caching (Intelligent Learning): When a user selects a food from the API results to log, *automatically save it permanently to CoreData* (set `source="api"`).
- **D-08:** Progressive Offline: Future searches for that cached term will hit the local database instantly, reducing API calls and making the app smarter over time.
- **D-09:** Silent Fallback: If the API fails, times out, or hits a rate limit, fail silently. Just show the local results. Do not display error alerts that break the user's flow.

### Agent's Discretion
- The exact structure of the seed JSON file (as long as it maps to `FoodItem` properties).
- The visual distinction between local items and API items in the search results list.
- The precise implementation of the debounce logic (e.g., Combine or async/await Task cancellation).
- The exact string matching logic for deduplication (e.g., case-insensitive comparison, trimming whitespaces).

</decisions>

<canonical_refs>
## Canonical References

### Prior Phase Context
- `.planning/phases/01-project-foundation/01-CONTEXT.md` — CoreData schema (FoodItem, MealFood)
- `.planning/phases/03-home-dashboard/03-CONTEXT.md` — UI conventions and data flow

### Project Context
- `.planning/REQUIREMENTS.md` — FOOD-01 through FOOD-04
- `.planning/ROADMAP.md` — Phase 4 success criteria

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `LiiO_EatClean/Data/Repositories/FoodRepository.swift` — Will need new methods for search, seed, and cache
- `LiiO_EatClean/Data/Models/FoodItemModel.swift` — Represents the data structure

### Integration Points
- Search UI will later be embedded in the "Add Meal" flow (Phase 5). For this phase, build the UI component independently or as a standalone view for testing.
- The CalorieNinjas API requires an API key, which should be managed (even if hardcoded for testing initially, prepare for the APIKey entity rotation in the future).

</code_context>

<specifics>
## Specific Ideas

- The core insight from the discussion is building an "Offline-first intelligent system." The local database is the core, the API is just an assistant, and the cache learns from the user.
- Focus heavily on the speed and responsiveness of the local search.

</specifics>

<deferred>
## Deferred Ideas

- Categorized browsing (e.g., viewing a menu of "Món nước"). The flat list search is sufficient for v1.
- Barcode scanning (deferred to v2).

</deferred>

---

*Phase: 04-Food Database*
*Context gathered: 2026-04-29*
