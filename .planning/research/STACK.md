# Stack Research: LiiO EatClean

## Recommended Stack (2025)

### Platform & UI
| Component | Choice | Version | Confidence | Rationale |
|-----------|--------|---------|------------|-----------|
| Language | Swift | 5.10+ | ✅ High | Native iOS, type-safe, modern concurrency |
| UI Framework | SwiftUI | iOS 17+ | ✅ High | Declarative, state-driven, perfect for tracking app |
| Charts | Swift Charts | iOS 17+ | ✅ High | Native, LineMark/AreaMark/PointMark for weight tracking |
| Navigation | NavigationStack | iOS 17+ | ✅ High | Type-safe navigation, deep linking ready |

### Data Layer
| Component | Choice | Version | Confidence | Rationale |
|-----------|--------|---------|------------|-----------|
| Local DB | CoreData | iOS 17+ | ✅ High | Mature, complex queries, migration support |
| Architecture | MVVM + Repository | — | ✅ High | Clean separation, testable, swappable backend |
| Concurrency | Swift async/await | Swift 5.10 | ✅ High | Modern, replaces DispatchQueue |
| Observation | @Observable macro | iOS 17+ | ✅ High | Replaces ObservableObject, more efficient |

### Food APIs
| API | Free Tier | Coverage | Best For |
|-----|-----------|----------|----------|
| CalorieNinjas | 10K req/mo | Good international | Quick MVP, simple REST |
| USDA FoodData Central | Unlimited | US foods, research-grade | Free, accurate data |
| Open Food Facts | Unlimited | Global, barcode-based | Scan feature later |
| Nutritionix | 500 req/day | Best commercial | Production quality |

**Recommendation:** Start with CalorieNinjas (simplest API, generous free tier) + local Vietnamese JSON.

### AI Integration
| Component | Choice | Rationale |
|-----------|--------|-----------|
| Primary | OpenAI GPT-4o-mini | Fast, cheap, good at JSON output |
| Fallback | Google Gemini Flash | Free tier generous, good quality |
| Format | JSON structured output | Easy parsing, consistent UI |

### What NOT to Use
| Technology | Why Not |
|-----------|---------|
| SwiftData | Still maturing, CoreData more battle-tested for v1 |
| Realm | Overkill, adds dependency, CoreData sufficient |
| Firebase | Unnecessary backend complexity for local-first app |
| Combine | Replaced by async/await + @Observable in modern SwiftUI |
| UIKit | SwiftUI covers all needs for this app |

## Project Structure

```
LiiO_EatClean/
├── App/
│   └── LiiO_EatCleanApp.swift
├── Models/
│   ├── User.swift
│   ├── Meal.swift
│   ├── FoodItem.swift
│   └── DailyLog.swift
├── Persistence/
│   ├── CoreDataStack.swift
│   ├── LiiO_EatClean.xcdatamodeld
│   └── Repositories/
│       ├── MealRepository.swift
│       ├── FoodRepository.swift
│       └── UserRepository.swift
├── ViewModels/
│   ├── HomeViewModel.swift
│   ├── MealViewModel.swift
│   ├── ProgressViewModel.swift
│   └── ProfileViewModel.swift
├── Views/
│   ├── Splash/
│   ├── Onboarding/
│   ├── SetupGoal/
│   ├── Home/
│   ├── Meals/
│   ├── Progress/
│   └── Profile/
├── Services/
│   ├── FoodAPIService.swift
│   ├── AIService.swift
│   └── NotificationService.swift
├── UseCases/
│   ├── CalculateCaloriesUseCase.swift
│   ├── SearchFoodUseCase.swift
│   └── SuggestMealUseCase.swift
├── Resources/
│   ├── vietnamese_foods.json
│   └── Assets.xcassets
└── Utilities/
    ├── Extensions/
    └── Constants.swift
```
