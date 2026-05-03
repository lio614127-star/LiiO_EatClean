import Foundation

struct MealFoodModel: Identifiable, Codable {
    let id: UUID
    var quantity: Double
    let caloriesSnapshot: Double
    let proteinSnapshot: Double
    let carbsSnapshot: Double
    let fatSnapshot: Double
    var isEaten: Bool
    var mealType: String? // Added to track which meal category this belongs to in the cart
    var foodItem: FoodItemModel?
    
    init(id: UUID = UUID(), quantity: Double = 1.0, caloriesSnapshot: Double, proteinSnapshot: Double, carbsSnapshot: Double, fatSnapshot: Double, isEaten: Bool = true, mealType: String? = nil, foodItem: FoodItemModel? = nil) {
        self.id = id
        self.quantity = quantity
        self.caloriesSnapshot = caloriesSnapshot
        self.proteinSnapshot = proteinSnapshot
        self.carbsSnapshot = carbsSnapshot
        self.fatSnapshot = fatSnapshot
        self.isEaten = isEaten
        self.mealType = mealType
        self.foodItem = foodItem
    }
}
