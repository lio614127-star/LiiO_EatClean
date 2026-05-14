import Foundation

enum ChatMessageStatus: String, Codable {
    case transcribing
    case sending
    case thinking
    case streaming
    case speaking
    case done
    case error
}

enum ChatRole: String, Codable {
    case user = "user"
    case assistant = "assistant"
}

struct ChatMessageModel: Identifiable, Codable {
    var id = UUID()
    var sessionId: UUID?
    let role: ChatRole
    var text: String
    var createdAt: Date = Date()
    var updatedAt: Date?
    
    // Realtime & Transient State
    var status: ChatMessageStatus?
    var clientId: String? // Matches transient drafts to persisted models to prevent double inserts
    
    // Voice & Mode
    var inputMode: String = "text" // text / voice
    var outputMode: String? // text / voice
    
    // Linked Data
    var suggestedFoods: [AISuggestedFood]?
    var modelInfo: AIModelInfo?
    var isError: Bool = false
    
    var isUser: Bool {
        return role == .user
    }
}
