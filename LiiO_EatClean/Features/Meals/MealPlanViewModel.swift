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
                    
                    // Validate total calories (D-02: ±5%)
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
    
    // MARK: - Calorie Validation (D-02: AI phân bổ + app validate ±5%)
    
    static func validateCalories(items: [AISuggestedFood], target: Double) -> [AISuggestedFood] {
        let total = items.reduce(0) { $0 + $1.calories }
        let upperBound = target * 1.05
        
        guard total > upperBound else { return items }
        
        // Proportional trim — create new items with scaled values
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
            self.errorMessage = nil
        }
        
        do {
            let memory = memoryManager.fetchMemory()
            
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
            
            
            QUAN TRỌNG: Trả về kết quả trong một Markdown code block chuẩn ` ```json ... ``` `. Không giải thích thêm.
            
            Định dạng JSON:
            ```json
            {
              "action": "weekly_plan",
              "days": [
                {
                  "day": "T2",
                  "totalCalories": 1800,
                  "highlights": ["Phở bò", "Cơm gà", "Cá hấp"],
                  "items": [
                    {"name":"Phở bò","calories":400,"protein":25,"carbs":50,"fat":10,"servingSize":1.0,"mealType":"Bữa sáng"}
                  ]
                }
              ]
            }
            ```
            
            Mỗi item: {name,calories,protein,carbs,fat,servingSize:1.0,mealType:"Bữa sáng|Bữa trưa|Bữa tối|Ăn vặt"}
            Mỗi bữa 1-2 món. highlights là 3 món tiêu biểu nhất mỗi ngày.
            """
            
            let message = try await aiService.sendChatMessage(history: [], systemPrompt: prompt)
            
            await MainActor.run {
                let text = message.text
                if !text.isEmpty {
                    self.weeklyPlan = Self.parseWeeklyPlan(text, target: targetCalories)
                }
                if self.weeklyPlan.isEmpty {
                    self.errorMessage = "Lỗi Parse JSON. Raw text: \(text.prefix(300))"
                }
                self.isLoadingWeekly = false
            }
        } catch {
            print("generateWeekPlan error: \(error)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoadingWeekly = false
            }
        }
    }
    
    static func parseWeeklyPlan(_ text: String, target: Double) -> [WeeklyDayPlan] {
        // Extract JSON from response (handle markdown code blocks)
        var jsonText = text
        
        // Remove markdown code block markers if present
        if let jsonBlockStart = text.range(of: "```json") {
            jsonText = String(text[jsonBlockStart.upperBound...])
            if let jsonBlockEnd = jsonText.range(of: "```") {
                jsonText = String(jsonText[..<jsonBlockEnd.lowerBound])
            }
        }
        
        guard let jsonStart = jsonText.firstIndex(of: "{"),
              let jsonEnd = jsonText.lastIndex(of: "}") else { return [] }
        
        let jsonString = String(jsonText[jsonStart...jsonEnd])
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
