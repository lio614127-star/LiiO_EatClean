import Foundation
import SwiftUI

struct DailySummary {
    let date: Date
    let totalCalories: Double
    let targetCalories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let mealBreakdown: [String: Double]
    let insights: [DailyInsight]
    let aiComment: String
    let aiSuggestion: String
    let isGoalMet: Bool
    
    // Journal Adherence
    var adherenceScore: Double? = nil
    var plannedCalories: Double? = nil
    var plannedProtein: Double? = nil
    var adherenceLabel: String? = nil
}

@Observable
class DailySummaryService {
    var currentSummary: DailySummary?
    var isLoading = false
    
    private let mealRepository: MealRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    private let dailyPlanRepository: DailyPlanRepositoryProtocol
    private let insightDetector: InsightDetector
    private let aiService: AIService
    
    init(mealRepository: MealRepositoryProtocol = MealRepository(),
         userRepository: UserRepositoryProtocol = UserRepository(),
         dailyPlanRepository: DailyPlanRepositoryProtocol = DailyPlanRepository(),
         insightDetector: InsightDetector = InsightDetector(),
         aiService: AIService = AIService.shared) {
        self.mealRepository = mealRepository
        self.userRepository = userRepository
        self.dailyPlanRepository = dailyPlanRepository
        self.insightDetector = insightDetector
        self.aiService = aiService
    }
    
    func generateSummary(for date: Date = Date(), isInternal: Bool = false) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let meals = try await mealRepository.fetchMeals(by: date)
            let user = try await userRepository.fetchUser()
            let targetCalories = user?.dailyCalorieTarget ?? 2000
            
            var totalCalories: Double = 0
            var protein: Double = 0
            var carbs: Double = 0
            var fat: Double = 0
            var mealBreakdown: [String: Double] = [:]
            
            let validMealTypes = ["bữa sáng", "bữa trưa", "bữa tối", "ăn vặt"]
            
            for meal in meals {
                // Match HomeViewModel: filter by valid meal types
                guard validMealTypes.contains(meal.mealType.lowercased()) else { continue }
                
                var mealCals: Double = 0
                for food in meal.mealFoods {
                    // Match HomeViewModel: only count eaten foods
                    guard food.isEaten else { continue }
                    
                    // caloriesSnapshot already includes quantity — do NOT multiply by qty again
                    mealCals += food.caloriesSnapshot
                    totalCalories += food.caloriesSnapshot
                    protein += food.proteinSnapshot
                    carbs += food.carbsSnapshot
                    fat += food.fatSnapshot
                }
                mealBreakdown[meal.mealType, default: 0] += mealCals
            }
            
            let isGoalMet = totalCalories <= targetCalories
            
            // Only generate insights if we actually logged something
            let insights = meals.isEmpty ? [] : await insightDetector.detectInsights()
            
            // Format data for AI
            var dataBlock = "[Dữ liệu Hôm nay]\n"
            dataBlock += "- Calories: \(Int(totalCalories)) / \(Int(targetCalories)) kcal\n"
            dataBlock += "- Protein: \(Int(protein))g | Carbs: \(Int(carbs))g | Fat: \(Int(fat))g\n"
            for (type, cals) in mealBreakdown {
                dataBlock += "- \(type): \(Int(cals)) kcal\n"
            }
            
            if !insights.isEmpty {
                dataBlock += "\n[Insights (Cảnh báo)]\n"
                for i in insights {
                    dataBlock += "- \(i.message)\n"
                }
            }
            
            let contextBuilder = ContextBuilder(userRepository: userRepository, mealRepository: mealRepository)
            let systemPrompt = try await contextBuilder.buildSystemPrompt(for: "", strategy: .dailySummary)
            
            // Call AI
            let fullPrompt = systemPrompt + "\n\n" + dataBlock
            var aiComment = "Bạn đang đi đúng hướng, hãy tiếp tục duy trì nhé! 💪"
            var aiSuggestion = "Uống đủ nước và cố gắng ăn nhiều rau xanh hơn vào ngày mai."
            
            if !meals.isEmpty {
                let aiResponse = try await aiService.generateText(
                    prompt: fullPrompt, 
                    requestType: .dailySummary, 
                    feature: "Tổng kết ngày",
                    isInternal: isInternal
                )
                // Parse JSON block out of markdown response if it exists
                let jsonString = extractJSON(from: aiResponse)
                
                if let data = jsonString.data(using: String.Encoding.utf8),
                   let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let comment = dict["comment"] as? String { aiComment = comment }
                    if let suggestion = dict["suggestion"] as? String { aiSuggestion = suggestion }
                }
            } else {
                aiComment = "Hôm nay bạn chưa ghi nhận bữa ăn nào. Hãy bắt đầu bằng cách thêm bữa sáng nhé!"
                aiSuggestion = "Đừng bỏ bữa, đặc biệt là bữa sáng rất quan trọng."
            }
            
            var summary = DailySummary(
                date: date,
                totalCalories: totalCalories,
                targetCalories: targetCalories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                mealBreakdown: mealBreakdown,
                insights: insights,
                aiComment: aiComment,
                aiSuggestion: aiSuggestion,
                isGoalMet: isGoalMet
            )
            
            // Integrate Journal Adherence
            if let dailyPlan = try await dailyPlanRepository.fetchPlan(for: date) {
                let adherence = MealAdherenceCalculator.shared.calculate(
                    actualMeals: meals,
                    plannedMeals: dailyPlan.plannedMeals,
                    targetCalories: dailyPlan.targetCalories,
                    targetProtein: dailyPlan.targetProtein
                )
                summary.adherenceScore = adherence.totalScore
                summary.plannedCalories = dailyPlan.targetCalories
                summary.plannedProtein = dailyPlan.targetProtein
                summary.adherenceLabel = adherence.statusLabel
            }
            
            self.currentSummary = summary
            
        } catch {
            print("DailySummaryService Error: \(error)")
        }
    }
    
    private func extractJSON(from response: String) -> String {
        if let startRange = response.range(of: "```json"),
           let endRange = response.range(of: "```", range: startRange.upperBound..<response.endIndex) {
            return String(response[startRange.upperBound..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return response
    }
}
