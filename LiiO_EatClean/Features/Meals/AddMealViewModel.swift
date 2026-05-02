import Foundation
import SwiftUI

@Observable
class AddMealViewModel {
    var selectedMealType: String
    var cartItems: [MealFoodModel] = []
    
    // AI state
    var suggestedFoods: [AISuggestedFood] = []
    var isLoadingAI = false
    var aiError: AIError? = nil
    var showingAISection = false
    var needsAPIKey = false
    
    private let mealRepository: MealRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    private let aiService: AIService
    
    // Remaining calories for context
    var remainingCalories: Double = 0
    
    init(selectedMealType: String = "Bữa sáng",
         mealRepository: MealRepositoryProtocol = MealRepository(),
         userRepository: UserRepositoryProtocol = UserRepository()) {
        self.selectedMealType = selectedMealType
        self.mealRepository = mealRepository
        self.userRepository = userRepository
        self.aiService = AIService(userRepository: userRepository)
    }
    
    func addToCart(food: FoodItemModel, quantity: Double) {
        let caloriesSnapshot = food.calories * quantity
        let proteinSnapshot = food.protein * quantity
        let carbsSnapshot = food.carbs * quantity
        let fatSnapshot = food.fat * quantity
        
        let mealFood = MealFoodModel(
            id: UUID(),
            quantity: quantity,
            caloriesSnapshot: caloriesSnapshot,
            proteinSnapshot: proteinSnapshot,
            carbsSnapshot: carbsSnapshot,
            fatSnapshot: fatSnapshot,
            foodItem: food
        )
        
        cartItems.append(mealFood)
    }
    
    func addSuggestedFood(_ suggested: AISuggestedFood) {
        let food = suggested.toFoodItemModel()
        addToCart(food: food, quantity: 1)
        // Remove from suggestions after logging
        suggestedFoods.removeAll { $0.id == suggested.id }
    }
    
    func removeFromCart(id: UUID) {
        cartItems.removeAll { $0.id == id }
    }
    
    func saveCart(for date: Date) async {
        guard !cartItems.isEmpty else { return }
        
        let meal = MealModel(
            id: UUID(),
            date: date,
            mealType: selectedMealType,
            mealFoods: cartItems
        )
        
        do {
            try await mealRepository.saveMeal(meal, for: date)
            cartItems.removeAll()
        } catch {
            print("Failed to save meal: \(error)")
        }
    }
    
    func loadRemainingCalories() async {
        do {
            let user = try await userRepository.fetchUser()
            let target = user?.dailyCalorieTarget ?? 2000
            
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
            let mealsToday = try await mealRepository.fetchMeals(from: today, to: tomorrow)
            
            let consumed = mealsToday.reduce(0.0) { total, meal in
                total + meal.mealFoods.reduce(0.0) { $0 + $1.caloriesSnapshot }
            }
            
            remainingCalories = max(0, target - consumed)
        } catch {
            remainingCalories = 500 // Sensible fallback
        }
    }
    
    func requestAISuggestions() async {
        aiError = nil
        isLoadingAI = true
        showingAISection = true
        suggestedFoods = []
        
        do {
            let user = try await userRepository.fetchUser()
            let goalType = user?.goalType ?? "Duy trì cân nặng"
            
            let results = try await aiService.suggestMeals(
                remainingCalories: remainingCalories,
                mealType: selectedMealType,
                userGoal: goalType
            )
            suggestedFoods = results
        } catch AIError.missingKey {
            needsAPIKey = true
            showingAISection = false
        } catch let error as AIError {
            aiError = error
        } catch {
            aiError = AIError.networkError(error.localizedDescription)
        }
        
        isLoadingAI = false
    }
}
