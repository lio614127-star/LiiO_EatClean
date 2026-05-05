---
phase: 14
title: "Weekly Plan View + Polish"
plan: 14C
wave: 2
depends_on: [14A]
files_modified:
  - LiiO_EatClean/Features/Meals/Components/WeeklyPlanView.swift [NEW]
requirements:
  - PLAN-01
autonomous: true
must_haves:
  - Weekly plan list with 7 compact rows (T2-CN)
  - Each row shows day + total kcal + 2-3 highlight foods
  - Tap row opens day detail (reuses MealPlanSheet cards layout)
truths:
  - D-01: Kế hoạch tuần = optional, accessible via button
  - D-05: Weekly = list compact 7 dòng, tap → detail
---

# Plan 14C: Weekly Plan View + Polish

## Overview

Build WeeklyPlanView — a list of 7 compact day rows showing overview (day name, total kcal, 2-3 highlight foods). User taps a row to see full day detail. Weekly plan is generated via MealPlanViewModel.generateWeekPlan() from Plan 14A.

---

## Task 1: Create WeeklyPlanView

<read_first>
- LiiO_EatClean/Features/Meals/MealPlanViewModel.swift
- LiiO_EatClean/Features/Meals/Components/MealPlanCard.swift
- LiiO_EatClean/Features/Meals/Components/MealPlanSheet.swift
</read_first>

<action>
Create `LiiO_EatClean/Features/Meals/Components/WeeklyPlanView.swift`:

```swift
import SwiftUI

struct WeeklyPlanView: View {
    @Bindable var viewModel: MealPlanViewModel
    let targetCalories: Double
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedDay: WeeklyDayPlan?
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoadingWeekly {
                    VStack(spacing: 16) {
                        ProgressView("Đang tạo kế hoạch tuần...")
                            .padding(40)
                        Text("AI đang phân bổ dinh dưỡng cho 7 ngày")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.weeklyPlan.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("Chưa có kế hoạch tuần")
                            .font(.headline)
                        Text("Nhấn nút bên dưới để tạo")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button {
                            Task { await viewModel.generateWeekPlan(targetCalories: targetCalories) }
                        } label: {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("Tạo kế hoạch tuần")
                            }
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.green)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            // Header
                            VStack(spacing: 4) {
                                Text("Kế hoạch tuần")
                                    .font(.title2.bold())
                                Text("Nhấn vào ngày để xem chi tiết")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 8)
                            .padding(.bottom, 4)
                            
                            // 7 day rows
                            ForEach(viewModel.weeklyPlan) { dayPlan in
                                WeeklyDayRow(dayPlan: dayPlan)
                                    .onTapGesture {
                                        selectedDay = dayPlan
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") { dismiss() }
                }
            }
            .sheet(item: $selectedDay) { dayPlan in
                WeeklyDayDetailView(dayPlan: dayPlan, targetCalories: targetCalories)
            }
        }
        .task {
            if viewModel.weeklyPlan.isEmpty {
                await viewModel.generateWeekPlan(targetCalories: targetCalories)
            }
        }
    }
}

// MARK: - Weekly Day Row (compact, D-05)

struct WeeklyDayRow: View {
    let dayPlan: WeeklyDayPlan
    
    var body: some View {
        HStack {
            // Day label
            Text(dayPlan.day)
                .font(.headline)
                .foregroundColor(.green)
                .frame(width: 30, alignment: .leading)
            
            // Separator
            Text("—")
                .foregroundColor(.secondary)
            
            // Total kcal
            Text("\(Int(dayPlan.totalCalories)) kcal")
                .font(.subheadline.bold())
                .frame(width: 80, alignment: .leading)
            
            // Highlight foods
            Text(dayPlan.highlights.joined(separator: " • "))
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Day Detail View (reuses MealPlanCard pattern)

struct WeeklyDayDetailView: View {
    let dayPlan: WeeklyDayPlan
    let targetCalories: Double
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 4) {
                        Text("Thực đơn \(dayPlan.day)")
                            .font(.title2.bold())
                        Text("Tổng: \(Int(dayPlan.totalCalories)) kcal")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                    
                    // Cards per meal type (view-only, no log action for weekly preview)
                    ForEach(MealPlanViewModel.mealTypes, id: \.self) { mealType in
                        let foods = dayPlan.items.filter { ($0.mealType ?? "Ăn vặt") == mealType }
                        if !foods.isEmpty {
                            MealPlanCard(
                                mealType: mealType,
                                foods: foods,
                                isLogged: false,
                                onLog: {} // No-op for weekly preview
                            )
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") { dismiss() }
                }
            }
        }
    }
}
```

Design decisions:
- `WeeklyDayRow` follows D-05: `T2 — 1850 kcal — Phở bò • Cơm gà • Salad` format
- `WeeklyDayDetailView` reuses `MealPlanCard` (from 14B) in view-only mode (no log actions for future days)
- Uses `.sheet(item:)` for day detail to follow established presentation pattern
- Auto-generates plan on appear if empty
</action>

<acceptance_criteria>
- File `WeeklyPlanView.swift` exists in `Features/Meals/Components/`
- 7 `WeeklyDayRow` views rendered when plan is loaded
- Each row shows: day label (T2-CN) + total kcal + highlight foods joined by " • "
- Tap on row sets `selectedDay` which opens `WeeklyDayDetailView` via `.sheet(item:)`
- `WeeklyDayDetailView` shows `MealPlanCard` for each meal type (view-only, no log)
- Loading state shows ProgressView
- Empty state shows "Tạo kế hoạch tuần" button
- `WeeklyDayPlan` conforms to `Identifiable` (required for `.sheet(item:)`)
</acceptance_criteria>

---

## Verification

<verification>
1. Build project succeeds
2. Open Meals tab → "✨ Lên kế hoạch" → plan loads → tap "Lên kế hoạch tuần"
3. Weekly view loads → 7 rows visible with day + kcal + highlights
4. Tap a row → day detail sheet opens with meal cards
5. Day detail shows food items in MealPlanCard format
6. Close day detail → back to weekly list
</verification>

<success_criteria>
- Weekly plan generates and displays 7 day rows
- Compact row format: "T2 — 1850 kcal — Phở bò • Cơm gà • Salad"
- Tap row opens day detail with reused MealPlanCard
- Loading and empty states handled gracefully
</success_criteria>
