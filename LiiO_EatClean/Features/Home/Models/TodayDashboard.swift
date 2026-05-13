import Foundation

struct TodayDashboard: Equatable {
    let date: Date
    var confirmedDailyPlan: DailyPlanModel?
    
    // Categorized Planned Meals
    var pendingPlannedMeals: [PlannedMealModel] = []
    var eatenPlannedMeals: [PlannedMealModel] = []
    var skippedPlannedMeals: [PlannedMealModel] = []
    
    // Actual Meal Logs
    var actualMealLogs: [MealModel] = []
    
    // Unplanned Meal Logs (source != plannedMeal or not linked)
    var unplannedMealLogs: [MealModel] = []
    
    // Totals
    var actualCalories: Double = 0
    var actualProtein: Double = 0
    var actualCarbs: Double = 0
    var actualFat: Double = 0
    
    var plannedCalories: Double = 0
    var plannedProtein: Double = 0
    
    // Progress
    var remainingPlannedCalories: Double {
        max(0, plannedCalories - actualCalories)
    }
    
    var nextPlannedMeal: PlannedMealModel? {
        pendingPlannedMeals.first
    }
    
    static func == (lhs: TodayDashboard, rhs: TodayDashboard) -> Bool {
        lhs.date == rhs.date &&
        lhs.confirmedDailyPlan == rhs.confirmedDailyPlan &&
        lhs.pendingPlannedMeals == rhs.pendingPlannedMeals &&
        lhs.eatenPlannedMeals == rhs.eatenPlannedMeals &&
        lhs.skippedPlannedMeals == rhs.skippedPlannedMeals &&
        lhs.actualMealLogs == rhs.actualMealLogs &&
        lhs.unplannedMealLogs == rhs.unplannedMealLogs
    }
}
