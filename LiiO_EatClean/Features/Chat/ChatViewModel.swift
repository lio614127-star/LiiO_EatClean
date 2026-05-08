import Foundation
import SwiftUI
import Observation

@Observable
class ChatViewModel {
    var messages: [ChatMessage] = []
    var isTyping = false
    var errorMessage: String?
    var healthSafetyApplied = false
    
    private let aiService = AIService.shared
    private let contextBuilder = ContextBuilder()
    private let mealRepository: MealRepositoryProtocol
    
    init(mealRepository: MealRepositoryProtocol = MealRepository()) {
        self.mealRepository = mealRepository
        
        // Add a welcoming message
        messages.append(ChatMessage(role: .assistant, text: "Chào bạn! Mình là trợ lý dinh dưỡng cá nhân của bạn đây. Hôm nay bạn ăn uống thế nào rồi?", suggestedFoods: nil))
    }
    
    var currentModelInfo: AIModelInfo?
    var isStreaming = false
    
    func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let userMessage = ChatMessage(role: .user, text: trimmed, suggestedFoods: nil)
        messages.append(userMessage)
        
        errorMessage = nil
        currentModelInfo = nil
        
        let historyToSend = Array(messages.suffix(10))
        
        Task {
            do {
                let systemPrompt = try await contextBuilder.buildSystemPrompt(for: trimmed, strategy: .chat)
                
                // 1. Create a stable ID for the assistant message
                let assistantID = UUID()
                
                await MainActor.run {
                    self.isTyping = true
                    self.isStreaming = true
                    // 2. Append an empty assistant bubble immediately
                    self.messages.append(ChatMessage(id: assistantID, role: .assistant, text: "", suggestedFoods: nil))
                }
                
                let stream = aiService.sendChatMessageStream(
                    history: historyToSend, 
                    systemPrompt: systemPrompt,
                    isInternal: true
                )
                
                for try await result in stream {
                    await MainActor.run {
                        // 3. Ensure TypingIndicator disappears as soon as first data (info or chunk) arrives
                        if self.isTyping { self.isTyping = false }
                        
                        switch result {
                        case .modelInfo(let info):
                            if let index = self.messages.firstIndex(where: { $0.id == assistantID }) {
                                self.messages[index].modelInfo = info
                            }
                            self.currentModelInfo = info // Keep global for external UI if needed, but primary is on message
                        case .chunk(let text):
                            if let index = self.messages.firstIndex(where: { $0.id == assistantID }) {
                                self.messages[index].text += text
                            }
                        case .suggestions(let foods):
                            if let index = self.messages.firstIndex(where: { $0.id == assistantID }) {
                                self.messages[index].suggestedFoods = foods
                            }
                        case .finalCleanText(let cleanText):
                            // Replace accumulated text (which may contain raw JSON) with cleaned version
                            if let index = self.messages.firstIndex(where: { $0.id == assistantID }) {
                                self.messages[index].text = cleanText
                            }
                        case .error(let msg):
                            self.errorMessage = msg
                        }
                    }
                }
                
                // LAYER 2 + 3: Free-text safety scan and re-ask
                if let index = self.messages.firstIndex(where: { $0.id == assistantID }) {
                    let finalText = self.messages[index].text
                    if let memory = try? await AIMemoryRepository.shared.fetchMemory() {
                        let detected = FoodSafetyValidator.shared.scanFreeText(finalText, against: memory)
                        if !detected.isEmpty {
                            await MainActor.run { self.healthSafetyApplied = true }
                            
                            let conditionsStr = memory.healthConditions.map { $0.name }.joined(separator: ", ")
                            let detectedStr = detected.joined(separator: ", ")
                            let reaskPrompt = """
                            Viết lại câu sau nhưng thay '\(detectedStr)' bằng thực phẩm an toàn cho người \(conditionsStr):
                            \(finalText)
                            """
                            
                            if let newText = try? await aiService.quickReask(prompt: reaskPrompt) {
                                await MainActor.run {
                                    self.messages[index].text = newText
                                }
                            }
                        }
                    }
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
            
            await MainActor.run {
                self.isStreaming = false
                self.isTyping = false
                
                // Finalize model info status on the last assistant message
                if let lastIndex = self.messages.lastIndex(where: { $0.role == .assistant }),
                   var info = self.messages[lastIndex].modelInfo {
                    info = AIModelInfo(name: info.name, provider: info.provider, status: "✓ Trả lời xong")
                    self.messages[lastIndex].modelInfo = info
                }
                
                self.currentModelInfo = nil
                
                // Trigger haptic on complete
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }
        }
        
        // Learning System extraction
        Task {
            let updates = await LearningService.shared.processMessage(trimmed)
            if !updates.isEmpty {
                await MainActor.run {
                    self.pendingMemoryUpdates = updates
                    self.showMemoryConfirmation = true
                }
            }
        }
    }
    
    // MARK: - Learning System State
    var pendingMemoryUpdates: [MemoryUpdate] = []
    var showMemoryConfirmation = false
    
    func confirmMemoryUpdates(_ updates: [MemoryUpdate]) {
        for update in updates {
            MemoryManager.shared.applyMemoryUpdate(update)
        }
        pendingMemoryUpdates = []
        showMemoryConfirmation = false
    }
    
    func logSuggestedFood(_ food: AISuggestedFood, mealType: String = "Ăn vặt") {
        let mealFood = food.toMealFoodModel()
        let date = Date()
        
        // Prioritize mealType from AI, and map common variants to standard UI types
        var rawMealType = food.mealType ?? mealType
        var finalMealType = "Ăn vặt" // Default
        
        let lower = rawMealType.lowercased()
        if lower.contains("sáng") {
            finalMealType = "Bữa sáng"
        } else if lower.contains("trưa") {
            finalMealType = "Bữa trưa"
        } else if lower.contains("tối") {
            finalMealType = "Bữa tối"
        } else if lower.contains("phụ") || lower.contains("vặt") || lower.contains("snack") {
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
