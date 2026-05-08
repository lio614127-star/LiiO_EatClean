import Foundation
import SwiftUI

@Observable
class HomeViewModel {
    var user: UserModel?
    var todayMeals: [MealModel] = []
    var isLoading = false
    
    // Water tracking
    var waterConsumed: Double = 0
    var waterTarget: Double = 2000 // default 2000ml
    
    // Gamification
    var streak: StreakModel?
    var showMilestonePopup = false
    var milestoneValue = 0
    
    // Proactive AI
    var dailySummary: DailySummary?
    var insights: [DailyInsight]?
    private let summaryService = DailySummaryService()
    
    private let mealRepository: MealRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    private let streakService: StreakService
    
    init(mealRepository: MealRepositoryProtocol = MealRepository(),
         userRepository: UserRepositoryProtocol = UserRepository(),
         streakService: StreakService = StreakService()) {
        self.mealRepository = mealRepository
        self.userRepository = userRepository
        self.streakService = streakService
    }
    
    func loadDashboard() async {
        if todayMeals.isEmpty && user == nil {
            isLoading = true
        }
        do {
            user = try await userRepository.fetchUser()
            todayMeals = try await mealRepository.fetchMeals(by: Date())
            waterConsumed = try await userRepository.fetchWaterLog(for: Date())
            
            let previousIsOverTarget = isOverTarget
            
            streak = await streakService.evaluateToday(
                meals: todayMeals,
                totalCalories: totalCalories,
                dailyTarget: dailyTarget,
                waterConsumed: waterConsumed,
                waterTarget: waterTarget
            )
            
            if let streak = streak, [7, 14, 30].contains(streak.currentStreak) {
                // Determine if we just hit it today
                let calendar = Calendar.current
                if calendar.isDateInToday(streak.lastActiveDate) && streak.conditionsMet == 3 {
                    milestoneValue = streak.currentStreak
                    showMilestonePopup = true
                }
            }
            
            if !previousIsOverTarget && isOverTarget {
                HapticManager.warning()
            }
            
        } catch {
            print("Error loading dashboard data: \(error)")
        }
        isLoading = false
        
        // Generate AI Summary in background — NOT blocking dashboard UI
        await loadDailySummaryIfNeeded()
        
        let insightDetector = InsightDetector()
        insights = await insightDetector.detectInsights()
    }
    
    private var lastSummaryMealCount: Int = -1
    
    private func loadDailySummaryIfNeeded() async {
        // Only regenerate if meal data changed (avoid re-calling AI on every tab switch)
        let currentMealCount = todayMeals.flatMap { $0.mealFoods }.filter { $0.isEaten }.count
        guard currentMealCount != lastSummaryMealCount else { return }
        lastSummaryMealCount = currentMealCount
        
        await summaryService.generateSummary()
        dailySummary = summaryService.currentSummary
    }
    
    func addWater(amount: Double) async {
        do {
            try await userRepository.addWater(amount: amount, for: Date())
            waterConsumed += amount
            await refreshStreak()
        } catch {
            print("Failed to log water: \(error)")
        }
    }
    
    func resetWater() async {
        do {
            try await userRepository.resetWater(for: Date())
            waterConsumed = 0
            await refreshStreak()
        } catch {
            print("Failed to reset water: \(error)")
        }
    }
    
    private func refreshStreak() async {
        streak = await streakService.evaluateToday(
            meals: todayMeals,
            totalCalories: totalCalories,
            dailyTarget: dailyTarget,
            waterConsumed: waterConsumed,
            waterTarget: waterTarget
        )
    }
    
    func deleteMealFood(id: UUID) async {
        do {
            try await mealRepository.deleteMealFood(by: id)
            HapticManager.success()
            await loadDashboard()
        } catch {
            print("Failed to delete meal food: \(error)")
        }
    }
    
    // Computed properties for Dashboard
    private var validMealTypes: [String] { ["Bữa sáng", "Bữa trưa", "Bữa tối", "Ăn vặt"] }
    
    var totalCalories: Double {
        todayMeals
            .filter { meal in validMealTypes.contains { $0.lowercased() == meal.mealType.lowercased() } }
            .flatMap { $0.mealFoods }
            .filter { $0.isEaten }
            .reduce(0) { $0 + $1.caloriesSnapshot }
    }
    
    var totalProtein: Double {
        todayMeals
            .filter { meal in validMealTypes.contains { $0.lowercased() == meal.mealType.lowercased() } }
            .flatMap { $0.mealFoods }
            .filter { $0.isEaten }
            .reduce(0) { $0 + $1.proteinSnapshot }
    }
    
    var totalCarbs: Double {
        todayMeals
            .filter { meal in validMealTypes.contains { $0.lowercased() == meal.mealType.lowercased() } }
            .flatMap { $0.mealFoods }
            .filter { $0.isEaten }
            .reduce(0) { $0 + $1.carbsSnapshot }
    }
    
    var totalFat: Double {
        todayMeals
            .filter { meal in validMealTypes.contains { $0.lowercased() == meal.mealType.lowercased() } }
            .flatMap { $0.mealFoods }
            .filter { $0.isEaten }
            .reduce(0) { $0 + $1.fatSnapshot }
    }
    
    var dailyTarget: Double {
        user?.dailyCalorieTarget ?? 2000.0
    }
    
    var remainingCalories: Double {
        max(0, dailyTarget - totalCalories)
    }
    
    var isOverTarget: Bool {
        totalCalories > dailyTarget
    }
    
    // Macro targets derived from calorie target (30% Protein, 40% Carbs, 30% Fat)
    var proteinTarget: Double {
        (dailyTarget * 0.30) / 4.0
    }
    
    var carbsTarget: Double {
        (dailyTarget * 0.40) / 4.0
    }
    
    var fatTarget: Double {
        (dailyTarget * 0.30) / 9.0
    }
    
    func meals(for type: String) -> [MealModel] {
        todayMeals.filter { $0.mealType.lowercased() == type.lowercased() }
    }
    
    func toggleMealFoodStatus(id: UUID) async {
        let currentStatus = todayMeals.flatMap { $0.mealFoods }.first(where: { $0.id == id })?.isEaten ?? false
        do {
            try await mealRepository.updateMealFoodStatus(id: id, isEaten: !currentStatus)
            await loadDashboard()
        } catch {
            print("Failed to toggle meal food status: \(error)")
        }
    }
}
