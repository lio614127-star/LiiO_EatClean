import Foundation
import SwiftUI

@Observable
class MealsViewModel {
    var todayMeals: [MealModel] = []
    var isLoading = false
    var user: UserModel?
    
    private let mealRepository: MealRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    
    init(mealRepository: MealRepositoryProtocol = MealRepository(),
         userRepository: UserRepositoryProtocol = UserRepository()) {
        self.mealRepository = mealRepository
        self.userRepository = userRepository
    }
    
    func loadTodayMeals(forceSilent: Bool = false) async {
        let isInitialLoad = todayMeals.isEmpty && !forceSilent
        
        if isInitialLoad {
            isLoading = true
        }
        
        do {
            user = try await userRepository.fetchUser()
            let fetchedMeals = try await mealRepository.fetchMeals(by: Date())
            
            // ⚡ Update only if data actually changed to avoid unnecessary List flashes
            if fetchedMeals != todayMeals {
                todayMeals = fetchedMeals
            }
            
            // ⚡ Handle sync delays only on initial empty state
            if todayMeals.isEmpty && isInitialLoad {
                try await Task.sleep(nanoseconds: 200_000_000)
                todayMeals = try await mealRepository.fetchMeals(by: Date())
            }
        } catch {
            print("Error loading today meals: \(error)")
        }
        
        if isInitialLoad {
            isLoading = false
        }
        
        // Background Enrichment
        let allFoods = todayMeals.flatMap { $0.mealFoods }.compactMap { $0.foodItem }
        BackgroundEnrichmentManager.shared.enrich(foods: allFoods)
    }
    
    func deleteMealFood(id: UUID) async {
        do {
            try await mealRepository.deleteMealFood(by: id)
            await loadTodayMeals()
        } catch {
            print("Failed to delete meal food: \(error)")
        }
    }
    
    func toggleMealFoodStatus(id: UUID) async {
        let currentStatus = todayMeals.flatMap { $0.mealFoods }.first(where: { $0.id == id })?.isEaten ?? false
        do {
            try await mealRepository.updateMealFoodStatus(id: id, isEaten: !currentStatus)
            await loadTodayMeals()
        } catch {
            print("Failed to toggle meal food status: \(error)")
        }
    }
    
    // Group meals by type
    func meals(for type: String) -> [MealModel] {
        todayMeals.filter { $0.mealType.lowercased() == type.lowercased() }
    }
    
    private var validMealTypes: [String] { ["Bữa sáng", "Bữa trưa", "Bữa tối", "Ăn vặt"] }
    
    var totalCalories: Double {
        todayMeals
            .filter { meal in validMealTypes.contains { $0.lowercased() == meal.mealType.lowercased() } }
            .flatMap { $0.mealFoods }
            .filter { $0.isEaten }
            .reduce(0) { $0 + $1.caloriesSnapshot }
    }
    
    var dailyTarget: Double {
        user?.dailyCalorieTarget ?? 2000.0
    }
    
    var remainingCalories: Double {
        max(0, dailyTarget - totalCalories)
    }
}
