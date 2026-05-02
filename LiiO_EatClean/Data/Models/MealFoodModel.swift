import Foundation

struct MealFoodModel: Identifiable, Codable {
    let id: UUID
    var quantity: Double
    let caloriesSnapshot: Double
    let proteinSnapshot: Double
    let carbsSnapshot: Double
    let fatSnapshot: Double
    var foodItem: FoodItemModel?
    
    init(id: UUID = UUID(), quantity: Double = 1.0, caloriesSnapshot: Double, proteinSnapshot: Double, carbsSnapshot: Double, fatSnapshot: Double, foodItem: FoodItemModel? = nil) {
        self.id = id
        self.quantity = quantity
        self.caloriesSnapshot = caloriesSnapshot
        self.proteinSnapshot = proteinSnapshot
        self.carbsSnapshot = carbsSnapshot
        self.fatSnapshot = fatSnapshot
        self.foodItem = foodItem
    }
}
