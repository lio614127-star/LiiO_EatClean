# Plan 10C: AI Proactive Suggestion Section

**Wave:** 2 (can run parallel with Plan 10B, both depend on 10A)
**Requirements:** AIMEAL-03, AIMEAL-04, AIMEAL-06
**Depends on:** Plan 10A

## Objective

Xây dựng AI Suggestion Section trong Meals tab: proactive gợi ý bữa ăn dựa trên calo còn lại, sở thích, bệnh lý. AI tự chạy sẵn khi mở tab — user thấy gợi ý ngay, có nút "Log Ngay" để lưu trực tiếp.

## Task 1: Create MealSuggestionViewModel

<read_first>
- LiiO_EatClean/Features/AI/AIService.swift (suggestMeals method + AISuggestedFood model)
- LiiO_EatClean/Features/AI/ContextBuilder.swift (after refactor from Plan 10A)
- LiiO_EatClean/Services/MemoryManager.swift (after upgrade from Plan 10A)
- LiiO_EatClean/Features/Chat/ChatViewModel.swift (reference for logSuggestedFood pattern)
- LiiO_EatClean/Data/Repositories/MealRepository.swift
</read_first>

<action>
Create `LiiO_EatClean/Features/Meals/MealSuggestionViewModel.swift`:

```swift
@Observable
class MealSuggestionViewModel {
    var suggestions: [AISuggestedFood] = []
    var isLoading = false
    var errorMessage: String?
    var remainingCalories: Double = 0
    var loggedFoodName: String?  // for success feedback
    var showLogSuccess = false
    
    private let aiService = AIService.shared
    private let contextBuilder = ContextBuilder()
    private let mealRepository: MealRepositoryProtocol
    private let memoryManager: MemoryManagerProtocol
    
    // Auto-determine meal type based on current time
    var suggestedMealType: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<10: return "Bữa sáng"
        case 10..<14: return "Bữa trưa"
        case 14..<17: return "Ăn vặt"
        case 17..<21: return "Bữa tối"
        default: return "Ăn vặt"
        }
    }
    
    // Proactive: auto-fetch on appear
    func fetchSuggestions(remainingCalories: Double) async { 
        // Use .mealSuggestion strategy from ContextBuilder
        // Build prompt with health conditions + avoid foods + preferences
        // Call AIService.suggestMeals() or sendChatMessage with mealSuggestion context
    }
    
    // Log a suggestion directly
    func logSuggestion(_ food: AISuggestedFood) async {
        // Reuse pattern from ChatViewModel.logSuggestedFood
        // Save via MealRepository
        // Show success feedback
    }
    
    // Refresh for new suggestions
    func refreshSuggestions(remainingCalories: Double) async { ... }
}
```

**CRITICAL:** Use `.mealSuggestion` strategy when building prompt. The priority order MUST be:
1. Avoid foods (from health conditions) — marked [CẤM] in prompt
2. Remaining calories constraint
3. User preferences (likes/dislikes)

Must NOT suggest foods in the avoid list. This is a safety constraint.
</action>

<acceptance_criteria>
- File `Features/Meals/MealSuggestionViewModel.swift` exists
- Uses `@Observable` macro
- Contains `var suggestedMealType: String` computed from current hour
- Contains `func fetchSuggestions(remainingCalories: Double) async`
- Contains `func logSuggestion(_ food: AISuggestedFood) async`
- Uses `.mealSuggestion` strategy with ContextBuilder
- Uses MealRepositoryProtocol for saving logged meals
</acceptance_criteria>

## Task 2: Create AISuggestionSectionView

<read_first>
- LiiO_EatClean/Features/Chat/Components/ActionableMessageView.swift (reference for suggestion cards)
- LiiO_EatClean/Features/Home/Components/CalorieRingView.swift (reference for visual style)
</read_first>

<action>
Create `LiiO_EatClean/Features/Meals/Components/AISuggestionSectionView.swift`:

**Layout:**
```
VStack(alignment: .leading, spacing: 16) {
    // Section Header
    HStack {
        Image(systemName: "sparkles")
            .foregroundColor(.green)
        Text("AI Gợi ý")
            .font(.headline)
        Spacer()
        Button("Gợi ý thêm") { refresh }
            .font(.subheadline)
            .foregroundColor(.green)
    }
    
    // Remaining calories banner
    HStack {
        Text("Bạn còn \(Int(remainingCalories)) kcal hôm nay")
            .font(.subheadline)
            .foregroundColor(.secondary)
        
        Text("• \(suggestedMealType)")
            .font(.subheadline.bold())
            .foregroundColor(.green)
    }
    
    // Suggestion Cards (or loading/error/empty state)
    if isLoading {
        ProgressView("Đang suy nghĩ...")
    } else if let error = errorMessage {
        // Error state with retry button
    } else if suggestions.isEmpty {
        // Empty state: "Thêm API key trong Profile để nhận gợi ý"
    } else {
        ForEach(suggestions) { food in
            SuggestionCard(food: food, onLog: { logSuggestion(food) })
        }
    }
}
.padding(16)
.background(Color(.systemBackground))
.cornerRadius(16)
.shadow(color: .black.opacity(0.05), radius: 8, y: 2)
```

**SuggestionCard (inline or separate):**
- Food name + calories (bold green)
- P/C/F macro row
- "Log Ngay" button (green, full width) → taps log directly
- Card style: rounded corners, subtle border, consistent with app design
- Success animation: brief checkmark overlay after logging

**States:**
- Loading: shimmer/spinner
- No API key: guide to Profile
- Error: retry button
- Success: brief "Đã thêm ✓" animation
</action>

<acceptance_criteria>
- File `Features/Meals/Components/AISuggestionSectionView.swift` exists
- Shows "Bạn còn X kcal hôm nay" banner
- Shows suggested meal type based on current time
- "Gợi ý thêm" button triggers refresh
- Each suggestion card shows food name, calories, P/C/F macros
- Each card has "Log Ngay" button
- Loading state shows ProgressView
- Error state shows retry button
- Empty/no-key state shows guidance text
</acceptance_criteria>

## Task 3: Integrate AI Section into MealsView

<read_first>
- LiiO_EatClean/Features/Meals/MealsView.swift (after Plan 10B rebuild)
</read_first>

<action>
Add the `AISuggestionSectionView` at the bottom of MealsView's ScrollView, below the meal sections:

```swift
// In MealsView body, after meal sections:
Divider()
    .padding(.vertical, 8)

AISuggestionSectionView(
    viewModel: suggestionViewModel,
    remainingCalories: mealsViewModel.remainingCalories,
    onMealLogged: {
        Task { await mealsViewModel.loadTodayMeals() }
    }
)
.padding(.horizontal, 16)
```

- Pass `remainingCalories` from `MealsViewModel` to trigger proactive suggestions.
- On meal logged from suggestion → refresh today's meals list.
- Auto-fetch suggestions on `.task` modifier when view appears.
</action>

<acceptance_criteria>
- MealsView.swift contains `AISuggestionSectionView` below the meal sections
- Remaining calories passed from MealsViewModel to suggestion view
- On suggestion logged → today's meals list refreshes
- Suggestions auto-fetch when Meals tab appears via `.task` modifier
</acceptance_criteria>

## Verification

### Manual Verification
1. Build project — no compile errors.
2. Open Meals tab — AI section appears at bottom with "Đang suy nghĩ..." loading.
3. After loading, 1-2 suggestion cards appear with food name, calories, macros.
4. Verify suggested meal type matches current time (e.g., "Bữa trưa" at noon).
5. Tap "Log Ngay" on a card → success animation → meal appears in Today's Meals list above.
6. Remaining calories updates after logging.
7. Tap "Gợi ý thêm" → new suggestions load.
8. If no API key → shows guidance to add key in Profile.
9. If HealthCondition has "Gan nhiễm mỡ" with avoidFoods ["Đồ chiên"] → AI does NOT suggest fried food.
