# Research Summary: LiiO EatClean

## Key Findings

### Stack
- **Swift + SwiftUI** (iOS 17+) with **@Observable macro** for modern reactive UI
- **CoreData** with Repository pattern — mature, battle-tested, migration-ready
- **Swift Charts** framework for weight tracking graphs (LineMark, AreaMark, PointMark)
- **async/await** for all networking — modern Swift concurrency
- **CalorieNinjas API** for food search (simplest, 10K req/mo free) + local Vietnamese JSON

### Table Stakes
- Daily calorie target (TDEE calculation)
- Calorie progress visualization (ring)
- Meal logging by time slot
- Food search with nutrition data
- Weight tracking with charts
- User profile & goal setup
- Onboarding wizard

### Differentiators
- **Vietnamese food database** — no competitor focuses here, high impact
- **AI meal suggestions** — real AI (OpenAI/Gemini) from day one
- **Multi API key rotation** — reliability for personal use

### Watch Out For
1. **Inaccurate calorie data** — always include serving sizes, cross-validate
2. **CoreData threading** — map to structs in Repository, never pass NSManagedObject across threads
3. **Onboarding drop-off** — max 3-4 steps, get to dashboard within 60s
4. **Slow food search** — local-first, debounce API, cache everything
5. **AI parse failures** — enforce JSON format, graceful fallback
6. **Date/timezone bugs** — UTC storage, Calendar.current for display

### Architecture Decision
MVVM + Clean Architecture with Repository pattern:
```
Views → ViewModels (@Observable) → Use Cases → Repositories → CoreData/API
```

### Build Order
1. CoreData + Repository foundation
2. Splash + Onboarding + Goal Setup
3. Home Dashboard with progress ring
4. Food database + search (hybrid)
5. Meal logging (core loop)
6. Progress/Weight charts
7. AI meal suggestions
8. Water tracking + Notifications + Polish
