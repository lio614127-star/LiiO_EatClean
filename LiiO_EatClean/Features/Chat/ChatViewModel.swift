import Foundation
import SwiftUI
import Observation

@Observable
class ChatViewModel {
    var messages: [ChatMessage] = []
    var isTyping = false
    var errorMessage: String?
    
    private let aiService = AIService.shared
    private let contextBuilder = ContextBuilder()
    private let mealRepository: MealRepositoryProtocol
    
    init(mealRepository: MealRepositoryProtocol = MealRepository()) {
        self.mealRepository = mealRepository
        
        // Add a welcoming message
        messages.append(ChatMessage(role: .assistant, text: "Chào bạn! Mình là trợ lý dinh dưỡng cá nhân của bạn đây. Hôm nay bạn ăn uống thế nào rồi?", suggestedFoods: nil))
    }
    
    func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let userMessage = ChatMessage(role: .user, text: trimmed, suggestedFoods: nil)
        messages.append(userMessage)
        
        isTyping = true
        errorMessage = nil
        
        let historyToSend = Array(messages.suffix(10))
        
        Task {
            do {
                let systemPrompt = try await contextBuilder.buildSystemPrompt(for: trimmed)
                let responseMessage = try await aiService.sendChatMessage(history: historyToSend, systemPrompt: systemPrompt)
                await MainActor.run {
                    self.messages.append(responseMessage)
                    self.isTyping = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isTyping = false
                }
            }
        }
    }
    
    func logSuggestedFood(_ food: AISuggestedFood, mealType: String = "Ăn vặt") {
        let mealFood = food.toMealFoodModel()
        let date = Date()
        
        // Prioritize mealType from AI, and map common variants to standard UI types
        var finalMealType = food.mealType ?? mealType
        if finalMealType.lowercased().contains("phụ") || finalMealType.lowercased().contains("vặt") {
            finalMealType = "Ăn vặt"
        }
        
        let meal = MealModel(date: date, mealType: finalMealType, mealFoods: [mealFood])
        
        Task {
            do {
                try await mealRepository.saveMeal(meal, for: date)
                await MainActor.run {
                    let statusSuffix = (food.isEaten ?? false) ? "đã ăn" : "vào danh sách chờ"
                    let successMsg = ChatMessage(role: .assistant, text: "Đã thêm **\(food.name)** \(statusSuffix)! 👍", suggestedFoods: nil)
                    messages.append(successMsg)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Lỗi lưu món ăn: \(error.localizedDescription)"
                }
            }
        }
    }
}
