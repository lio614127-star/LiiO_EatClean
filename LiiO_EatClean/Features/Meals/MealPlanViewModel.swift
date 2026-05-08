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
    var weeklyErrorMessage: String?
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
        
        let mealTypes = Self.mealTypes
        
        do {
            let userContext = try await contextBuilder.buildFullUserContext()
            let rawFoods = try await AIOrchestrator.shared.generateDayPlanBatched(
                mealTypes: mealTypes,
                userContext: userContext,
                targetCalories: targetCalories
            ) { partialFoods in
                // ⚡ Streaming update: Normalize and show immediately
                let normalized = partialFoods.map { food in
                    var f = food
                    f.mealType = Self.normalizeMealType(f.mealType ?? "Ăn vặt")
                    return f
                }
                Task { @MainActor in
                    self.planItems.append(contentsOf: normalized)
                    HapticManager.interaction() // Gentle feedback per chunk
                }
            }
            
            // Final pass: Normalize all for final validation
            let allFoods = rawFoods.map { food in
                var f = food
                f.mealType = Self.normalizeMealType(f.mealType ?? "Ăn vặt")
                return f
            }
            
            await MainActor.run {
                if !allFoods.isEmpty {
                    // Validate total calories (D-02: ±5%)
                    self.planItems = Self.validateCalories(items: allFoods, target: targetCalories)
                } else {
                    self.errorMessage = "AI không thể tạo kế hoạch lúc này. Hãy thử lại."
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Lỗi kết nối AI: \(error.localizedDescription)"
            }
        }
        
        await MainActor.run {
            self.isLoading = false
        }
    }
    
    // MARK: - Calorie Validation (Soft Constraints: ±15% tolerance)
    
    static func validateCalories(items: [AISuggestedFood], target: Double) -> [AISuggestedFood] {
        let total = items.reduce(0) { $0 + $1.calories }
        let upperBound = target * 1.15
        let lowerBound = target * 0.85
        
        // Only trim/scale if it's wildly off (outside ±15% tolerance)
        guard total > upperBound || total < lowerBound else { return items }
        
        // Proportional rescale — create new items with scaled values
        let ratio = target / total
        return items.map { item in
            AISuggestedFood(
                name: item.name,
                calories: round(item.calories * ratio),
                protein: round(item.protein * ratio * 10) / 10,
                carbs: round(item.carbs * ratio * 10) / 10,
                fat: round(item.fat * ratio * 10) / 10,
                servingSize: item.servingSize,
                mealType: item.mealType
            )
        }
    }
    
    // MARK: - MealType Normalizer (D-11: map AI variants to canonical Vietnamese)
    
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
    
    // MARK: - Log Actions (D-06: per-meal + bulk, D-07: source = "AI Meal Plan")
    
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
    
    // MARK: - Weekly Plan (D-01, D-05: compact 7-row overview)
    
    func generateWeekPlan(targetCalories: Double) async {
        guard !isLoadingWeekly else { return }
        
        await MainActor.run {
            self.isLoadingWeekly = true
            self.weeklyPlan = []
            self.weeklyErrorMessage = nil
        }
        
        let days = ["Thứ 2", "Thứ 3", "Thứ 4", "Thứ 5", "Thứ 6", "Thứ 7", "Chủ Nhật"]
        
        do {
            let userContext = try await contextBuilder.buildFullUserContext()
            let plans = try await AIOrchestrator.shared.generateWeekPlanBatched(userContext: userContext)
            
            await MainActor.run {
                self.weeklyPlan = plans
                self.isLoadingWeekly = false
            }
        } catch {
            print("generateWeekPlan error: \(error)")
            await MainActor.run {
                self.weeklyErrorMessage = "Lỗi tạo kế hoạch tuần: \(error.localizedDescription)"
                self.isLoadingWeekly = false
            }
        }
    }
    
    static func parseSingleDayPlan(_ text: String, dayName: String) -> WeeklyDayPlan? {
        var jsonText = text
        if let firstBracket = jsonText.firstIndex(of: "{"),
           let lastBracket = jsonText.lastIndex(of: "}") {
            jsonText = String(jsonText[firstBracket...lastBracket])
        }
        
        guard let data = jsonText.data(using: .utf8) else { return nil }
        
        do {
            let plan = try JSONDecoder().decode(WeeklyDayPlan.self, from: data)
            return WeeklyDayPlan(
                day: dayName,
                breakfast: plan.breakfast,
                lunch: plan.lunch,
                dinner: plan.dinner,
                snack: plan.snack
            )
        } catch {
            print("Single day parse error: \(error)")
            return nil
        }
    }
    
    func reset() {
        self.planItems = []
        self.isLoading = false
        self.errorMessage = nil
        self.loggedMealTypes = []
        self.weeklyPlan = []
        self.isLoadingWeekly = false
        self.weeklyErrorMessage = nil
    }
}

// MARK: - Weekly Plan Model

struct WeeklyDayPlan: Identifiable, Codable {
    var id = UUID()
    let day: String
    let breakfast: AISuggestedFood?
    let lunch: AISuggestedFood?
    let dinner: AISuggestedFood?
    let snack: AISuggestedFood?
    
    var items: [AISuggestedFood] {
        var results: [AISuggestedFood] = []
        if var b = breakfast { b.mealType = "Bữa sáng"; results.append(b) }
        if var l = lunch { l.mealType = "Bữa trưa"; results.append(l) }
        if var d = dinner { d.mealType = "Bữa tối"; results.append(d) }
        if var s = snack { s.mealType = "Ăn vặt"; results.append(s) }
        return results
    }
    
    var totalCalories: Double {
        items.reduce(0) { $0 + $1.calories }
    }
    
    var highlights: [String] {
        items.prefix(2).map { $0.name }
    }
    
    enum CodingKeys: String, CodingKey {
        case day, breakfast, lunch, dinner, snack
    }
}
