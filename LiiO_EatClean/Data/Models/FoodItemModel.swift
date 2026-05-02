import Foundation

struct FoodItemModel: Identifiable, Codable {
    let id: UUID
    var name: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var servingSize: Double
    var source: String
    var apiId: String?
    var isCustom: Bool
    var lastUsed: Date?
    
    init(id: UUID = UUID(), name: String = "", calories: Double = 0.0, protein: Double = 0.0, carbs: Double = 0.0, fat: Double = 0.0, servingSize: Double = 100.0, source: String = "", apiId: String? = nil, isCustom: Bool = false, lastUsed: Date? = nil) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.servingSize = servingSize
        self.source = source
        self.apiId = apiId
        self.isCustom = isCustom
        self.lastUsed = lastUsed
    }
}

struct FoodItemDTO: Codable {
    let name: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let servingSize: Double
}
