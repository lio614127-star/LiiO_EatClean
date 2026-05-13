import Foundation

struct MealModel: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var mealType: String
    var source: String // "manual", "homeQuickLog", "mealsTab", "plannedMeal", "voice", "barcode", "aiCoach"
    var linkedPlannedMealId: UUID?
    var mealFoods: [MealFoodModel]
    
    init(id: UUID = UUID(), 
         date: Date = Date(), 
         mealType: String = "", 
         source: String = "manual",
         linkedPlannedMealId: UUID? = nil,
         mealFoods: [MealFoodModel] = []) {
        self.id = id
        self.date = date
        self.mealType = mealType
        self.source = source
        self.linkedPlannedMealId = linkedPlannedMealId
        self.mealFoods = mealFoods
    }
    
    var totalCalories: Double {
        mealFoods.reduce(0) { $0 + $1.caloriesSnapshot }
    }
}
