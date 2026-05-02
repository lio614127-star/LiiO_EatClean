# Architecture Research: LiiO EatClean

## System Architecture

```
┌─────────────────────────────────────────────┐
│                 SwiftUI Views               │
│  Splash │ Onboarding │ Home │ Meals │ etc.  │
├─────────────────────────────────────────────┤
│              ViewModels (@Observable)        │
│  HomeVM │ MealVM │ ProgressVM │ ProfileVM   │
├─────────────────────────────────────────────┤
│              Use Cases (Business Logic)      │
│  CalculateCalories │ SearchFood │ SuggestMeal│
├─────────────────────────────────────────────┤
│              Repository Layer (Protocols)    │
│  MealRepo │ FoodRepo │ UserRepo │ LogRepo   │
├─────────────────────────────────────────────┤
│              Data Sources                    │
│  CoreData │ Food API │ AI API │ Local JSON   │
└─────────────────────────────────────────────┘
```

## Component Boundaries

### Views (Presentation)
- **Responsibility:** Render UI, capture user input
- **Rules:** No business logic, no direct data access
- **Communicates with:** ViewModels only

### ViewModels (Presentation Logic)
- **Responsibility:** UI state management, user action handling
- **Rules:** @MainActor, @Observable macro, calls Use Cases
- **Communicates with:** Use Cases, NOT directly with repositories

### Use Cases (Domain Logic)
- **Responsibility:** Business rules (calorie calculation, food search strategy)
- **Rules:** Protocol-based dependencies, testable
- **Communicates with:** Repository protocols

### Repositories (Data Abstraction)
- **Responsibility:** Data CRUD, source selection (local vs API)
- **Rules:** Implements protocol, hides CoreData/API details
- **Communicates with:** CoreData, API services

## Data Flow

### Add Meal Flow
```
User taps "Add Meal"
  → MealView shows search
  → User types food name
  → MealViewModel.searchFood(query)
  → SearchFoodUseCase.execute(query)
  → FoodRepository.search(query)
    → 1. Query CoreData cache (instant)
    → 2. If no results → call Food API
    → 3. Cache API results to CoreData
  → Results displayed in list
  → User selects food + portion
  → MealViewModel.saveMeal(food, portion)
  → MealRepository.save(meal)
  → HomeViewModel refreshes daily calories
```

### Daily Calorie Calculation
```
User completes Setup Goal
  → SetupGoalViewModel collects: weight, height, age, gender, goal
  → CalculateCaloriesUseCase.execute(profile)
    → BMR = Mifflin-St Jeor formula
    → TDEE = BMR × activity multiplier
    → Target = TDEE - deficit (for weight loss)
  → Save to UserRepository
  → Home Dashboard displays target
```

### AI Suggestion Flow
```
User taps "AI Suggest"
  → AIViewModel.suggest()
  → SuggestMealUseCase.execute(remainingCalories, goal, todayMeals)
    → Build prompt with context
    → AIService.call(prompt)
      → Try apiKeys[currentIndex]
      → If fail → rotate to next key
    → Parse JSON response
  → Display suggestions as cards
```

## Data Schema (CoreData Entities)

### User
- id: UUID
- name: String
- age: Int16
- height: Double (cm)
- weight: Double (kg)
- goalType: String (lose/maintain/gain)
- dailyCalorieTarget: Int32
- createdAt: Date
- updatedAt: Date

### Meal
- id: UUID
- userId: UUID
- date: Date
- mealType: String (breakfast/lunch/dinner/snack)
- totalCalories: Int32
- createdAt: Date

### FoodItem
- id: UUID
- name: String
- calories: Int32 (per serving)
- servingSize: String
- source: String (local/api)
- apiId: String? (external reference)
- lastUsed: Date

### MealFood (junction)
- id: UUID
- mealId: UUID
- foodItemId: UUID
- quantity: Double
- calories: Int32

### DailyLog
- id: UUID
- userId: UUID
- date: Date
- totalCalories: Int32
- waterIntake: Double (ml)
- weight: Double? (optional daily weigh-in)

### WeightEntry
- id: UUID
- userId: UUID
- date: Date
- weight: Double (kg)

### APIKey
- id: UUID
- provider: String (openai/gemini)
- key: String
- isActive: Bool
- createdAt: Date

## Build Order (Dependencies)

1. **CoreData schema + Repository layer** — foundation everything builds on
2. **User profile + Goal setup** — needed for calorie targets
3. **Home Dashboard** — central hub, can use fake data initially
4. **Food database + search** — needed before meal logging
5. **Meal logging** — core feature, updates dashboard
6. **Progress/Weight tracking** — visualization layer
7. **AI integration** — enhancement on top of core tracking
8. **Notifications + polish** — final touches
