import Foundation

struct MealModel: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var mealType: String
    var mealFoods: [MealFoodModel]
    
    init(id: UUID = UUID(), date: Date = Date(), mealType: String = "", mealFoods: [MealFoodModel] = []) {
        self.id = id
        self.date = date
        self.mealType = mealType
        self.mealFoods = mealFoods
    }
    
    var totalCalories: Double {
        mealFoods.reduce(0) { $0 + $1.caloriesSnapshot }
    }
}
