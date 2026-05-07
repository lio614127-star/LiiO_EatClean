import Foundation

actor APIKeyPoolManager {
    private var keys: [APIKeyModel] = []
    private let repository: UserRepositoryProtocol
    
    init(repository: UserRepositoryProtocol) {
        self.repository = repository
    }
    
    func loadKeys() async throws {
        self.keys = try await repository.fetchAPIKeys()
    }
    
    func getBestKey() -> APIKeyModel? {
        return keys.filter { key in
            guard key.isActive else { return false }
            if let cooldown = key.cooldownUntil {
                return cooldown < Date()
            }
            return true
        }
        .sorted { $0.priority > $1.priority }
        .first
    }
    
    func reportError(keyID: UUID, statusCode: Int) async throws {
        guard let index = keys.firstIndex(where: { $0.id == keyID }) else { return }
        var updatedKey = keys[index]
        
        // Handle specific status codes
        if statusCode == 401 || statusCode == 403 {
            updatedKey.isActive = false
            updatedKey.healthScore = 0
        } else if statusCode == 429 {
            updatedKey.cooldownUntil = Date().addingTimeInterval(60) // 60s cooldown
        } else if statusCode == -1001 { // Timeout
            updatedKey.cooldownUntil = Date().addingTimeInterval(30) // 30s cooldown
        }
        
        // Decrease health score
        updatedKey.healthScore = max(0, updatedKey.healthScore - 5)
        
        keys[index] = updatedKey
        try await repository.saveAPIKey(updatedKey)
    }
    
    func reportSuccess(keyID: UUID) async throws {
        guard let index = keys.firstIndex(where: { $0.id == keyID }) else { return }
        var updatedKey = keys[index]
        
        updatedKey.healthScore = min(100, updatedKey.healthScore + 1)
        updatedKey.cooldownUntil = nil
        updatedKey.lastUsed = Date()
        
        keys[index] = updatedKey
        try await repository.saveAPIKey(updatedKey)
    }
}
