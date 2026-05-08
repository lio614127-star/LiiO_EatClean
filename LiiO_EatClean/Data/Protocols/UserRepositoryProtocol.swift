import Foundation

protocol UserRepositoryProtocol {
    func fetchUser() async throws -> UserModel?
    func saveUser(_ user: UserModel) async throws
    
    func fetchWeightEntries() async throws -> [WeightEntryModel]
    func saveWeightEntry(_ entry: WeightEntryModel) async throws
    
    func fetchAPIKeys() async throws -> [APIKeyModel]
    func saveAPIKey(_ key: APIKeyModel) async throws
    func deleteAPIKey(id: UUID) async throws
    
    func fetchWaterLog(for date: Date) async throws -> Double
    func addWater(amount: Double, for date: Date) async throws
    func resetWater(for date: Date) async throws
    
    func fetchStreak() async throws -> StreakModel?
    func saveStreak(_ streak: StreakModel) async throws
}
