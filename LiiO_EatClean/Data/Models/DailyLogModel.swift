import Foundation

struct DailyLogModel: Identifiable, Codable {
    let id: UUID
    var date: Date
    var waterIntake: Double
    var notes: String
    var meals: [MealModel]
    
    init(id: UUID = UUID(), date: Date = Date(), waterIntake: Double = 0.0, notes: String = "", meals: [MealModel] = []) {
        self.id = id
        self.date = date
        self.waterIntake = waterIntake
        self.notes = notes
        self.meals = meals
    }
}
