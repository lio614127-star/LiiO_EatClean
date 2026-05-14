import Foundation
import Observation

@Observable
class ChatRealtimeStore {
    static let shared = ChatRealtimeStore()
    
    var activeVoiceDraftMessage: ChatMessageModel?
    var activeAssistantDraftMessage: ChatMessageModel?
    
    private init() {}
    
    // MARK: - User Voice Draft Mechanics
    
    func updateVoiceDraft(text: String, sessionId: UUID?, clientId: String) {
        if activeVoiceDraftMessage == nil {
            activeVoiceDraftMessage = ChatMessageModel(
                id: UUID(),
                sessionId: sessionId,
                role: .user,
                text: text,
                status: .transcribing,
                clientId: clientId,
                inputMode: "voice"
            )
        } else {
            activeVoiceDraftMessage?.text = text
            activeVoiceDraftMessage?.status = .transcribing
            activeVoiceDraftMessage?.clientId = clientId
        }
    }
    
    func finalizeVoiceDraft() {
        activeVoiceDraftMessage = nil
    }
    
    // MARK: - Assistant Draft Mechanics
    
    func startAssistantDraft(sessionId: UUID?, clientId: String) {
        activeAssistantDraftMessage = ChatMessageModel(
            id: UUID(),
            sessionId: sessionId,
            role: .assistant,
            text: "Đang phân tích...",
            status: .thinking,
            clientId: clientId,
            inputMode: "text"
        )
    }
    
    func updateAssistantDraft(text: String, status: ChatMessageStatus = .streaming) {
        activeAssistantDraftMessage?.text = text
        activeAssistantDraftMessage?.status = status
    }
    
    func finalizeAssistantDraft() {
        activeAssistantDraftMessage = nil
    }
    
    func clearAllDrafts() {
        activeVoiceDraftMessage = nil
        activeAssistantDraftMessage = nil
    }
}

// Custom Notification helper to allow loose coupling across modules
extension Notification.Name {
    static let chatMessageSavedExternally = Notification.Name("ChatMessageSavedExternally")
}
