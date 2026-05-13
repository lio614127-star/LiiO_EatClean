import Foundation
import SwiftUI

@Observable
class MealsViewModel {
    var meals: [MealModel] = []
    var selectedDate: Date = Date()
    var isLoading = false
    var user: UserModel?
    
    private let mealRepository: MealRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    
    init(mealRepository: MealRepositoryProtocol = MealRepository(),
         userRepository: UserRepositoryProtocol = UserRepository()) {
        self.mealRepository = mealRepository
        self.userRepository = userRepository
    }
    
    func loadData(for date: Date? = nil, forceSilent: Bool = false) async {
        let targetDate = date ?? selectedDate
        let isInitialLoad = meals.isEmpty && !forceSilent
        
        if isInitialLoad {
            isLoading = true
        }
        
        do {
            user = try await userRepository.fetchUser()
            let fetchedMeals = try await mealRepository.fetchMeals(by: targetDate)
            
            if fetchedMeals != meals {
                meals = fetchedMeals
            }
            
            if meals.isEmpty && isInitialLoad {
                try await Task.sleep(nanoseconds: 200_000_000)
                meals = try await mealRepository.fetchMeals(by: targetDate)
            }
        } catch {
            print("Error loading meals for \(targetDate): \(error)")
        }
        
        if isInitialLoad {
            isLoading = false
        }
        
        let allFoods = meals.flatMap { $0.mealFoods }.compactMap { $0.foodItem }
        BackgroundEnrichmentManager.shared.enrich(foods: allFoods)
    }
    
    func deleteMealFood(id: UUID) async {
        do {
            try await mealRepository.deleteMealFood(by: id)
            await loadData()
        } catch {
            print("Failed to delete meal food: \(error)")
        }
    }
    
    func toggleMealFoodStatus(id: UUID) async {
        let currentStatus = meals.flatMap { $0.mealFoods }.first(where: { $0.id == id })?.isEaten ?? false
        do {
            try await mealRepository.updateMealFoodStatus(id: id, isEaten: !currentStatus)
            await loadData()
        } catch {
            print("Failed to toggle meal food status: \(error)")
        }
    }
    
    // Group meals by type
    func meals(for type: String) -> [MealModel] {
        meals.filter { $0.mealType.lowercased() == type.lowercased() }
    }
    
    private var validMealTypes: [String] { ["Bữa sáng", "Bữa trưa", "Bữa tối", "Ăn vặt"] }
    
    var totalCalories: Double {
        meals
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
