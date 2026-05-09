---
wave: 1
depends_on: ["01-PLAN"]
files_modified: ["LiiO_EatClean.xcdatamodeld/LiiO_EatClean.xcdatamodel/contents", "LiiO_EatClean/Data/Models/UserModel.swift", "LiiO_EatClean/App/LiiO_EatCleanApp.swift", "LiiO_EatClean/Features/Onboarding/SplashView.swift", "LiiO_EatClean/Features/Onboarding/OnboardingView.swift", "LiiO_EatClean/Features/Onboarding/OnboardingSlide.swift", "LiiO_EatClean/Features/Onboarding/GoalSetupView.swift", "LiiO_EatClean/Features/Onboarding/Steps/*.swift", "LiiO_EatClean/Core/Utils/CalorieCalculator.swift"]
autonomous: true
---

# Phase 2: Splash + Onboarding + Goal Setup

## Objective
Build the complete first-run experience: animated splash screen → 3-slide onboarding → 3-step goal setup with inline calorie preview → save user profile → transition to Home.

## Requirements Covered
- **ONBD-01**: Splash screen with logo, auto-transition after 1-2s
- **ONBD-02**: Onboarding 3 slides with Continue + Skip
- **ONBD-03**: Setup Goal step-by-step (3 steps): weight, height, age, goal
- **ONBD-04**: Auto-calculate calories/day using Mifflin-St Jeor with min 1200 kcal
- **ONBD-05**: Progress bar on Setup Goal screens

---

## 1. Schema Update — Add Gender Field
<task>
<read_first>
- `LiiO_EatClean.xcdatamodeld/LiiO_EatClean.xcdatamodel/contents` (current schema XML)
- `LiiO_EatClean/Data/Models/UserModel.swift` (current UserModel struct)
- `.planning/phases/02-splash-onboarding/02-CONTEXT.md` (D-23: gender field requirement)
</read_first>
<action>
1. Edit `LiiO_EatClean.xcdatamodeld/LiiO_EatClean.xcdatamodel/contents`:
   Add `<attribute name="gender" optional="YES" attributeType="String"/>` inside the `<entity name="User">` block.

2. Edit `LiiO_EatClean/Data/Models/UserModel.swift`:
   Add `var gender: String` property with default value `"male"`.
   Update the init to include `gender` parameter.

3. Edit `LiiO_EatClean/Data/Repositories/UserRepository.swift`:
   Add `coreDataUser.gender = user.gender` in saveUser().
   Add `gender: user.gender ?? "male"` in fetchUser() mapping.
</action>
<acceptance_criteria>
- `contents` XML contains `<attribute name="gender" optional="YES" attributeType="String"/>` inside User entity
- `UserModel.swift` contains `var gender: String`
- `UserRepository.swift` contains `coreDataUser.gender = user.gender`
</acceptance_criteria>
</task>

## 2. Calorie Calculator Utility
<task>
<read_first>
- `.planning/phases/02-splash-onboarding/02-CONTEXT.md` (D-17: Mifflin-St Jeor formula details)
- `.planning/phases/02-splash-onboarding/02-RESEARCH.md` (Section 4: formula implementation)
</read_first>
<action>
Create `LiiO_EatClean/Core/Utils/CalorieCalculator.swift`:

```swift
struct CalorieCalculator {
    static func calculateDailyCalories(
        weight: Double,   // kg
        height: Double,   // cm
        age: Double,
        gender: String,   // "male" or "female"
        goal: String      // "lose", "maintain", "gain"
    ) -> Double {
        let bmr: Double
        if gender == "male" {
            bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5
        } else {
            bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161
        }
        let tdee = bmr * 1.55
        let adjustment: Double
        switch goal {
        case "lose": adjustment = -500
        case "gain": adjustment = 300
        default: adjustment = 0
        }
        return max(1200, tdee + adjustment)
    }
}
```
</action>
<acceptance_criteria>
- `CalorieCalculator.swift` exists at `LiiO_EatClean/Core/Utils/`
- Contains `static func calculateDailyCalories` with 5 parameters
- Contains `max(1200,` enforcing minimum bound
- Male formula: `(10 * weight) + (6.25 * height) - (5 * age) + 5`
- Female formula: `(10 * weight) + (6.25 * height) - (5 * age) - 161`
</acceptance_criteria>
</task>

## 3. Splash Screen View
<task>
<read_first>
- `.planning/phases/02-splash-onboarding/02-CONTEXT.md` (D-01 through D-05: splash decisions)
</read_first>
<action>
Create `LiiO_EatClean/Features/Onboarding/SplashView.swift`:

- VStack centered: "LiiO" (SF Pro Bold, 40pt, Primary color) + "EatClean" (SF Pro Regular, 16pt, Color(.systemGray))
- Background: LinearGradient from Color("Primary").opacity(0.1) to .white
- @State scale starts at 0.9, animates to 1.0 with .easeOut(duration: 1.0)
- @State opacity starts at 0.0, animates to 1.0
- After 2 seconds: transition to next view (onboarding or home based on `hasCompletedOnboarding`)
- Use @AppStorage("hasCompletedOnboarding") to check routing
</action>
<acceptance_criteria>
- `SplashView.swift` contains `.scaleEffect(scale)` and `.opacity(opacity)`
- Contains `@AppStorage("hasCompletedOnboarding")`
- Contains `.easeOut` animation
- Contains `DispatchQueue.main.asyncAfter` with 2.0 second delay
</acceptance_criteria>
</task>

## 4. Onboarding Slides
<task>
<read_first>
- `.planning/phases/02-splash-onboarding/02-CONTEXT.md` (D-06 through D-11: onboarding decisions)
</read_first>
<action>
Create `LiiO_EatClean/Features/Onboarding/OnboardingSlide.swift`:
- Reusable slide component: Image(systemName:) at 80pt + title (Bold, 24pt) + description (Regular, secondary color)

Create `LiiO_EatClean/Features/Onboarding/OnboardingView.swift`:
- TabView with `.tabViewStyle(.page(indexDisplayMode: .always))` and 3 slides:
  - Slide 1: icon "flame.fill", title "Theo dõi Calories", desc "Log bữa ăn nhanh chóng, chính xác mỗi ngày"
  - Slide 2: icon "chart.bar.fill", title "Xem tiến trình", desc "Biểu đồ trực quan giúp bạn theo dõi mục tiêu"
  - Slide 3: icon "figure.walk", title "Đạt body mong muốn", desc "Thiết lập mục tiêu cá nhân và bắt đầu ngay"
- @State currentPage binding for TabView selection
- "Skip" button at top-right (navigates to GoalSetupView)
- "Continue" button at bottom: if last page → navigate to GoalSetupView, else increment currentPage
</action>
<acceptance_criteria>
- `OnboardingSlide.swift` contains `Image(systemName:` with `.font(.system(size: 80))`
- `OnboardingView.swift` contains `.tabViewStyle(.page`
- Contains `"flame.fill"`, `"chart.bar.fill"`, `"figure.walk"`
- Contains Vietnamese text "Theo dõi Calories"
</acceptance_criteria>
</task>

## 5. Goal Setup — 3-Step Form
<task>
<read_first>
- `.planning/phases/02-splash-onboarding/02-CONTEXT.md` (D-12 through D-20: goal setup decisions)
- `LiiO_EatClean/Data/Models/UserModel.swift` (UserModel struct)
- `LiiO_EatClean/Data/Repositories/UserRepository.swift` (saveUser method)
</read_first>
<action>
Create `LiiO_EatClean/Features/Onboarding/GoalSetupView.swift`:
- Enum `SetupStep: Int, CaseIterable { case basicInfo, bodyMetrics, goalSelection }`
- @State currentStep tracks progress
- ProgressView at top showing step/total
- Switch on currentStep to display the correct step view
- "Next" / "Back" buttons, "Next" disabled if required fields empty
- On final step completion: calculate calories, save user, set hasCompletedOnboarding = true

Create `LiiO_EatClean/Features/Onboarding/Steps/BasicInfoStepView.swift`:
- Name TextField (optional), Age TextField (numeric keyboard), Gender Picker (segmented: Nam/Nữ)

Create `LiiO_EatClean/Features/Onboarding/Steps/BodyMetricsStepView.swift`:
- Height TextField + Stepper (cm), Weight TextField + Stepper (kg)
- Numeric keyboard, auto-focus height field

Create `LiiO_EatClean/Features/Onboarding/Steps/GoalSelectionStepView.swift`:
- 3 goal cards: "Giảm cân", "Giữ cân", "Tăng cân"
- Selected card: Primary color border + light background
- Inline calorie preview below cards: "🔥 Your daily calories" + large number (Bold, 36pt)
- Number animates (fade) when switching goals
- "Based on your profile & goal" subtitle text
- "Get Started" button instead of "Next"
</action>
<acceptance_criteria>
- `GoalSetupView.swift` contains `enum SetupStep` with 3 cases
- `GoalSetupView.swift` contains `ProgressView(value:`
- `BasicInfoStepView.swift` contains `.pickerStyle(.segmented)`
- `BodyMetricsStepView.swift` contains `Stepper`
- `GoalSelectionStepView.swift` contains `CalorieCalculator.calculateDailyCalories`
- `GoalSelectionStepView.swift` contains text "Your daily calories"
</acceptance_criteria>
</task>

## 6. App Routing Update
<task>
<read_first>
- `LiiO_EatClean/App/LiiO_EatCleanApp.swift` (current @main entry point)
- `LiiO_EatClean/App/ContentView.swift` (existing TabView)
</read_first>
<action>
Update `LiiO_EatClean/App/LiiO_EatCleanApp.swift`:
- Replace direct ContentView() with SplashView()
- SplashView handles routing: onboarding flag false → OnboardingView, true → ContentView
- Ensure PersistenceController environment is still injected

The routing chain:
LiiO_EatCleanApp → SplashView → (OnboardingView → GoalSetupView → ContentView) OR (ContentView)
</action>
<acceptance_criteria>
- `LiiO_EatCleanApp.swift` contains `SplashView()` instead of `ContentView()`
- `SplashView.swift` references both `OnboardingView` and `ContentView`
</acceptance_criteria>
</task>

---
## Verification Criteria
- All new `.swift` files exist in the correct directories
- Grep confirms `CalorieCalculator.calculateDailyCalories` is called from GoalSelectionStepView
- Grep confirms `@AppStorage("hasCompletedOnboarding")` exists in SplashView
- Grep confirms `UserRepository` is used in GoalSetupView to save user data
- CoreData schema XML contains `gender` attribute in User entity
