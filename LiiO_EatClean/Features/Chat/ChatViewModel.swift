import Foundation
import SwiftUI
import Observation

@Observable
class ChatViewModel {
    var messages: [ChatMessageModel] = []
    var isTyping = false
    var errorMessage: String?
    var healthSafetyApplied = false
    var currentSession: ChatSessionModel?
    
    var displayMessages: [ChatMessageModel] {
        var combined = messages
        
        // 1. Insert active user voice draft
        if let voiceDraft = ChatRealtimeStore.shared.activeVoiceDraftMessage,
           voiceDraft.sessionId == currentSession?.id {
            // Ensure we don't show a voice draft if we already received its official counterpart
            let hasOfficial = messages.contains { $0.clientId == voiceDraft.clientId }
            if !hasOfficial {
                combined.append(voiceDraft)
            }
        }
        
        // 2. Insert active assistant response draft
        if let assistantDraft = ChatRealtimeStore.shared.activeAssistantDraftMessage,
           assistantDraft.sessionId == currentSession?.id {
            let hasOfficial = messages.contains { $0.clientId == assistantDraft.clientId }
            if !hasOfficial {
                combined.append(assistantDraft)
            }
        }
        
        return combined
    }
    
    private let aiService = AIService.shared
    private let contextBuilder = ContextBuilder()
    private let mealRepository: MealRepositoryProtocol
    private let chatRepository: ChatRepositoryProtocol
    
    init(mealRepository: MealRepositoryProtocol = MealRepository(),
         chatRepository: ChatRepositoryProtocol = ChatRepository()) {
        self.mealRepository = mealRepository
        self.chatRepository = chatRepository
        
        Task {
            await loadInitialSession()
        }
        listenForRetries()
        listenForExternalMessages()
    }
    
    @MainActor
    private func loadInitialSession() async {
        do {
            if let session = try await chatRepository.fetchLatestActiveSession() {
                self.currentSession = session
                let fetchedMessages = try await chatRepository.fetchMessages(sessionId: session.id)
                self.messages = fetchedMessages
                
                if messages.isEmpty {
                    addWelcomeMessage()
                }
            } else {
                await startNewChat(isInitial: true)
            }
        } catch {
            print("Failed to load initial session: \(error)")
            addWelcomeMessage()
        }
    }
    
    @MainActor
    func startNewChat(isInitial: Bool = false) async {
        do {
            let session = try await chatRepository.createSession(title: "Hội thoại mới", source: "aiCoach")
            self.currentSession = session
            self.messages = []
            ChatRealtimeStore.shared.clearAllDrafts()
            addWelcomeMessage()
            print("[ChatDraft] cleared all drafts via startNewChat")
        } catch {
            print("Failed to create new session: \(error)")
        }
    }
    
    private func addWelcomeMessage() {
        let welcome = ChatMessageModel(role: .assistant, text: "Chào bạn! Mình là trợ lý dinh dưỡng cá nhân của bạn đây. Hôm nay bạn ăn uống thế nào rồi?", suggestedFoods: nil)
        messages.append(welcome)
        // Visual-only welcome: Do not persist into DB so voice/AI sessions remain clean
    }
    
    var currentModelInfo: AIModelInfo?
    var isStreaming = false
    
    func sendMessage(_ text: String, isRetry: Bool = false, pendingId: UUID? = nil, inputMode: String = "text") {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        Task { @MainActor in
            ChatRealtimeStore.shared.clearAllDrafts()
            print("[ChatDraft] cleared all drafts via sendMessage")
        }
        
        let userMessage = ChatMessageModel(role: .user, text: trimmed, inputMode: inputMode, suggestedFoods: nil)
        
        if !NetworkMonitor.shared.isConnected && !isRetry {
            messages.append(userMessage)
            PendingChatQueue.shared.enqueue(text: trimmed, conversationID: UUID())
            return
        }
        
        if isRetry {
            if let pid = pendingId {
                PendingChatQueue.shared.remove(id: pid)
            }
        } else {
            messages.append(userMessage)
        }
        
        // Save user message to CoreData
        if let sessionId = currentSession?.id {
            Task {
                try? await chatRepository.saveMessage(userMessage, sessionId: sessionId)
                
                // Update session title if it's the first user message
                if messages.filter({ $0.role == .user }).count == 1 {
                    let autoTitle = trimmed.prefix(30).description + (trimmed.count > 30 ? "..." : "")
                    try? await chatRepository.updateSessionMetadata(sessionId: sessionId, lastMessage: trimmed)
                    await MainActor.run {
                        self.currentSession?.title = autoTitle
                    }
                }
            }
        }
        
        errorMessage = nil
        currentModelInfo = nil
        
        // Only send last 20 messages for context efficiency
        let historyToSend = Array(messages.suffix(20))
        
        Task {
            do {
                let systemPrompt = try await contextBuilder.buildSystemPrompt(for: trimmed, strategy: .chat)
                let assistantID = UUID()
                
                await MainActor.run {
                    self.isTyping = true
                    self.isStreaming = true
                    self.messages.append(ChatMessageModel(id: assistantID, role: .assistant, text: "", suggestedFoods: nil))
                }
                
                let stream = aiService.sendChatMessageStream(
                    history: historyToSend, 
                    systemPrompt: systemPrompt,
                    isInternal: true
                )
                
                for try await result in stream {
                    await MainActor.run {
                        if self.isTyping { self.isTyping = false }
                        
                        switch result {
                        case .modelInfo(let info):
                            if let index = self.messages.firstIndex(where: { $0.id == assistantID }) {
                                self.messages[index].modelInfo = info
                            }
                            self.currentModelInfo = info
                        case .chunk(let text):
                            if let index = self.messages.firstIndex(where: { $0.id == assistantID }) {
                                self.messages[index].text += text
                            }
                        case .suggestions(let foods):
                            if let index = self.messages.firstIndex(where: { $0.id == assistantID }) {
                                let allowed = AICoachIntentDetector.shared.shouldAllowFoodSuggestions(for: trimmed)
                                self.messages[index].suggestedFoods = allowed ? foods : nil
                                print("[ChatRender] intent evaluated: userQuery='\(trimmed)', suggestedFoodsCount=\(foods.count), shouldShowFoodCards=\(allowed)")
                            }
                        case .finalCleanText(let cleanText):
                            if let index = self.messages.firstIndex(where: { $0.id == assistantID }) {
                                self.messages[index].text = cleanText
                            }
                        case .error(let msg):
                            self.errorMessage = msg
                        }
                    }
                }
                
                // Finalize and save assistant message
                if let index = self.messages.firstIndex(where: { $0.id == assistantID }) {
                    let finalAssistantMsg = self.messages[index]
                    if let sessionId = currentSession?.id {
                        try? await chatRepository.saveMessage(finalAssistantMsg, sessionId: sessionId)
                    }
                    
                    // Safety check
                    if let memory = try? await AIMemoryRepository.shared.fetchMemory() {
                        let detected = FoodSafetyValidator.shared.scanFreeText(finalAssistantMsg.text, against: memory)
                        if !detected.isEmpty {
                            await MainActor.run { self.healthSafetyApplied = true }
                            let conditionsStr = memory.healthConditions.map { $0.name }.joined(separator: ", ")
                            let detectedStr = detected.joined(separator: ", ")
                            let reaskPrompt = "Viết lại câu sau nhưng thay '\(detectedStr)' bằng thực phẩm an toàn cho người \(conditionsStr):\n\(finalAssistantMsg.text)"
                            
                            if let newText = try? await aiService.quickReask(prompt: reaskPrompt) {
                                await MainActor.run {
                                    self.messages[index].text = newText
                                    if let sessionId = currentSession?.id {
                                        // Update the message in DB with safer version
                                        Task { try? await chatRepository.saveMessage(self.messages[index], sessionId: sessionId) }
                                    }
                                }
                            }
                        }
                    }
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
                if let pid = pendingId {
                    PendingChatQueue.shared.markFailed(id: pid)
                }
            }
            
            await MainActor.run {
                self.isStreaming = false
                self.isTyping = false
                
                if let lastIndex = self.messages.lastIndex(where: { $0.role == .assistant }),
                   var info = self.messages[lastIndex].modelInfo {
                    info = AIModelInfo(name: info.name, provider: info.provider, status: "✓ Trả lời xong")
                    self.messages[lastIndex].modelInfo = info
                }
                
                self.currentModelInfo = nil
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                if let pid = pendingId, self.errorMessage == nil {
                    PendingChatQueue.shared.remove(id: pid)
                }
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
        var rawMealType = food.mealType ?? mealType
        var finalMealType = "Ăn vặt"
        
        let lower = rawMealType.lowercased()
        if lower.contains("sáng") { finalMealType = "Bữa sáng" }
        else if lower.contains("trưa") { finalMealType = "Bữa trưa" }
        else if lower.contains("tối") { finalMealType = "Bữa tối" }
        else if lower.contains("phụ") || lower.contains("vặt") || lower.contains("snack") { finalMealType = "Ăn vặt" }
        
        let meal = MealModel(date: date, mealType: finalMealType, mealFoods: [mealFood])
        
        Task {
            do {
                try await mealRepository.saveMeal(meal, for: date)
                BackgroundEnrichmentManager.shared.enrich(foods: [food.toFoodItemModel()])
                
                await MainActor.run {
                    let statusSuffix = (food.isEaten ?? false) ? "đã ăn" : "vào danh sách chờ"
                    let successMsg = ChatMessageModel(role: .assistant, text: "Đã thêm **\(food.name)** \(statusSuffix)! 👍", suggestedFoods: nil)
                    messages.append(successMsg)
                    if let sessionId = currentSession?.id {
                        Task { try? await chatRepository.saveMessage(successMsg, sessionId: sessionId) }
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Lỗi lưu món ăn: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Retry Logic
    private func listenForRetries() {
        NotificationCenter.default.addObserver(
            forName: .pendingChatReadyToSend,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let message = notification.userInfo?["message"] as? PendingMessage else { return }
            self?.sendMessage(message.text, isRetry: true, pendingId: message.id)
        }
    }
    
    // MARK: - Realtime Live Mirror Subscriptions
    private func listenForExternalMessages() {
        NotificationCenter.default.addObserver(
            forName: .chatMessageSavedExternally,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            guard let incoming = notification.object as? ChatMessageModel else { return }
            
            // Verify session matches
            guard incoming.sessionId == self.currentSession?.id else { return }
            
            // Deduplicate by clientId or id
            let alreadyExists = self.messages.contains {
                $0.id == incoming.id || ($0.clientId != nil && $0.clientId == incoming.clientId)
            }
            
            if !alreadyExists {
                print("[ChatRealtime] 🪞 Mirroring external message into active chat view: \(incoming.text.prefix(20))...")
                withAnimation {
                    self.messages.append(incoming)
                }
            }
        }
    }
}
