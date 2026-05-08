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
    
    // Custom Foods
    func fetchCustomFoods() async throws -> [FoodItemModel]
    func searchCustomFoods(query: String) async throws -> [FoodItemModel]
    func saveCustomFood(_ food: FoodItemModel) async throws
    func updateCustomFood(_ food: FoodItemModel) async throws
    func duplicateCustomFood(_ food: FoodItemModel) async throws -> FoodItemModel
}
