import Foundation

protocol MealRepositoryProtocol {
    func fetchMeals(by date: Date) async throws -> [MealModel]
    func fetchMeals(from startDate: Date, to endDate: Date) async throws -> [MealModel]
    func fetchDailyLog(by date: Date) async throws -> DailyLogModel?
    func saveMeal(_ meal: MealModel, for date: Date) async throws
    func deleteMeal(by id: UUID) async throws
    func deleteMealFood(by id: UUID) async throws
    func saveDailyLog(_ log: DailyLogModel) async throws
    func updateMealFoodStatus(id: UUID, isEaten: Bool) async throws
}
