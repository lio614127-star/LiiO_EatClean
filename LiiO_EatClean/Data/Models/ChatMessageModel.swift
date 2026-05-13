import Foundation

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
