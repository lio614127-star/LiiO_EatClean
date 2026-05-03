import Foundation

/// Calorie calculator using the Mifflin-St Jeor equation.
/// This is the gold standard formula recommended by the Academy of Nutrition and Dietetics.
struct CalorieCalculator {
    
    /// Calculate daily calorie target based on user profile and goal.
    /// - Parameters:
    ///   - weight: Body weight in kilograms
    ///   - height: Height in centimeters
    ///   - age: Age in years
    ///   - gender: "male" or "female"
    ///   - goal: "lose", "maintain", or "gain"
    /// - Returns: Daily calorie target (minimum 1200 kcal)
    static func calculateDailyCalories(
        weight: Double,
        height: Double,
        age: Double,
        gender: String,
        goal: String
    ) -> Double {
        // Mifflin-St Jeor BMR
        let bmr: Double
        if gender == "male" {
            bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5
        } else {
            bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161
        }
        
        // TDEE with activity multiplier
        // Default to 1.55 (Moderate), but structured to be adjustable in v2
        let activityMultiplier = 1.55
        let tdee = bmr * activityMultiplier
        
        // Goal adjustment
        let adjustment: Double
        switch goal {
        case "lose": adjustment = -500
        case "gain": adjustment = 300
        default: adjustment = 0 // maintain
        }
        
        let result = tdee + adjustment
        
        // Enforce safe minimums based on gender
        // Men: 1500 kcal, Women: 1200 kcal
        let minCalories: Double = (gender == "male") ? 1500 : 1200
        
        return max(minCalories, result)
    }
}
