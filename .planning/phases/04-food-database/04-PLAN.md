---
wave: 1
depends_on: ["03-PLAN"]
files_modified: ["LiiO_EatClean/Data/Models/FoodItemModel.swift", "LiiO_EatClean/Data/Repositories/FoodRepository.swift", "LiiO_EatClean/Resources/VietnameseFoods.json", "LiiO_EatClean/Services/FoodAPIService.swift", "LiiO_EatClean/Features/Meals/FoodSearchViewModel.swift", "LiiO_EatClean/Features/Meals/FoodSearchView.swift"]
autonomous: true
---

# Phase 4: Food Database (Hybrid Search)

## Objective
Implement an offline-first, intelligent food database system with hybrid search capabilities. Seed a local database with Vietnamese foods, fetch international foods from CalorieNinjas API, prioritize local results, and automatically cache selected API foods into the local database for future use.

## Requirements Covered
- **FOOD-01**: Local Vietnamese foods JSON seed
- **FOOD-02**: Food API integration (CalorieNinjas)
- **FOOD-03**: Hybrid search (Local first, API fallback, deduplication)
- **FOOD-04**: Food search UI (debounce, loading state, suggestions)

---

## 1. Local Database Seeding
<task>
<read_first>
- `.planning/phases/04-food-database/04-CONTEXT.md` (D-01, D-02, D-03)
- `LiiO_EatClean/Data/Repositories/FoodRepository.swift`
</read_first>
<action>
Create `LiiO_EatClean/Resources/VietnameseFoods.json`:
- Provide a flat JSON array of ~10 core Vietnamese foods (Phở bò, Bún chả, Cơm tấm, Bánh mì thịt, Gỏi cuốn, Bún bò Huế, Xôi gấc, Cà phê sữa đá, Sinh tố bơ, Phở gà) with accurate `calories`, `protein`, `carbs`, `fat`, `servingSize`.

Update `LiiO_EatClean/Data/Repositories/FoodRepository.swift`:
- Add `func seedDatabaseIfNeeded() async throws`.
- Implementation: Check if `FoodItem.fetchRequest()` count is 0. If so, parse `VietnameseFoods.json` and create CoreData entities. Set `source = "local"`, `isCustom = false`.
- Call this method in `init` or provide a way to call it on app launch.
</action>
<acceptance_criteria>
- `VietnameseFoods.json` exists with ~10 items.
- `FoodRepository` contains `seedDatabaseIfNeeded()` method.
- Seeded items have `source="local"` and `isCustom=false`.
</acceptance_criteria>
</task>

## 2. Food API Integration (CalorieNinjas)
<task>
<read_first>
- `.planning/phases/04-food-database/04-CONTEXT.md` (D-04, D-09)
- `.planning/phases/04-food-database/04-RESEARCH.md` (Section 2)
</read_first>
<action>
Create `LiiO_EatClean/Services/FoodAPIService.swift`:
- Define `FoodAPIServiceProtocol` with `func search(query: String) async throws -> [FoodItemModel]`.
- Implement `FoodAPIService`.
- Hardcode a temporary API key or fetch from a secure place.
- Endpoint: `https://api.calorieninjas.com/v1/nutrition?query={query}`.
- Map the JSON response (`items` array) to `FoodItemModel`. Set `source="api"` and `isCustom=false`.
- If API fails, return `[]` (Silent fallback logic will be handled here or in ViewModel).
</action>
<acceptance_criteria>
- `FoodAPIService.swift` exists.
- Contains protocol and implementation.
- Successfully parses CalorieNinjas response into `FoodItemModel` with `source="api"`.
</acceptance_criteria>
</task>

## 3. Food Repository Extensions (Search & Suggestions)
<task>
<read_first>
- `LiiO_EatClean/Data/Repositories/FoodRepository.swift`
- `.planning/phases/04-food-database/04-CONTEXT.md` (D-06, D-07)
</read_first>
<action>
Extend `LiiO_EatClean/Data/Repositories/FoodRepository.swift`:
- Add `func searchLocalFoods(query: String) async throws -> [FoodItemModel]`
  - Use `NSPredicate(format: "name CONTAINS[cd] %@", query)`
- Add `func fetchSuggestions() async throws -> [FoodItemModel]`
  - Return up to 10 foods ordered by `lastUsed` descending (combines recent/frequent conceptually for v1).
- Add `func updateLastUsed(for id: UUID) async throws`
  - Fetch item by ID, set `lastUsed = Date()`, save context.
- Add `func saveFood(_ food: FoodItemModel) async throws`
  - Save a new `FoodItem` (used for caching API items).
</action>
<acceptance_criteria>
- `searchLocalFoods(query:)` implemented.
- `fetchSuggestions()` implemented ordering by `lastUsed`.
- `updateLastUsed(for:)` implemented.
- `saveFood(_:)` implemented.
</acceptance_criteria>
</task>

## 4. FoodSearchViewModel (Hybrid Logic)
<task>
<read_first>
- `.planning/phases/04-food-database/04-CONTEXT.md` (D-04, D-05)
</read_first>
<action>
Create `LiiO_EatClean/Features/Meals/FoodSearchViewModel.swift`:
- Use `@Observable`.
- Properties: `searchText: String`, `localResults: [FoodItemModel]`, `apiResults: [FoodItemModel]`, `suggestions: [FoodItemModel]`, `isSearchingAPI: Bool`.
- Inject `FoodRepositoryProtocol` and `FoodAPIServiceProtocol`.
- `func loadSuggestions() async`
- `func performSearch(query: String) async`
  1. Set `localResults` by querying local repo immediately.
  2. Set `isSearchingAPI = true`.
  3. Fetch from API.
  4. Deduplicate: Filter API results whose `name.lowercased()` matches any in `localResults`.
  5. Set `apiResults` to the filtered array.
  6. Set `isSearchingAPI = false`.
- Handle debouncing logic (e.g., using a delayed Task).
</action>
<acceptance_criteria>
- `FoodSearchViewModel` exists and is `@Observable`.
- Contains `localResults` and `apiResults` arrays.
- Implements hybrid search logic: local first, then API.
- Implements deduplication (local priority).
</acceptance_criteria>
</task>

## 5. FoodSearchView (UI)
<task>
<read_first>
- `.planning/phases/04-food-database/04-CONTEXT.md` (D-04, D-06)
</read_first>
<action>
Create `LiiO_EatClean/Features/Meals/FoodSearchView.swift`:
- Uses `FoodSearchViewModel`.
- `searchable(text: $viewModel.searchText)`.
- Use `.onChange(of: viewModel.searchText)` to trigger debounced search.
- If `searchText` is empty, show "Gợi ý" list (`viewModel.suggestions`).
- If typing:
  - Show `localResults` (List section: "Dữ liệu offline").
  - If `isSearchingAPI` is true, show `ProgressView()` below local results.
  - Show `apiResults` (List section: "Từ CalorieNinjas", with cloud icon `icloud.fill` on rows).
- Action when selecting a row (simulated for now, as logging happens in Phase 5):
  - Print selected food name.
  - If `source == "api"`, call `repository.saveFood` to auto-cache.
  - Call `repository.updateLastUsed`.
</action>
<acceptance_criteria>
- UI implements `.searchable`.
- Displays combined Suggestions when empty.
- Displays Local Results instantly.
- Displays API results with a cloud icon after loading.
- Includes auto-cache logic placeholder on tap.
</acceptance_criteria>
</task>

---
## Verification Criteria
- Grep: `VietnameseFoods.json` exists.
- Grep: `seedDatabaseIfNeeded` exists in FoodRepository.
- Grep: `https://api.calorieninjas.com` exists in FoodAPIService.
- Grep: `performSearch` in FoodSearchViewModel.
- UI View `FoodSearchView` displays properly in Preview.
