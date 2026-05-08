import Foundation

enum ChatRole: String, Codable {
    case user = "user"
    case assistant = "assistant"
}

struct ChatMessage: Identifiable, Codable {
    var id = UUID()
    let role: ChatRole
    var text: String
    var suggestedFoods: [AISuggestedFood]?
    var modelInfo: AIModelInfo?
    
    var isUser: Bool {
        return role == .user
    }
}
