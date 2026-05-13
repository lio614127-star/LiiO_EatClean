import Foundation

struct MealAdherenceResult {
    let totalScore: Double
    let calorieScore: Double
    let proteinScore: Double
    let completionScore: Double
    let fidelityScore: Double
    
    var statusLabel: String {
        switch totalScore {
        case 90...100: return "Tuyệt vời"
        case 75..<90: return "Rất tốt"
        case 60..<75: return "Bám sát plan"
        case 40..<60: return "Cần chú ý"
        default: return "Lệch mục tiêu"
        }
    }
}

class MealAdherenceCalculator {
    static let shared = MealAdherenceCalculator()
    
    private init() {}
    
    func calculate(
        actualMeals: [MealModel],
        plannedMeals: [PlannedMealModel],
        targetCalories: Double,
        targetProtein: Double
    ) -> MealAdherenceResult {
        
        let actualCalories = actualMeals.reduce(0) { $0 + $1.totalCalories }
        let actualProtein = actualMeals.reduce(0) { sum, meal in
            sum + meal.mealFoods.reduce(0) { $0 + ($1.proteinSnapshot * $1.quantity) }
        }
        
        // 1. Calorie Score (50 pts)
        let calDiffRatio = targetCalories > 0 ? abs(actualCalories - targetCalories) / targetCalories : 0
        let calorieScore = max(0, 50 * (1 - calDiffRatio / 0.25)) // 0 pts if >25% off
        
        // 2. Protein Score (25 pts)
        let protRatio = targetProtein > 0 ? actualProtein / targetProtein : 1.0
        var proteinScore: Double = 0
        if protRatio >= 0.9 && protRatio <= 1.2 {
            proteinScore = 25
        } else if protRatio < 0.9 {
            proteinScore = max(0, 25 * (protRatio / 0.9))
        } else {
            proteinScore = max(0, 25 * (1 - (protRatio - 1.2) / 0.5))
        }
        
        // 3. Completion Score (15 pts)
        let totalPlanned = Double(plannedMeals.count)
        let eatenPlanned = Double(plannedMeals.filter { $0.status == "eaten" }.count)
        let completionScore = totalPlanned > 0 ? (eatenPlanned / totalPlanned) * 15 : 15
        
        // 4. Fidelity Score (10 pts)
        let linkedCount = Double(actualMeals.filter { $0.linkedPlannedMealId != nil }.count)
        let totalEaten = Double(actualMeals.count)
        let fidelityScore = totalEaten > 0 ? min(10, (linkedCount / totalEaten) * 10) : 10
        
        return MealAdherenceResult(
            totalScore: calorieScore + proteinScore + completionScore + fidelityScore,
            calorieScore: calorieScore,
            proteinScore: proteinScore,
            completionScore: completionScore,
            fidelityScore: fidelityScore
        )
    }
}
