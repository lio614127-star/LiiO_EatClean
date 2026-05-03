import Foundation

enum ChatRole: String, Codable {
    case user = "user"
    case assistant = "assistant"
}

struct ChatMessage: Identifiable, Codable {
    var id = UUID()
    let role: ChatRole
    let text: String
    let suggestedFoods: [AISuggestedFood]?
    
    var isUser: Bool {
        return role == .user
    }
}
