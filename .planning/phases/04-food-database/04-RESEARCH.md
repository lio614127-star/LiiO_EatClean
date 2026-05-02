# Phase 4: Food Database (Hybrid Search) — Research

**Gathered:** 2026-04-29

## 1. Local Database Seeding (CoreData)

### JSON Structure
To seed the `FoodItem` entities, we need a simple local JSON file `VietnameseFoods.json` included in the app bundle.

```json
[
  {
    "name": "Phở bò",
    "calories": 450,
    "protein": 20,
    "carbs": 50,
    "fat": 15,
    "servingSize": 1
  },
  {
    "name": "Cơm tấm sườn bì chả",
    "calories": 750,
    "protein": 35,
    "carbs": 80,
    "fat": 25,
    "servingSize": 1
  }
]
```

### Seeding Logic in `FoodRepository`
Check if DB is empty, then decode JSON and save to CoreData:
```swift
func seedDatabaseIfNeeded() async throws {
    let count = try await context.perform {
        let request = FoodItem.fetchRequest()
        return try self.context.count(for: request)
    }
    
    if count == 0 {
        // Load JSON from bundle
        guard let url = Bundle.main.url(forResource: "VietnameseFoods", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return }
        
        let decoder = JSONDecoder()
        let items = try decoder.decode([FoodItemDTO].self, from: data)
        
        try await context.perform {
            for item in items {
                let entity = FoodItem(context: self.context)
                entity.id = UUID()
                entity.name = item.name
                entity.calories = item.calories
                entity.protein = item.protein
                entity.carbs = item.carbs
                entity.fat = item.fat
                entity.servingSize = item.servingSize
                entity.source = "local"
                entity.isCustom = false
            }
            try self.context.save()
        }
    }
}
```

## 2. CalorieNinjas API Integration

### API Details
- URL: `https://api.calorieninjas.com/v1/nutrition?query={query}`
- Headers: `X-Api-Key: {API_KEY}`
- Note: Since we are building an intelligent system, the API key should ideally be fetched from the `APIKey` CoreData entity, but for v1 implementation, we can pass it to the service or store it securely.

### Response Format
```json
{
  "items": [
    {
      "sugar_g": 0.0,
      "fiber_g": 0.0,
      "serving_size_g": 100.0,
      "sodium_mg": 0.0,
      "name": "apple",
      "potassium_mg": 107.0,
      "fat_saturated_g": 0.0,
      "fat_total_g": 0.2,
      "calories": 52.1,
      "cholesterol_mg": 0.0,
      "protein_g": 0.3,
      "carbohydrates_total_g": 13.8
    }
  ]
}
```

### Network Service (`FoodAPIService`)
A simple `FoodAPIService` protocol and implementation to fetch data using `URLSession`. It will return `[FoodItemModel]`.

## 3. Hybrid Search Logic

### ViewModel `SearchViewModel`
- Use `@Observable`
- Property: `searchText: String`
- Debounce: Use `.onChange(of: searchText)` with a `Task` and `Task.sleep` for debounce (300ms).
- **Step 1:** Search CoreData (`FoodRepository.searchFoods(query: searchText)`). Update `localResults`.
- **Step 2:** Search API (`FoodAPIService.search(query: searchText)`).
- **Step 3:** Filter API results against `localResults` based on `name` (case-insensitive) to prevent duplicates.
- **Step 4:** Append filtered API results to `apiResults`.

### Suggestions (Recent & Frequent)
- Query CoreData for foods ordered by `lastUsed` (Recent).
- Query CoreData for foods joined with `MealFood` to find most frequently logged (Frequent). Since `MealFood` has the count, we can do a fetch request grouped by food. Alternatively, for simplicity in v1, just fetch foods ordered by `lastUsed` and a simple count or just rely on `lastUsed`.
- *Decision from Context:* Combined list of 5 recent + 5 frequent.
- To keep it simple: `FoodRepository.fetchSuggestions()` returns a combined array.

## 4. UI Implementation (`FoodSearchView`)
- `searchable(text: $viewModel.searchText)`
- List showing `Suggestions` when `searchText` is empty.
- When typing, show `localResults`.
- Show a `ProgressView()` while API is fetching.
- Below local results, show `apiResults` (maybe with a cloud icon `icloud.fill`).
- On tap: trigger an action (e.g., save to cache if API, then proceed to Add Meal).

### Auto-Caching
When a user selects an API item:
```swift
func selectFood(_ food: FoodItemModel) async {
    if food.source == "api" {
        // Cache to CoreData
        try? await foodRepository.saveFood(food)
    }
    // Update lastUsed
    try? await foodRepository.updateLastUsed(for: food.id)
    // Pass selected food back to parent
}
```
