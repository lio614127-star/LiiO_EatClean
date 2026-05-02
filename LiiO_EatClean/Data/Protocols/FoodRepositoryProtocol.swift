import Foundation

protocol FoodRepositoryProtocol {
    func fetchAllFoods() async throws -> [FoodItemModel]
    func searchFoods(query: String) async throws -> [FoodItemModel]
    func searchLocalFoods(query: String) async throws -> [FoodItemModel]
    func fetchSuggestions() async throws -> [FoodItemModel]
    func saveFood(_ food: FoodItemModel) async throws
    func updateLastUsed(for id: UUID) async throws
    func deleteFood(by id: UUID) async throws
    func seedDatabaseIfNeeded() async throws
}
