import Foundation

struct APIKeyModel: Identifiable, Codable {
    let id: UUID
    var provider: String
    var key: String
    var isActive: Bool
    var lastUsed: Date?
    
    init(id: UUID = UUID(), provider: String = "", key: String = "", isActive: Bool = true, lastUsed: Date? = nil) {
        self.id = id
        self.provider = provider
        self.key = key
        self.isActive = isActive
        self.lastUsed = lastUsed
    }
}
