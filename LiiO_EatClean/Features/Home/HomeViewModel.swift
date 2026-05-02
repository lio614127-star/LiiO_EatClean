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
    
    private let mealRepository: MealRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    
    init(mealRepository: MealRepositoryProtocol = MealRepository(),
         userRepository: UserRepositoryProtocol = UserRepository()) {
        self.mealRepository = mealRepository
        self.userRepository = userRepository
    }
    
    func loadDashboard() async {
        isLoading = true
        do {
            user = try await userRepository.fetchUser()
            todayMeals = try await mealRepository.fetchMeals(by: Date())
            waterConsumed = try await userRepository.fetchWaterLog(for: Date())
        } catch {
            print("Error loading dashboard data: \(error)")
        }
        isLoading = false
    }
    
    func addWater(amount: Double) async {
        do {
            try await userRepository.addWater(amount: amount, for: Date())
            waterConsumed += amount
        } catch {
            print("Failed to log water: \(error)")
        }
    }
    
    func deleteMealFood(id: UUID) async {
        do {
            try await mealRepository.deleteMealFood(by: id)
            await loadDashboard()
        } catch {
            print("Failed to delete meal food: \(error)")
        }
    }
    
    // Computed properties for Dashboard
    var totalCalories: Double {
        todayMeals.flatMap { $0.mealFoods }.reduce(0) { $0 + $1.caloriesSnapshot }
    }
    
    var totalProtein: Double {
        todayMeals.flatMap { $0.mealFoods }.reduce(0) { $0 + $1.proteinSnapshot }
    }
    
    var totalCarbs: Double {
        todayMeals.flatMap { $0.mealFoods }.reduce(0) { $0 + $1.carbsSnapshot }
    }
    
    var totalFat: Double {
        todayMeals.flatMap { $0.mealFoods }.reduce(0) { $0 + $1.fatSnapshot }
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
}
