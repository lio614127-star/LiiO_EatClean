import Foundation

actor APIKeyPoolManager {
    static let shared = APIKeyPoolManager(repository: UserRepository())
    
    private var keys: [APIKeyModel] = []
    private var lastLoaded: Date? = nil
    private let repository: UserRepositoryProtocol
    
    init(repository: UserRepositoryProtocol = UserRepository()) {
        self.repository = repository
    }
    
    func getKeys() -> [APIKeyModel] {
        return keys
    }
    
    func loadKeys(force: Bool = false) async throws {
        if !force, let last = lastLoaded, Date().timeIntervalSince(last) < 10 {
            return // Skip redundant load within 10s
        }
        self.keys = try await repository.fetchAPIKeys()
        self.lastLoaded = Date()
    }
    
    func getBestKey(for task: AIRequestType) -> APIKeyModel? {
        let activeKeys = keys.filter { key in
            guard key.isActive else { return false }
            if let cooldown = key.cooldownUntil {
                return cooldown < Date()
            }
            return true
        }
        
        let isHeavy = (task == .healthReasoning || task == .weeklyPlan || task == .trendAnalysis)
        
        return activeKeys.sorted { (k1, k2) -> Bool in
            let p1 = k1.isPaid == true
            let p2 = k2.isPaid == true
            
            // Priority 0: Health score (0 is always last)
            if (k1.healthScore == 0) != (k2.healthScore == 0) {
                return k1.healthScore > k2.healthScore
            }
            
            // Priority 1: Tier matching
            if isHeavy {
                if p1 != p2 { return p1 } // Paid first for heavy tasks
            } else {
                if p1 != p2 { return !p1 } // Free first for light tasks
            }
            
            // Priority 2: Health score
            if k1.healthScore != k2.healthScore {
                return k1.healthScore > k2.healthScore
            }
            
            // Priority 3: Manual priority
            return k1.priority > k2.priority
        }.first
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
            updatedKey.healthScore = max(0, updatedKey.healthScore - 10) // Heavier penalty for 429
        } else if statusCode == -1001 { // Timeout
            updatedKey.cooldownUntil = Date().addingTimeInterval(30) // 30s cooldown
            updatedKey.healthScore = max(0, updatedKey.healthScore - 5)
        } else {
            updatedKey.healthScore = max(0, updatedKey.healthScore - 5)
        }
        
        keys[index] = updatedKey
        try await repository.saveAPIKey(updatedKey)
    }
    
    func reportSuccess(keyID: UUID) async throws {
        guard let index = keys.firstIndex(where: { $0.id == keyID }) else { return }
        var updatedKey = keys[index]
        
        // Faster recovery (+5 per success)
        updatedKey.healthScore = min(100, updatedKey.healthScore + 5)
        updatedKey.cooldownUntil = nil
        updatedKey.lastUsed = Date()
        
        keys[index] = updatedKey
        try await repository.saveAPIKey(updatedKey)
    }
}
