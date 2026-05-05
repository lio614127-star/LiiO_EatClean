---
phase: 14
title: "AI Context Strategy + Calorie Validator"
plan: 14A
wave: 1
depends_on: []
files_modified:
  - LiiO_EatClean/Features/AI/ContextBuilder.swift
  - LiiO_EatClean/Features/Meals/MealPlanViewModel.swift [NEW]
requirements:
  - PLAN-01
autonomous: true
must_haves:
  - ContextBuilder has .mealPlan strategy case
  - Adaptive context injection (base + conditional history/insights)
  - MealPlanViewModel generates day plan via AIService
  - Calorie validation trims to ±5% of target
  - mealType normalizer handles Vietnamese variants
truths:
  - D-09: Adaptive context — base (kcal + memory) always, history IF ≥3 days, insights IF detected
  - D-10: Flat array + mealType, reuse AISuggestedFood, action = "meal_plan"
  - D-02: AI allocates + app validates ±5%, trim snack → dinner
  - D-11: Vietnamese mealType matching in prompt
---

# Plan 14A: AI Context Strategy + Calorie Validator

## Overview

Add `.mealPlan` strategy to ContextBuilder for full-day plan generation (4 meals). Create `MealPlanViewModel` with adaptive prompt building, AIService integration, calorie validation, and mealType normalization. This plan creates the entire backend/logic layer — no UI.

---

## Task 1: Add `.mealPlan` Strategy to ContextBuilder

<read_first>
- LiiO_EatClean/Features/AI/ContextBuilder.swift
- LiiO_EatClean/Data/Models/UserProfileMemory.swift
- LiiO_EatClean/Services/InsightDetector.swift
- LiiO_EatClean/Services/MemoryManager.swift
</read_first>

<action>
Edit `LiiO_EatClean/Features/AI/ContextBuilder.swift`:

1. Add `.mealPlan` case to `ContextStrategy` enum (after `.dailySummary`):
```swift
case mealPlan
```

2. In `buildSystemPrompt(for:strategy:remainingCalories:mealType:)`, add case handling in the switch:
```swift
case .mealPlan:
    return try await buildMealPlanContext(remainingCalories: remainingCalories ?? 2000)
```

3. Add new method `buildMealPlanContext(remainingCalories:)`:
```swift
private func buildMealPlanContext(remainingCalories: Double) async throws -> String {
    let memory = try await memoryManager.getMemory()
    let targetCalories = remainingCalories
    
    // Base context (always included)
    var prompt = """
    Bạn là chuyên gia dinh dưỡng chuyên về ẩm thực Việt Nam.
    Hãy lên thực đơn 1 ngày gồm 4 bữa với tổng khoảng \(Int(targetCalories)) kcal.
    
    Phân bổ gợi ý:
    - Bữa sáng: ~\(Int(targetCalories * 0.25)) kcal (25%)
    - Bữa trưa: ~\(Int(targetCalories * 0.35)) kcal (35%)
    - Bữa tối: ~\(Int(targetCalories * 0.30)) kcal (30%)
    - Ăn vặt: ~\(Int(targetCalories * 0.10)) kcal (10%)
    
    """
    
    // Memory injection (always if available)
    if memory.hasContent {
        if !memory.allAvoidFoods.isEmpty {
            prompt += "\n⛔ CẤM — không được gợi ý: \(memory.allAvoidFoods.joined(separator: ", "))"
        }
        if !memory.dislikes.isEmpty {
            prompt += "\nKhông thích: \(memory.dislikes.joined(separator: ", "))"
        }
        if !memory.likes.isEmpty {
            prompt += "\nƯa thích: \(memory.likes.joined(separator: ", "))"
        }
        if !memory.healthConditions.isEmpty {
            let conditions = memory.healthConditions.map { "\($0.name): \($0.dietaryNotes)" }.joined(separator: "; ")
            prompt += "\nTình trạng sức khoẻ: \(conditions)"
        }
    }
    
    // Conditional: History (only if ≥3 days of data)
    let calendar = Calendar.current
    let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: Date()) ?? Date()
    let recentMeals = try await mealRepository.fetchMeals(from: threeDaysAgo, to: Date())
    
    if recentMeals.count >= 3 {
        let recentFoodNames = Array(Set(recentMeals.flatMap { $0.mealFoods }.compactMap { $0.foodItem?.name })).prefix(5)
        if !recentFoodNames.isEmpty {
            prompt += "\n\nMón đã ăn gần đây (tránh lặp): \(recentFoodNames.joined(separator: ", "))"
        }
    }
    
    // Conditional: Insights (only if patterns detected)
    let insightDetector = InsightDetector()
    let insights = await insightDetector.detectInsights()
    if !insights.isEmpty {
        let insightTexts = insights.prefix(2).map { "- \($0.message)" }.joined(separator: "\n")
        prompt += "\n\nNhận xét dinh dưỡng gần đây:\n\(insightTexts)\nHãy điều chỉnh thực đơn để khắc phục các vấn đề trên."
    }
    
    // Output format
    prompt += """
    
    
    Trả về JSON duy nhất, KHÔNG có text ngoài JSON:
    {"action":"meal_plan","items":[{"name":"Tên món","calories":400,"protein":25,"carbs":50,"fat":10,"servingSize":1.0,"mealType":"Bữa sáng"}]}
    
    Mỗi item PHẢI có mealType là 1 trong: "Bữa sáng", "Bữa trưa", "Bữa tối", "Ăn vặt".
    Mỗi bữa nên có 2-3 món. servingSize luôn = 1.0.
    """
    
    return prompt
}
```

**Note:** This method follows the exact same pattern as `buildMealSuggestionContext()` — it uses the same `memoryManager`, `mealRepository`, and prompt formatting conventions.
</action>

<acceptance_criteria>
- ContextBuilder.swift contains `case mealPlan` in ContextStrategy enum
- ContextBuilder.swift contains `func buildMealPlanContext(remainingCalories:)`
- Method injects memory data when `memory.hasContent` is true
- Method conditionally injects history when `recentMeals.count >= 3`
- Method conditionally injects insights when `insights.isEmpty` is false
- Prompt ends with JSON format instruction containing `"action":"meal_plan"`
- Prompt specifies mealType values as "Bữa sáng", "Bữa trưa", "Bữa tối", "Ăn vặt"
</acceptance_criteria>

---

## Task 2: Create MealPlanViewModel

<read_first>
- LiiO_EatClean/Features/Meals/MealSuggestionViewModel.swift
- LiiO_EatClean/Features/AI/AIService.swift
- LiiO_EatClean/Data/Repositories/MealRepository.swift
- LiiO_EatClean/Features/AI/ContextBuilder.swift
- LiiO_EatClean/Data/Models/MealModel.swift
- LiiO_EatClean/Data/Models/MealFoodModel.swift
</read_first>

<action>
Create `LiiO_EatClean/Features/Meals/MealPlanViewModel.swift`:

```swift
import Foundation
import SwiftUI

@Observable
class MealPlanViewModel {
    // Plan state
    var planItems: [AISuggestedFood] = []
    var isLoading = false
    var errorMessage: String?
    var loggedMealTypes: Set<String> = []
    var showLogSuccess = false
    
    // Weekly plan state
    var weeklyPlan: [WeeklyDayPlan] = []
    var isLoadingWeekly = false
    var selectedWeekDay: Int? = nil
    
    private let aiService = AIService.shared
    private let contextBuilder = ContextBuilder()
    private let mealRepository: MealRepositoryProtocol
    private let memoryManager: MemoryManagerProtocol
    
    // Canonical Vietnamese meal types
    static let mealTypes = ["Bữa sáng", "Bữa trưa", "Bữa tối", "Ăn vặt"]
    static let mealIcons: [String: String] = [
        "Bữa sáng": "🌅",
        "Bữa trưa": "🌤",
        "Bữa tối": "🌙",
        "Ăn vặt": "🍎"
    ]
    
    init(mealRepository: MealRepositoryProtocol = MealRepository(),
         memoryManager: MemoryManagerProtocol = MemoryManager.shared) {
        self.mealRepository = mealRepository
        self.memoryManager = memoryManager
    }
    
    // MARK: - Day Plan Generation
    
    func generateDayPlan(targetCalories: Double) async {
        guard !isLoading else { return }
        
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
            self.planItems = []
            self.loggedMealTypes = []
        }
        
        do {
            let prompt = try await contextBuilder.buildSystemPrompt(
                for: "Lên kế hoạch ăn",
                strategy: .mealPlan,
                remainingCalories: targetCalories,
                mealType: nil
            )
            
            let message = try await aiService.sendChatMessage(history: [], systemPrompt: prompt)
            
            await MainActor.run {
                if let foods = message.suggestedFoods, !foods.isEmpty {
                    // Normalize mealTypes and validate calories
                    var normalized = foods.map { food -> AISuggestedFood in
                        var f = food
                        f.mealType = Self.normalizeMealType(f.mealType ?? "Ăn vặt")
                        return f
                    }
                    
                    // Validate total calories
                    normalized = Self.validateCalories(items: normalized, target: targetCalories)
                    
                    self.planItems = normalized
                } else {
                    self.errorMessage = "AI không thể tạo kế hoạch lúc này. Hãy thử lại."
                }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Lỗi kết nối AI: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Calorie Validation (D-02)
    
    static func validateCalories(items: [AISuggestedFood], target: Double) -> [AISuggestedFood] {
        let total = items.reduce(0) { $0 + $1.calories }
        let upperBound = target * 1.05
        
        guard total > upperBound else { return items }
        
        // Proportional trim
        let ratio = target / total
        return items.map { item in
            var f = item
            f.calories = round(item.calories * ratio)
            f.protein = round(item.protein * ratio * 10) / 10
            f.carbs = round(item.carbs * ratio * 10) / 10
            f.fat = round(item.fat * ratio * 10) / 10
            return f
        }
    }
    
    // MARK: - MealType Normalizer (D-11)
    
    static func normalizeMealType(_ raw: String) -> String {
        let lower = raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        if lower.contains("sáng") || lower.contains("breakfast") || lower.contains("morning") {
            return "Bữa sáng"
        }
        if lower.contains("trưa") || lower.contains("lunch") || lower.contains("noon") {
            return "Bữa trưa"
        }
        if lower.contains("tối") || lower.contains("dinner") || lower.contains("evening") {
            return "Bữa tối"
        }
        if lower.contains("vặt") || lower.contains("snack") || lower.contains("phụ") {
            return "Ăn vặt"
        }
        
        return "Ăn vặt" // fallback
    }
    
    // MARK: - Grouped items by meal type
    
    func items(for mealType: String) -> [AISuggestedFood] {
        planItems.filter { ($0.mealType ?? "Ăn vặt") == mealType }
    }
    
    func totalCalories(for mealType: String) -> Double {
        items(for: mealType).reduce(0) { $0 + $1.calories }
    }
    
    var totalPlanCalories: Double {
        planItems.reduce(0) { $0 + $1.calories }
    }
    
    var allMealsLogged: Bool {
        let typesWithItems = Set(planItems.compactMap { $0.mealType })
        return !typesWithItems.isEmpty && typesWithItems.isSubset(of: loggedMealTypes)
    }
    
    // MARK: - Log Actions (D-06, D-07, D-08)
    
    func logMeal(type mealType: String) async {
        let mealFoods = items(for: mealType)
        guard !mealFoods.isEmpty else { return }
        
        do {
            let foodModels = mealFoods.map { food -> MealFoodModel in
                let foodItem = FoodItemModel(
                    name: food.name,
                    calories: food.calories,
                    protein: food.protein,
                    carbs: food.carbs,
                    fat: food.fat,
                    servingSize: food.servingSize,
                    source: "AI Meal Plan"
                )
                return MealFoodModel(
                    quantity: food.servingSize,
                    caloriesSnapshot: food.calories,
                    proteinSnapshot: food.protein,
                    carbsSnapshot: food.carbs,
                    fatSnapshot: food.fat,
                    isEaten: true,
                    mealType: mealType,
                    foodItem: foodItem
                )
            }
            
            let meal = MealModel(
                date: Date(),
                mealType: mealType,
                mealFoods: foodModels
            )
            
            try await mealRepository.saveMeal(meal, for: Date())
            
            await MainActor.run {
                self.loggedMealTypes.insert(mealType)
                HapticManager.success()
            }
        } catch {
            print("Error logging meal plan: \(error)")
        }
    }
    
    func logAllMeals(targetCalories: Double) async {
        let typesWithItems = Set(planItems.compactMap { $0.mealType })
        for mealType in typesWithItems where !loggedMealTypes.contains(mealType) {
            await logMeal(type: mealType)
        }
        
        await MainActor.run {
            HapticManager.interaction()
        }
    }
    
    // MARK: - Weekly Plan (D-01, D-05)
    
    func generateWeekPlan(targetCalories: Double) async {
        guard !isLoadingWeekly else { return }
        
        await MainActor.run {
            self.isLoadingWeekly = true
            self.weeklyPlan = []
        }
        
        do {
            let memory = try await memoryManager.getMemory()
            
            var prompt = """
            Bạn là chuyên gia dinh dưỡng Việt Nam.
            Lên thực đơn 7 NGÀY, mỗi ngày 4 bữa, tổng mỗi ngày ~\(Int(targetCalories)) kcal.
            Đa dạng món, không lặp quá 2 lần trong tuần.
            """
            
            if memory.hasContent {
                if !memory.allAvoidFoods.isEmpty {
                    prompt += "\n⛔ CẤM: \(memory.allAvoidFoods.joined(separator: ", "))"
                }
                if !memory.likes.isEmpty {
                    prompt += "\nƯa thích: \(memory.likes.joined(separator: ", "))"
                }
            }
            
            prompt += """
            
            
            Trả JSON: {"action":"weekly_plan","days":[
            {"day":"T2","totalCalories":1800,"highlights":["Phở bò","Cơm gà","Cá hấp"],"items":[{...}]},
            ...
            ]}
            
            Mỗi item: {name,calories,protein,carbs,fat,servingSize:1.0,mealType:"Bữa sáng|Bữa trưa|Bữa tối|Ăn vặt"}
            Mỗi bữa 1-2 món. highlights là 3 món tiêu biểu nhất mỗi ngày.
            """
            
            let message = try await aiService.sendChatMessage(history: [], systemPrompt: prompt)
            
            await MainActor.run {
                if let text = message.content {
                    self.weeklyPlan = Self.parseWeeklyPlan(text, target: targetCalories)
                }
                if self.weeklyPlan.isEmpty {
                    // Fallback: empty state
                }
                self.isLoadingWeekly = false
            }
        } catch {
            await MainActor.run {
                self.isLoadingWeekly = false
            }
        }
    }
    
    static func parseWeeklyPlan(_ text: String, target: Double) -> [WeeklyDayPlan] {
        // Extract JSON from response
        guard let jsonStart = text.firstIndex(of: "{"),
              let jsonEnd = text.lastIndex(of: "}") else { return [] }
        
        let jsonString = String(text[jsonStart...jsonEnd])
        guard let data = jsonString.data(using: .utf8) else { return [] }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let days = json["days"] as? [[String: Any]] {
                return days.compactMap { dayDict -> WeeklyDayPlan? in
                    guard let day = dayDict["day"] as? String else { return nil }
                    let totalCal = dayDict["totalCalories"] as? Double ?? 0
                    let highlights = dayDict["highlights"] as? [String] ?? []
                    
                    // Parse items if present
                    var items: [AISuggestedFood] = []
                    if let itemsArray = dayDict["items"] as? [[String: Any]] {
                        items = itemsArray.compactMap { itemDict -> AISuggestedFood? in
                            guard let name = itemDict["name"] as? String else { return nil }
                            return AISuggestedFood(
                                name: name,
                                calories: itemDict["calories"] as? Double ?? 0,
                                protein: itemDict["protein"] as? Double ?? 0,
                                carbs: itemDict["carbs"] as? Double ?? 0,
                                fat: itemDict["fat"] as? Double ?? 0,
                                servingSize: 1.0,
                                mealType: normalizeMealType(itemDict["mealType"] as? String ?? "Ăn vặt")
                            )
                        }
                    }
                    
                    return WeeklyDayPlan(
                        day: day,
                        totalCalories: totalCal,
                        highlights: highlights,
                        items: items
                    )
                }
            }
        } catch {
            print("Weekly plan parse error: \(error)")
        }
        return []
    }
}

// MARK: - Weekly Plan Model

struct WeeklyDayPlan: Identifiable {
    let id = UUID()
    let day: String          // "T2", "T3", etc.
    let totalCalories: Double
    let highlights: [String] // 2-3 representative food names
    let items: [AISuggestedFood]
}
```

Key implementation details:
- `source: "AI Meal Plan"` marks logged meals from planning (D-07)
- `loggedMealTypes: Set<String>` tracks which meals are logged (D-08)
- `validateCalories()` proportionally trims all items when total > 105% target (D-02)
- `normalizeMealType()` maps any AI variation to canonical Vietnamese names (D-11)
- `allMealsLogged` computed property triggers auto-dismiss logic in UI (D-08)
</action>

<acceptance_criteria>
- File `MealPlanViewModel.swift` exists in `Features/Meals/`
- Class uses `@Observable` macro (not ObservableObject)
- `generateDayPlan()` calls `ContextBuilder(.mealPlan)` then `AIService.sendChatMessage()`
- `validateCalories()` returns items where total ≤ target * 1.05
- `normalizeMealType("sáng")` returns "Bữa sáng"
- `normalizeMealType("breakfast")` returns "Bữa sáng"
- `normalizeMealType("Bữa trưa")` returns "Bữa trưa"
- `logMeal(type:)` saves to MealRepository with `source: "AI Meal Plan"`
- `loggedMealTypes` is updated after successful log
- `allMealsLogged` returns true when all meal types with items are logged
- `WeeklyDayPlan` struct exists with `day`, `totalCalories`, `highlights`, `items`
</acceptance_criteria>

---

## Verification

<verification>
1. Build project: `xcodebuild build -scheme LiiO_EatClean -destination 'platform=iOS Simulator,name=iPhone 16'` succeeds
2. ContextBuilder.swift contains `case mealPlan`
3. MealPlanViewModel.swift exists and uses `@Observable`
4. `normalizeMealType` handles all 4 canonical types plus English variants
5. `validateCalories` trims correctly when total exceeds 105%
</verification>

<success_criteria>
- ContextBuilder extended with `.mealPlan` strategy using adaptive context injection
- MealPlanViewModel can generate daily and weekly plans
- Calorie validation ensures plan stays within ±5% of target
- MealType normalizer handles all known Vietnamese and English variants
- All logged meals marked with source "AI Meal Plan"
</success_criteria>
