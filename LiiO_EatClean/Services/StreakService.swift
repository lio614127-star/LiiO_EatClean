import Foundation

@Observable
class StreakService {
    private let userRepository: UserRepositoryProtocol
    
    init(userRepository: UserRepositoryProtocol = UserRepository()) {
        self.userRepository = userRepository
    }
    
    func evaluateToday(meals: [MealModel], totalCalories: Double, dailyTarget: Double, waterConsumed: Double, waterTarget: Double) async -> StreakModel {
        var streak = (try? await userRepository.fetchStreak()) ?? StreakModel(
            id: UUID(),
            currentStreak: 0,
            longestStreak: 0,
            lastActiveDate: Date.distantPast,
            mealConditionMet: false,
            calorieConditionMet: false,
            waterConditionMet: false
        )
        
        let calendar = Calendar.current
        
        // 1. Check Meal Condition
        let uniqueMealTypes = Set(meals.map { $0.mealType })
        let mealConditionMet = uniqueMealTypes.count >= 2
        
        // 2. Check Calorie Condition
        let calorieMargin = dailyTarget * 0.10
        let calorieConditionMet = abs(totalCalories - dailyTarget) <= calorieMargin
        
        // 3. Check Water Condition
        let waterConditionMet = waterConsumed >= (waterTarget * 0.80)
        
        streak.mealConditionMet = mealConditionMet
        streak.calorieConditionMet = calorieConditionMet
        streak.waterConditionMet = waterConditionMet
        
        let allConditionsMet = mealConditionMet && calorieConditionMet && waterConditionMet
        
        if allConditionsMet {
            if calendar.isDateInToday(streak.lastActiveDate) {
                // Already updated today, do nothing to the streak count
            } else if calendar.isDateInYesterday(streak.lastActiveDate) {
                // Consecutive day
                streak.currentStreak += 1
                streak.lastActiveDate = Date()
            } else {
                // Streak broken, start new
                streak.currentStreak = 1
                streak.lastActiveDate = Date()
            }
        } else {
            // Check if streak should be reset due to missed days
            // Note: We don't reset currentStreak immediately today if conditions aren't met yet,
            // because the user has until the end of the day to meet them.
            // But if the last active date is older than yesterday, the streak is already lost.
            if !calendar.isDateInToday(streak.lastActiveDate) && !calendar.isDateInYesterday(streak.lastActiveDate) {
                streak.currentStreak = 0
            }
        }
        
        streak.longestStreak = max(streak.longestStreak, streak.currentStreak)
        
        try? await userRepository.saveStreak(streak)
        
        return streak
    }
}
