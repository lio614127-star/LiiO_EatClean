import Foundation
import SwiftUI

@Observable
class AddMealViewModel {
    var selectedMealType: String
    var cartItems: [MealFoodModel] = []
    
    // AI state
    var suggestedFoods: [AISuggestedFood] = []
    var cachedSuggestions: [String: [AISuggestedFood]] = [:]
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
    
    func addToCart(food: FoodItemModel, quantity: Double, unit: String? = nil) {
        var processedFood = food
        
        // If a specific unit is provided, use the conversion engine
        if let unit = unit, unit.lowercased() != "phần" {
            processedFood = UnitConversionEngine.shared.convert(food: food, to: unit, newAmount: quantity)
        }
        
        let ratio = (unit == nil || unit?.lowercased() == "phần") ? quantity : 1.0
        
        let caloriesSnapshot = processedFood.calories * ratio
        let proteinSnapshot = processedFood.protein * ratio
        let carbsSnapshot = processedFood.carbs * ratio
        let fatSnapshot = processedFood.fat * ratio
        
        let mealFood = MealFoodModel(
            id: UUID(),
            quantity: quantity,
            caloriesSnapshot: caloriesSnapshot,
            proteinSnapshot: proteinSnapshot,
            carbsSnapshot: carbsSnapshot,
            fatSnapshot: fatSnapshot,
            isEaten: true,
            mealType: selectedMealType,
            foodItem: processedFood
        )
        
        cartItems.append(mealFood)
    }
    
    func addSuggestedFood(_ suggested: AISuggestedFood) {
        let food = suggested.toFoodItemModel()
        // Use the AI-provided unit and weight if available
        addToCart(food: food, quantity: 1.0, unit: food.unit)
        suggestedFoods.removeAll { $0.id == suggested.id }
    }
    
    func removeFromCart(id: UUID) {
        cartItems.removeAll { $0.id == id }
    }
    
    func saveCart(for date: Date) async {
        guard !cartItems.isEmpty else { return }
        
        // Group items by their assigned mealType
        let groupedItems = Dictionary(grouping: cartItems) { $0.mealType ?? selectedMealType }
        
        for (mealType, items) in groupedItems {
            let meal = MealModel(
                id: UUID(),
                date: date,
                mealType: mealType,
                mealFoods: items
            )
            
            do {
                try await mealRepository.saveMeal(meal, for: date)
                
                // Background Enrichment: Fetch recipes for any items that don't have them
                BackgroundEnrichmentManager.shared.enrich(foods: items.compactMap { $0.foodItem })
            } catch {
                print("Failed to save meal (\(mealType)): \(error)")
            }
        }
        
        cartItems.removeAll()
    }
    
    func loadRemainingCalories() async {
        do {
            let user = try await userRepository.fetchUser()
            let target = user?.dailyCalorieTarget ?? 2000
            
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
            let mealsToday = try await mealRepository.fetchMeals(from: today, to: tomorrow)
            
            let validMealTypes = ["Bữa sáng", "Bữa trưa", "Bữa tối", "Ăn vặt"]
            let consumed = mealsToday.reduce(0.0) { total, meal in
                guard validMealTypes.contains(where: { $0.lowercased() == meal.mealType.lowercased() }) else { return total }
                return total + meal.mealFoods.reduce(0.0) { $0 + $1.caloriesSnapshot }
            }
            
            remainingCalories = max(0, target - consumed)
        } catch {
            remainingCalories = 500 // Sensible fallback
        }
    }
    
    func requestAISuggestions(forceRefresh: Bool = false) async {
        if !forceRefresh, let cached = cachedSuggestions[selectedMealType], !cached.isEmpty {
            self.suggestedFoods = cached
            self.showingAISection = true
            return
        }
        
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
                userGoal: goalType,
                isInternal: true
            )
            self.cachedSuggestions[selectedMealType] = results
            self.suggestedFoods = results
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
