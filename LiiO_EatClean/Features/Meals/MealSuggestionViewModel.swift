import Foundation
import SwiftUI

@Observable
class MealSuggestionViewModel {
    var suggestions: [AISuggestedFood] = []
    var isLoading = false
    var hasFetched = false
    var errorMessage: String?
    var showLogSuccess = false
    
    private let aiService = AIService.shared
    private let contextBuilder = ContextBuilder()
    private let mealRepository: MealRepositoryProtocol
    private let memoryManager: MemoryManagerProtocol
    
    init(mealRepository: MealRepositoryProtocol = MealRepository(),
         memoryManager: MemoryManagerProtocol = MemoryManager.shared) {
        self.mealRepository = mealRepository
        self.memoryManager = memoryManager
    }
    
    var suggestedMealType: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<10: return "Bữa sáng"
        case 10..<14: return "Bữa trưa"
        case 14..<17: return "Ăn vặt"
        case 17..<21: return "Bữa tối"
        default: return "Ăn vặt"
        }
    }
    
    func fetchSuggestions(remainingCalories: Double) async {
        guard !isLoading else { return }
        
        await MainActor.run {
            self.isLoading = true
            self.hasFetched = false
            self.errorMessage = nil
            self.suggestions = []
        }
        
        do {
            let prompt = try await contextBuilder.buildSystemPrompt(
                for: "Gợi ý món ăn",
                strategy: .mealSuggestion,
                remainingCalories: remainingCalories,
                mealType: suggestedMealType
            )
            
            let message = try await aiService.sendChatMessage(history: [], systemPrompt: prompt)
            
            await MainActor.run {
                if let foods = message.suggestedFoods, !foods.isEmpty {
                    self.suggestions = foods
                    self.hasFetched = true
                } else {
                    self.errorMessage = "AI không thể đưa ra gợi ý lúc này."
                }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Lỗi kết nối AI: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func logSuggestion(_ food: AISuggestedFood) async {
        do {
            let foodItem = FoodItemModel(
                name: food.name,
                calories: food.calories,
                protein: food.protein,
                carbs: food.carbs,
                fat: food.fat,
                servingSize: food.servingSize,
                source: "AI Suggestion"
            )
            
            let finalMealType = (food.mealType ?? self.suggestedMealType).trimmingCharacters(in: .whitespacesAndNewlines)
            
            let mealFood = MealFoodModel(
                quantity: food.servingSize,
                caloriesSnapshot: food.calories,
                proteinSnapshot: food.protein,
                carbsSnapshot: food.carbs,
                fatSnapshot: food.fat,
                isEaten: true,
                mealType: finalMealType,
                foodItem: foodItem
            )
            
            let meal = MealModel(
                date: Date(),
                mealType: finalMealType,
                mealFoods: [mealFood]
            )
            
            try await mealRepository.saveMeal(meal, for: Date())
            
            await MainActor.run {
                self.showLogSuccess = true
                
                // Remove the logged suggestion from the list
                if let index = self.suggestions.firstIndex(where: { $0.id == food.id }) {
                    self.suggestions.remove(at: index)
                }
                
                // Hide success message after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.showLogSuccess = false
                }
            }
        } catch {
            print("Error logging suggested food: \(error)")
        }
    }
}
