---
phase: 14
title: "Meal Plan Sheet UI — Daily Plan Cards"
plan: 14B
wave: 2
depends_on: [14A]
files_modified:
  - LiiO_EatClean/Features/Meals/Components/MealPlanCard.swift [NEW]
  - LiiO_EatClean/Features/Meals/Components/MealPlanSheet.swift [NEW]
  - LiiO_EatClean/Features/Meals/MealsView.swift
requirements:
  - PLAN-01
  - PLAN-02
autonomous: true
must_haves:
  - "✨ Lên kế hoạch" button in Meals tab
  - Full-screen sheet with 4 meal cards (ScrollView vertical)
  - "Log bữa này" per card with ✅ state change
  - "📋 Áp dụng toàn bộ kế hoạch" with confirm dialog
  - Auto-dismiss sheet when all meals logged
  - Haptic feedback on log actions
truths:
  - D-03: Full-screen sheet riêng (.fullScreenCover)
  - D-04: Cards xếp dọc, 2-3 món/card, CTA per card
  - D-06: Log từng bữa + "Áp dụng tất cả" with confirm
  - D-07: Source = "AI Meal Plan"
  - D-08: Card ✅ trạng thái + auto-dismiss khi log hết
---

# Plan 14B: Meal Plan Sheet UI — Daily Plan Cards

## Overview

Build the full-screen MealPlanSheet with vertical ScrollView of MealPlanCards. Entry point is "✨ Lên kế hoạch" button in MealsView. Each card shows meal foods with "Log bữa này" CTA. Bottom has "Áp dụng tất cả" with confirmation dialog. Cards transition to ✅ state after logging. Auto-dismiss when all meals logged.

---

## Task 1: Create MealPlanCard Component

<read_first>
- LiiO_EatClean/Features/Meals/Components/AISuggestionSectionView.swift
- LiiO_EatClean/Features/Home/Components/DailySummaryCardView.swift
- LiiO_EatClean/Core/Utils/HapticManager.swift
- LiiO_EatClean/Features/Meals/MealPlanViewModel.swift
</read_first>

<action>
Create `LiiO_EatClean/Features/Meals/Components/MealPlanCard.swift`:

```swift
import SwiftUI

struct MealPlanCard: View {
    let mealType: String
    let foods: [AISuggestedFood]
    let isLogged: Bool
    let onLog: () -> Void
    
    private var icon: String {
        MealPlanViewModel.mealIcons[mealType] ?? "🍽"
    }
    
    private var totalCalories: Double {
        foods.reduce(0) { $0 + $1.calories }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: icon + meal type + total kcal
            HStack {
                Text(icon)
                    .font(.title2)
                Text(mealType)
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text("\(Int(totalCalories)) kcal")
                    .font(.headline)
                    .foregroundColor(isLogged ? .gray : .green)
                
                if isLogged {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            
            // Food items list
            ForEach(foods) { food in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(food.name)
                            .font(.subheadline)
                            .foregroundColor(isLogged ? .secondary : .primary)
                        HStack(spacing: 12) {
                            MacroMini(label: "P", value: food.protein, color: .blue)
                            MacroMini(label: "C", value: food.carbs, color: .orange)
                            MacroMini(label: "F", value: food.fat, color: .pink)
                        }
                    }
                    Spacer()
                    Text("\(Int(food.calories)) kcal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            // CTA: "Log bữa này"
            if !isLogged {
                Button(action: onLog) {
                    Text("Log bữa này")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .opacity(isLogged ? 0.6 : 1.0)
        )
        .shadow(color: .black.opacity(isLogged ? 0.02 : 0.05), radius: 8, y: 4)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isLogged)
    }
}
```

This card:
- Uses `MacroMini` (already exists in `AISuggestionSectionView.swift`)
- Follows `secondarySystemGroupedBackground` + cornerRadius 16 from `DailySummaryCardView`
- Logged state: opacity 0.6 + gray text + ✅ icon + disabled CTA (D-08)
- Spring animation on state change: `.spring(response: 0.3, dampingFraction: 0.8)` from `DailySummaryCardView`
</action>

<acceptance_criteria>
- File `MealPlanCard.swift` exists in `Features/Meals/Components/`
- Card shows meal type icon, name, food list with macros, total kcal
- `isLogged == true` → opacity 0.6, ✅ icon visible, "Log bữa này" button hidden
- `isLogged == false` → full opacity, green "Log bữa này" button visible
- Uses `MacroMini` component (imported from AISuggestionSectionView's module)
- Animation uses `.spring(response: 0.3, dampingFraction: 0.8)`
</acceptance_criteria>

---

## Task 2: Create MealPlanSheet

<read_first>
- LiiO_EatClean/Features/Meals/Components/MealPlanCard.swift
- LiiO_EatClean/Features/Meals/MealPlanViewModel.swift
- LiiO_EatClean/Core/Utils/HapticManager.swift
- LiiO_EatClean/Features/Meals/MealsView.swift
</read_first>

<action>
Create `LiiO_EatClean/Features/Meals/Components/MealPlanSheet.swift`:

```swift
import SwiftUI

struct MealPlanSheet: View {
    @State private var viewModel = MealPlanViewModel()
    @Binding var isPresented: Bool
    let targetCalories: Double
    
    @State private var showConfirmDialog = false
    @State private var showWeeklyPlan = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header summary
                    if !viewModel.planItems.isEmpty {
                        VStack(spacing: 4) {
                            Text("Kế hoạch hôm nay")
                                .font(.title2.bold())
                            Text("Tổng: \(Int(viewModel.totalPlanCalories)) / \(Int(targetCalories)) kcal")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    }
                    
                    // Meal cards
                    if viewModel.isLoading {
                        VStack(spacing: 16) {
                            ProgressView("Đang tạo kế hoạch...")
                                .padding(40)
                            Text("AI đang phân tích dinh dưỡng và sở thích của bạn")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else if let error = viewModel.errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Thử lại") {
                                Task { await viewModel.generateDayPlan(targetCalories: targetCalories) }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        }
                        .padding(40)
                    } else {
                        ForEach(MealPlanViewModel.mealTypes, id: \.self) { mealType in
                            let foods = viewModel.items(for: mealType)
                            if !foods.isEmpty {
                                MealPlanCard(
                                    mealType: mealType,
                                    foods: foods,
                                    isLogged: viewModel.loggedMealTypes.contains(mealType),
                                    onLog: {
                                        Task { await viewModel.logMeal(type: mealType) }
                                    }
                                )
                            }
                        }
                        
                        // "Áp dụng tất cả" button
                        if !viewModel.planItems.isEmpty && !viewModel.allMealsLogged {
                            Button {
                                showConfirmDialog = true
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("📋 Áp dụng toàn bộ kế hoạch")
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.green)
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 8)
                        }
                        
                        // Weekly plan button
                        if !viewModel.planItems.isEmpty {
                            Button {
                                showWeeklyPlan = true
                            } label: {
                                HStack {
                                    Image(systemName: "calendar")
                                    Text("Lên kế hoạch tuần")
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.green)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") {
                        isPresented = false
                    }
                }
            }
            .confirmationDialog(
                "Bạn muốn log toàn bộ 4 bữa hôm nay?",
                isPresented: $showConfirmDialog,
                titleVisibility: .visible
            ) {
                Button("Xác nhận") {
                    Task {
                        await viewModel.logAllMeals(targetCalories: targetCalories)
                    }
                }
                Button("Huỷ", role: .cancel) {}
            }
            .sheet(isPresented: $showWeeklyPlan) {
                WeeklyPlanView(viewModel: viewModel, targetCalories: targetCalories)
            }
        }
        .task {
            await viewModel.generateDayPlan(targetCalories: targetCalories)
        }
        // Auto-dismiss when all meals logged (D-08)
        .onChange(of: viewModel.allMealsLogged) { _, allLogged in
            if allLogged {
                HapticManager.interaction()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    isPresented = false
                }
            }
        }
    }
}
```

Key behaviors:
- Auto-generates plan on appear via `.task`
- Confirmation dialog before bulk log (D-06)
- Auto-dismiss ~1s after all meals logged (D-08)
- Stronger haptic on full completion vs per-meal (D-08)
- Weekly plan accessible via bottom button, opens as nested sheet
</action>

<acceptance_criteria>
- File `MealPlanSheet.swift` exists in `Features/Meals/Components/`
- Sheet shows "Kế hoạch hôm nay" header with total kcal
- 4 `MealPlanCard` views rendered for non-empty meal types
- "📋 Áp dụng toàn bộ kế hoạch" button visible when meals exist and not all logged
- Button hidden when `allMealsLogged` is true
- Confirmation dialog shown before bulk log with "Xác nhận" / "Huỷ"
- `onChange(of: viewModel.allMealsLogged)` triggers dismiss after 1.0 seconds
- Loading state shows ProgressView
- Error state shows error message with "Thử lại" button
- "Lên kế hoạch tuần" button opens WeeklyPlanView sheet
</acceptance_criteria>

---

## Task 3: Integrate MealPlanSheet into MealsView

<read_first>
- LiiO_EatClean/Features/Meals/MealsView.swift
- LiiO_EatClean/Features/Meals/MealsViewModel.swift
</read_first>

<action>
Edit `LiiO_EatClean/Features/Meals/MealsView.swift`:

1. Add state variable for sheet presentation:
```swift
@State private var showMealPlanSheet = false
```

2. Add "✨ Lên kế hoạch" button in the toolbar or as a prominent button above the meal sections. Place it after MemorySummaryCard and before meal type sections:
```swift
// After MemorySummaryCard, before ForEach meal sections
Button {
    showMealPlanSheet = true
} label: {
    HStack {
        Image(systemName: "sparkles")
        Text("Lên kế hoạch hôm nay")
            .fontWeight(.semibold)
    }
    .foregroundColor(.white)
    .frame(maxWidth: .infinity)
    .padding(.vertical, 12)
    .background(
        LinearGradient(
            colors: [Color.green, Color.green.opacity(0.8)],
            startPoint: .leading,
            endPoint: .trailing
        )
    )
    .cornerRadius(12)
}
.buttonStyle(.plain)
.padding(.horizontal)
```

3. Add `.fullScreenCover` modifier on the outermost view container:
```swift
.fullScreenCover(isPresented: $showMealPlanSheet) {
    MealPlanSheet(
        isPresented: $showMealPlanSheet,
        targetCalories: viewModel.dailyTarget
    )
}
```

**Important:** Place the `.fullScreenCover` at the same level as the existing `.sheet(item:)` modifiers, NOT nested inside them. This avoids iOS 17 sheet presentation conflicts.
</action>

<acceptance_criteria>
- MealsView.swift contains `@State private var showMealPlanSheet = false`
- "✨ Lên kế hoạch hôm nay" button visible in Meals tab with green gradient
- Button sets `showMealPlanSheet = true`
- `.fullScreenCover(isPresented: $showMealPlanSheet)` presents `MealPlanSheet`
- `MealPlanSheet` receives `targetCalories: viewModel.dailyTarget`
- fullScreenCover modifier is NOT nested inside other .sheet modifiers
</acceptance_criteria>

---

## Verification

<verification>
1. Build project succeeds
2. Launch app → Meals tab → "✨ Lên kế hoạch hôm nay" button visible
3. Tap button → full-screen sheet opens with loading state
4. Plan loads → 4 meal cards visible with foods
5. Tap "Log bữa này" on one card → card transitions to ✅ state
6. Tap "📋 Áp dụng toàn bộ" → confirm dialog appears
7. Confirm → all cards ✅ → sheet auto-dismisses after ~1s
8. Check Meals tab → logged meals appear in correct sections
</verification>

<success_criteria>
- Full-screen meal plan sheet accessible from Meals tab
- 4 meal cards with food items, macros, and calories
- Per-meal and bulk log actions work correctly
- Card visual state changes on log (✅ + dimmed)
- Auto-dismiss with haptic when all meals logged
- Confirmation dialog prevents accidental bulk log
</success_criteria>
