---
phase: 13
title: "Proactive AI — Daily Summary & Memory Insights"
wave: 1
depends_on: []
files_modified:
  - LiiO_EatClean/Services/DailySummaryService.swift [NEW]
  - LiiO_EatClean/Services/InsightDetector.swift [NEW]
  - LiiO_EatClean/Features/AI/ContextBuilder.swift
  - LiiO_EatClean/Features/Home/HomeView.swift
  - LiiO_EatClean/Features/Home/HomeViewModel.swift
  - LiiO_EatClean/Features/Home/Components/DailySummaryCardView.swift [NEW]
  - LiiO_EatClean/Features/AI/ReminderService.swift
requirements:
  - DSUM-01
  - DSUM-02
  - MINS-01
  - MINS-02
autonomous: true
must_haves:
  - Daily Summary card on Home (below Streak card)
  - Smart compact/expand based on insight presence
  - Push notification at 20h with daily calorie summary
  - Pattern detection for macro deficit, skipped meals, calorie overrun, low water
  - AI-generated summary with tone adaptation (encouraging vs gentle)
---

# Plan 13: Proactive AI — Daily Summary & Memory Insights

## Overview

Build a proactive AI system that generates Daily Summaries (calories + macros + timing + AI commentary) and detects behavioral patterns (Memory Insights). Summary is displayed as a smart card on Home (compact by default, auto-expands when insights exist). Push notification at 20h reminds user to review.

---

## Task 1: Create InsightDetector Service

<read_first>
- LiiO_EatClean/Data/Repositories/MealRepository.swift
- LiiO_EatClean/Data/Protocols/MealRepositoryProtocol.swift
- LiiO_EatClean/Features/Home/HomeViewModel.swift
- LiiO_EatClean/Data/Models/UserProfileMemory.swift
</read_first>

<action>
Create `LiiO_EatClean/Services/InsightDetector.swift`:

```swift
import Foundation

struct DailyInsight: Identifiable {
    let id = UUID()
    let type: InsightType
    let message: String
    let suggestion: String
    let severity: InsightSeverity // .warning (3-day) or .alert (7-day)
    
    enum InsightType: String {
        case lowProtein = "low_protein"
        case skippedMeal = "skipped_meal"
        case calorieOverrun = "calorie_overrun"
        case lowWater = "low_water"
    }
    
    enum InsightSeverity {
        case warning  // 3-day pattern
        case alert    // 7-day pattern
    }
}

class InsightDetector {
    private let mealRepository: MealRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    
    init(mealRepository: MealRepositoryProtocol = MealRepository(),
         userRepository: UserRepositoryProtocol = UserRepository()) {
        self.mealRepository = mealRepository
        self.userRepository = userRepository
    }
    
    func detectInsights() async -> [DailyInsight]
    // Internally:
    // P1: Check protein < 30g for last 3 days (warning) / 7 days (alert)
    // P3: Check if breakfast ("Bữa sáng") missing > 50% of days in 7-day window
    // P5: Check if calories > dailyTarget for 3 consecutive days
    // P6: Check if water < 50% of waterTarget average over 7 days
    // Return max 3 insights, prioritized by severity (alert > warning)
}
```

Key implementation details:
- Use `mealRepository.fetchMeals(from:to:)` for date range queries
- Use `userRepository.fetchUser()` for dailyCalorieTarget
- Use `userRepository.fetchWaterLog(for:)` for each day in range
- Group meals by date and mealType for breakfast detection
- Calculate total protein per day from meal foods
- Sort insights: alerts first, then warnings. Cap at 3.
</action>

<acceptance_criteria>
- `InsightDetector.swift` exists at `LiiO_EatClean/Services/`
- File contains `struct DailyInsight` with `type`, `message`, `suggestion`, `severity`
- File contains `class InsightDetector` with `func detectInsights() async -> [DailyInsight]`
- `InsightType` enum has cases: `lowProtein`, `skippedMeal`, `calorieOverrun`, `lowWater`
- Uses `MealRepositoryProtocol` and `UserRepositoryProtocol` (not direct CoreData)
- Build succeeds with `xcodebuild`
</acceptance_criteria>

---

## Task 2: Create DailySummaryService

<read_first>
- LiiO_EatClean/Features/AI/ContextBuilder.swift
- LiiO_EatClean/Features/AI/AIService.swift
- LiiO_EatClean/Services/InsightDetector.swift (from Task 1)
- LiiO_EatClean/Data/Repositories/MealRepository.swift
</read_first>

<action>
Create `LiiO_EatClean/Services/DailySummaryService.swift`:

```swift
import Foundation

struct DailySummary {
    let date: Date
    let totalCalories: Double
    let targetCalories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let mealBreakdown: [String: Double] // ["Bữa sáng": 450, "Bữa trưa": 600, ...]
    let insights: [DailyInsight]
    let aiComment: String // AI-generated 2-3 sentence summary
    let aiSuggestion: String // 1 actionable suggestion for tomorrow
    let isGoalMet: Bool
}

@Observable
class DailySummaryService {
    var currentSummary: DailySummary?
    var isLoading = false
    
    private let mealRepository: MealRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    private let insightDetector: InsightDetector
    private let aiService: AIService
    
    func generateSummary(for date: Date = Date()) async
    // 1. Fetch meals for date
    // 2. Calculate totals (calories, protein, carbs, fat)
    // 3. Group by mealType for breakdown
    // 4. Run InsightDetector
    // 5. Build AI prompt with data + insights
    // 6. Call AIService for aiComment + aiSuggestion
    // 7. Set currentSummary
    
    // AI prompt should include:
    // - Calories eaten vs target
    // - Macro breakdown
    // - Meal timing
    // - Detected insights
    // - Instruction: tone positive if goal met, gentle if not
    // - Output format: JSON { "comment": "...", "suggestion": "..." }
}
```

Add new `ContextStrategy.dailySummary` case to `ContextBuilder.swift`:
- Include today's full data (calories, macros, meal breakdown)
- Include detected insights as context
- Request JSON output: `{ "comment": "...", "suggestion": "..." }`
- Tone instruction: encouraging if goal met, gentle + actionable if not
</action>

<acceptance_criteria>
- `DailySummaryService.swift` exists at `LiiO_EatClean/Services/`
- File contains `struct DailySummary` with fields: `totalCalories`, `targetCalories`, `protein`, `carbs`, `fat`, `mealBreakdown`, `insights`, `aiComment`, `aiSuggestion`, `isGoalMet`
- File contains `class DailySummaryService` with `@Observable` and `func generateSummary`
- `ContextBuilder.swift` contains new case `dailySummary` in `ContextStrategy` enum
- Build succeeds with `xcodebuild`
</acceptance_criteria>

---

## Task 3: Create DailySummaryCardView

<read_first>
- LiiO_EatClean/Features/Home/Components/StreakCardView.swift
- LiiO_EatClean/Features/Home/HomeView.swift
- LiiO_EatClean/Services/DailySummaryService.swift (from Task 2)
</read_first>

<action>
Create `LiiO_EatClean/Features/Home/Components/DailySummaryCardView.swift`:

Smart card with 2 states:

**Compact state (default, no insights):**
```
┌──────────────────────────────────┐
│ 📊  Hôm nay: 1850/2000 kcal  ✅ │
└──────────────────────────────────┘
```
- Single line, rounded corners, subtle background
- Green checkmark if goal met, orange warning if over

**Expanded state (auto when insights exist, or tap to toggle):**
```
┌──────────────────────────────────────┐
│ 📊  Hôm nay: 1850 / 2000 kcal       │
│                                      │
│  P: 45g  |  C: 250g  |  F: 60g      │
│  [progress bars for each macro]      │
│                                      │
│  ⚠️ Thiếu protein 3 ngày gần đây     │
│                                      │
│  💡 Thêm trứng vào bữa sáng          │
│                                      │
│  "Bạn đang ăn uống khá tốt..."       │
└──────────────────────────────────────┘
```

Implementation:
- `@State private var isExpanded: Bool` — toggled by tap or auto-set if `summary.insights` is not empty
- Animation: `.spring(response: 0.3, dampingFraction: 0.8)` for expand/collapse
- Style: match `StreakCardView` pattern (rounded corners, shadow, `.systemGroupedBackground`)
- Colors: green gradient for met goal, orange for over, blue accents for macros
- Macro progress bars: thin horizontal bars showing % of recommended daily intake
- Insight items: orange/red warning icon + message text
- AI comment: italic, secondary color, bottom of card
- Card should accept `DailySummary?` as binding — show skeleton/placeholder when nil
</action>

<acceptance_criteria>
- `DailySummaryCardView.swift` exists at `LiiO_EatClean/Features/Home/Components/`
- File contains `struct DailySummaryCardView: View`
- View has compact and expanded states with animation
- View auto-expands when `summary.insights` is not empty
- View displays: calories, macros, insights, AI comment
- Build succeeds with `xcodebuild`
</acceptance_criteria>

---

## Task 4: Integrate into HomeView & HomeViewModel

<read_first>
- LiiO_EatClean/Features/Home/HomeView.swift
- LiiO_EatClean/Features/Home/HomeViewModel.swift
- LiiO_EatClean/Features/Home/Components/DailySummaryCardView.swift (from Task 3)
- LiiO_EatClean/Services/DailySummaryService.swift (from Task 2)
</read_first>

<action>
**HomeViewModel.swift changes:**
- Add `var dailySummary: DailySummary?` property
- Add `private let summaryService = DailySummaryService()`
- In `loadDashboard()`, after existing loads, call:
  ```swift
  await summaryService.generateSummary()
  dailySummary = summaryService.currentSummary
  ```

**HomeView.swift changes:**
- Add `DailySummaryCardView(summary: viewModel.dailySummary)` AFTER the `StreakCardView` block (line ~44) and BEFORE `WaterCardView` (line ~47)
- Apply same padding as StreakCard: `.padding(.horizontal, 24)`
- Add transition: `.transition(.asymmetric(insertion: .slide.combined(with: .opacity), removal: .opacity))`
- Wrap in conditional: `if viewModel.dailySummary != nil || viewModel.todayMeals.count > 0`

Layout order on Home:
1. headerSection (greeting + mic)
2. CalorieRingView
3. macroBarsSection
4. StreakCardView
5. **DailySummaryCardView** ← NEW
6. WaterCardView
7. Meal sections
</action>

<acceptance_criteria>
- `HomeViewModel.swift` contains `var dailySummary: DailySummary?`
- `HomeViewModel.swift` calls `summaryService.generateSummary()` in `loadDashboard()`
- `HomeView.swift` contains `DailySummaryCardView` placed after `StreakCardView`
- Build succeeds with `xcodebuild`
- App shows Daily Summary card on Home screen when meals exist
</acceptance_criteria>

---

## Task 5: Add Push Notification for Daily Summary

<read_first>
- LiiO_EatClean/Features/AI/ReminderService.swift
- LiiO_EatClean/Features/Profile/ProfileView.swift
- LiiO_EatClean/Features/Profile/ProfileViewModel.swift
</read_first>

<action>
**ReminderService.swift changes:**
Add new method:

```swift
func scheduleDailySummaryReminder(hour: Int = 20, minute: Int = 0) async {
    // Remove old daily summary reminders
    let pending = await notificationCenter.pendingNotificationRequests()
    let summaryIDs = pending.filter { $0.identifier.hasPrefix("daily_summary_") }.map { $0.identifier }
    notificationCenter.removePendingNotificationRequests(withIdentifiers: summaryIDs)
    
    let granted = await requestPermission()
    guard granted else { return }
    
    let messages = [
        "Hôm nay bạn ăn uống thế nào? Xem tóm tắt ngày nhé! 📊",
        "Đã đến giờ review hôm nay rồi! Mở app xem Daily Summary 🎯",
        "Cùng điểm lại bữa ăn hôm nay nhé! 💪"
    ]
    
    let content = UNMutableNotificationContent()
    content.title = "LiiO EatClean"
    content.body = messages.randomElement() ?? messages[0]
    content.sound = .default
    
    var dateComponents = DateComponents()
    dateComponents.hour = hour
    dateComponents.minute = minute
    
    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
    let request = UNNotificationRequest(
        identifier: "daily_summary_\(hour)",
        content: content,
        trigger: trigger
    )
    
    try? await notificationCenter.add(request)
}
```

**Call scheduling:**
- In `ProfileViewModel` or `AppDelegate`, call `scheduleDailySummaryReminder()` when user enables reminders
- Or auto-schedule on first app launch after Phase 13 update
</action>

<acceptance_criteria>
- `ReminderService.swift` contains `func scheduleDailySummaryReminder(hour:minute:)`
- Method creates a repeating notification at 20:00
- Notification identifier starts with "daily_summary_"
- Old daily summary notifications are cleaned up before scheduling new ones
- Build succeeds with `xcodebuild`
</acceptance_criteria>

---

## Verification

```bash
xcodebuild -scheme LiiO_EatClean -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' build 2>&1 | tail -5
```

**Expected:** `BUILD SUCCEEDED`

**Manual verification:**
1. Open app → Home screen shows Daily Summary card below Streak
2. Card is compact if no insights, expanded if insights detected
3. Card shows calories vs target, macro breakdown, AI comment
4. Tap compact card → expands with animation
5. Push notification scheduled at 20:00
