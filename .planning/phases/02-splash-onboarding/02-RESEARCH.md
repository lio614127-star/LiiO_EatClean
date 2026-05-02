# Phase 2: Splash + Onboarding + Goal Setup — Research

**Gathered:** 2026-04-29
**Status:** Completed

## 1. SwiftUI Splash Screen Implementation

### Approach
SwiftUI doesn't have a built-in "splash screen" view. The standard approach is:
1. Use the native `LaunchScreen.storyboard` for the initial static splash (Apple requirement).
2. Create a custom SwiftUI view that mimics and extends it with animation.
3. Use `@State` variables to control animation phases (appear → animate → transition out).

### Animation Pattern
```swift
struct SplashView: View {
    @State private var isActive = false
    @State private var scale: CGFloat = 0.9
    @State private var opacity: Double = 0.0

    var body: some View {
        if isActive {
            ContentView() // or OnboardingView
        } else {
            VStack {
                Text("LiiO").font(.system(size: 40, weight: .bold))
                Text("EatClean").font(.system(size: 16)).foregroundColor(Color(.systemGray))
            }
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    scale = 1.0
                    opacity = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation { isActive = true }
                }
            }
        }
    }
}
```

### Key Considerations
- `DispatchQueue.main.asyncAfter` for timing the transition
- `withAnimation` block for the fade-out transition
- The splash view should be the ROOT view in `LiiO_EatCleanApp.swift`

## 2. TabView Page-Style Onboarding

### SwiftUI TabView with PageStyle
```swift
TabView(selection: $currentPage) {
    OnboardingSlide(icon: "flame.fill", title: "...", description: "...")
        .tag(0)
    OnboardingSlide(icon: "chart.bar.fill", title: "...", description: "...")
        .tag(1)
    OnboardingSlide(icon: "figure.walk", title: "...", description: "...")
        .tag(2)
}
.tabViewStyle(.page(indexDisplayMode: .always))
```

### Navigation Pattern
- "Continue" button increments `currentPage` binding
- "Skip" button sets `currentPage` to last page or triggers navigation directly
- Dots indicator comes free with `.page` style

### Transition to Goal Setup
After the last slide, the "Get Started" button navigates to the Goal Setup flow. Use `NavigationStack` with a path or simple `@State` view switching.

## 3. Multi-Step Form (Goal Setup)

### Step Navigation Pattern
Use an enum for steps and a `@State` variable:
```swift
enum SetupStep: Int, CaseIterable {
    case basicInfo = 0
    case bodyMetrics = 1
    case goalSelection = 2
}

@State private var currentStep: SetupStep = .basicInfo
```

### Progress Bar
A simple `ProgressView` or custom bar:
```swift
ProgressView(value: Double(currentStep.rawValue + 1), total: Double(SetupStep.allCases.count))
    .tint(Color("Primary"))
```

### Input Validation
- Age: 10–120 range
- Height: 100–250 cm range
- Weight: 30–300 kg range
- Name: optional, no validation needed

### Gender Segmented Control
```swift
Picker("Gender", selection: $gender) {
    Text("Nam").tag("male")
    Text("Nữ").tag("female")
}
.pickerStyle(.segmented)
```

## 4. Mifflin-St Jeor Formula

### Formula Details
```
Male:   BMR = (10 × weight_kg) + (6.25 × height_cm) − (5 × age) + 5
Female: BMR = (10 × weight_kg) + (6.25 × height_cm) − (5 × age) − 161
```

### TDEE Calculation
```
TDEE = BMR × Activity Multiplier
```
Activity multipliers:
- Sedentary (1.2)
- Light (1.375)
- **Moderate (1.55)** ← Default for v1
- Active (1.725)
- Very Active (1.9)

### Goal Adjustments
- Lose Weight: TDEE − 500 kcal
- Maintain: TDEE (no change)
- Gain Weight: TDEE + 300 kcal

### Bounds
- Minimum: 1200 kcal (enforced regardless of calculation)
- Maximum: No cap (natural range ~1500–3500 for most users)

### Swift Implementation
```swift
func calculateDailyCalories(weight: Double, height: Double, age: Double, gender: String, goal: String) -> Double {
    let bmr: Double
    if gender == "male" {
        bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5
    } else {
        bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161
    }
    
    let tdee = bmr * 1.55 // moderate activity
    
    let adjustment: Double
    switch goal {
    case "lose": adjustment = -500
    case "gain": adjustment = 300
    default: adjustment = 0 // maintain
    }
    
    return max(1200, tdee + adjustment)
}
```

## 5. Schema Update — Gender Field

The User entity from Phase 1 does NOT include a `gender` field. This must be added:
- **CoreData:** Add `gender` attribute (String, optional) to User entity in `.xcdatamodeld`
- **UserModel.swift:** Add `gender: String` property
- **UserRepository:** No changes needed (saveUser already maps all UserModel fields)

Since this is a development-phase change (no production data to migrate), we can simply update the schema XML and model directly.

## 6. App Routing Logic

### Onboarding State Management
```swift
@main
struct LiiO_EatCleanApp: App {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                SplashView(destination: .home)
            } else {
                SplashView(destination: .onboarding)
            }
        }
    }
}
```

### Key Decision
- Use `@AppStorage` (UserDefaults wrapper) for the onboarding flag — simple, persists across launches
- Splash always shows first, then routes based on the flag

## 7. Dependencies
- No external dependencies needed
- All native: SwiftUI, CoreData, Foundation

---
*Research completed successfully.*
