import Foundation

struct APIKeyModel: Identifiable, Codable {
    let id: UUID
    var provider: String
    var key: String
    var isActive: Bool
    var lastUsed: Date?
    var healthScore: Int
    var priority: Int
    var cooldownUntil: Date?
    
    init(id: UUID = UUID(), provider: String = "", key: String = "", isActive: Bool = true, lastUsed: Date? = nil, healthScore: Int = 100, priority: Int = 0, cooldownUntil: Date? = nil) {
        self.id = id
        self.provider = provider
        self.key = key
        self.isActive = isActive
        self.lastUsed = lastUsed
        self.healthScore = healthScore
        self.priority = priority
        self.cooldownUntil = cooldownUntil
    }
}
