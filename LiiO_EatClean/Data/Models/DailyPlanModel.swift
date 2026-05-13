import Foundation

struct DailyPlanModel: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var status: String // "draft", "active", "completed"
    var targetCalories: Double
    var targetProtein: Double
    var targetCarbs: Double
    var targetFat: Double
    var plannedMeals: [PlannedMealModel]
    
    init(id: UUID = UUID(), date: Date = Date(), status: String = "draft", targetCalories: Double = 0.0, targetProtein: Double = 0.0, targetCarbs: Double = 0.0, targetFat: Double = 0.0, plannedMeals: [PlannedMealModel] = []) {
        self.id = id
        // Normalize date to start of day by default if needed, though usually handled by Repository
        self.date = date
        self.status = status
        self.targetCalories = targetCalories
        self.targetProtein = targetProtein
        self.targetCarbs = targetCarbs
        self.targetFat = targetFat
        self.plannedMeals = plannedMeals
    }
}

struct PlannedMealModel: Identifiable, Codable, Equatable {
    let id: UUID
    var type: String // "Sáng", "Trưa", "Tối", "Ăn vặt"
    var convertedMealId: UUID? // Points to the actual Meal UUID once eaten (Legacy field)
    var status: String // "planned", "eaten", "skipped", "replaced"
    var actualMealLogId: UUID? // Linked Actual Meal ID
    var eatenAt: Date?
    var foodItems: [PlannedFoodItemModel]
    
    init(id: UUID = UUID(), 
         type: String = "", 
         convertedMealId: UUID? = nil, 
         status: String = "planned",
         actualMealLogId: UUID? = nil,
         eatenAt: Date? = nil,
         foodItems: [PlannedFoodItemModel] = []) {
        self.id = id
        self.type = type
        self.convertedMealId = convertedMealId
        self.status = status
        self.actualMealLogId = actualMealLogId
        self.eatenAt = eatenAt
        self.foodItems = foodItems
    }
    
    var totalCalories: Double {
        foodItems.reduce(0) { $0 + $1.calories }
    }
}

struct PlannedFoodItemModel: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var servingSize: Double
    
    init(id: UUID = UUID(), name: String = "", calories: Double = 0.0, protein: Double = 0.0, carbs: Double = 0.0, fat: Double = 0.0, servingSize: Double = 1.0) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.servingSize = servingSize
    }
}
