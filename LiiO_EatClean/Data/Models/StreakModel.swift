import Foundation

struct StreakModel: Identifiable, Codable {
    let id: UUID
    var currentStreak: Int
    var longestStreak: Int
    var lastActiveDate: Date
    var mealConditionMet: Bool
    var calorieConditionMet: Bool
    var waterConditionMet: Bool
    var conditionsMet: Int { [mealConditionMet, calorieConditionMet, waterConditionMet].filter { $0 }.count }
}
