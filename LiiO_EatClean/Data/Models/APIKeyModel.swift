import Foundation

struct APIKeyModel: Identifiable, Codable {
    let id: UUID
    var name: String?
    var provider: String
    var key: String
    var isActive: Bool
    var lastUsed: Date?
    var healthScore: Int
    var priority: Int
    var cooldownUntil: Date?
    var apiVersion: String? // "v1" or "v1beta"
    var isPaid: Bool?
    
    init(id: UUID = UUID(), 
         name: String? = nil,
         provider: String = "", 
         key: String = "", 
         isActive: Bool = true, 
         lastUsed: Date? = nil, 
         healthScore: Int = 100, 
         priority: Int = 0, 
         cooldownUntil: Date? = nil,
         apiVersion: String? = nil,
         isPaid: Bool? = nil) {
        self.id = id
        self.name = name
        self.provider = provider
        self.key = key
        self.isActive = isActive
        self.lastUsed = lastUsed
        self.healthScore = healthScore
        self.priority = priority
        self.cooldownUntil = cooldownUntil
        self.apiVersion = apiVersion
        self.isPaid = isPaid
    }
}
