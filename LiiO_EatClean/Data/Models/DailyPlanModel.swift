import Foundation

enum RebalancePreference: String, Codable {
    case preserveMeals = "Giữ món, chỉnh khẩu phần"
    case flexibleSwap = "Có thể đổi món"
    case hybrid = "Hybrid"
}

struct RebalanceTrigger: Identifiable {
    let id = UUID()
    let type: TriggerType
    let deviation: Double
    let reason: String
    
    enum TriggerType {
        case overCalorie
        case underProtein
        case unplannedLargeMeal
        case significantSkip
        case lateNightUnderEating
    }
}

struct RebalanceResult: Codable {
    let summary: String
    let reason: String
    let oldExpectedTotals: MacroTotals
    let newExpectedTotals: MacroTotals
    let changedMeals: [ChangedMealSuggestion]
    let warnings: [String]?
    
    struct MacroTotals: Codable {
        let calories: Double
        let protein: Double
        let carbs: Double
        let fat: Double
    }
}

struct ChangedMealSuggestion: Codable, Identifiable {
    var id: String { plannedMealId }
    let plannedMealId: String
    let mealType: String
    let oldName: String
    let newName: String?
    let oldCalories: Double
    let newCalories: Double
    let oldProtein: Double
    let newProtein: Double
    let oldCarbs: Double
    let newCarbs: Double
    let oldFat: Double
    let newFat: Double
    let changeType: String // "portionAdjusted", "swapped", "removed", "added"
    let reason: String?
}

struct IdentifiableResult: Identifiable {
    let id = UUID()
    let result: RebalanceResult
}

struct DailyPlanModel: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var status: String // "draft", "active", "completed"
    var targetCalories: Double
    var targetProtein: Double
    var targetCarbs: Double
    var targetFat: Double
    var plannedMeals: [PlannedMealModel]
    
    // Rebalance Metadata
    var isRebalanced: Bool = false
    var rebalanceReason: String? = nil
    var rebalancedAt: Date? = nil
    var previousPlanSnapshot: Data? = nil
    
    init(id: UUID = UUID(), 
         date: Date = Date(), 
         status: String = "draft", 
         targetCalories: Double = 0.0, 
         targetProtein: Double = 0.0, 
         targetCarbs: Double = 0.0, 
         targetFat: Double = 0.0, 
         plannedMeals: [PlannedMealModel] = [],
         isRebalanced: Bool = false,
         rebalanceReason: String? = nil,
         rebalancedAt: Date? = nil,
         previousPlanSnapshot: Data? = nil) {
        self.id = id
        self.date = date
        self.status = status
        self.targetCalories = targetCalories
        self.targetProtein = targetProtein
        self.targetCarbs = targetCarbs
        self.targetFat = targetFat
        self.plannedMeals = plannedMeals
        self.isRebalanced = isRebalanced
        self.rebalanceReason = rebalanceReason
        self.rebalancedAt = rebalancedAt
        self.previousPlanSnapshot = previousPlanSnapshot
    }
}

struct PlannedMealModel: Identifiable, Codable, Equatable {
    let id: UUID
    var type: String // "Sáng", "Trưa", "Tối", "Ăn vặt"
    var convertedMealId: UUID? // Points to the actual Meal UUID once eaten (Legacy field)
    var status: String // "planned", "eaten", "skipped", "replaced"
    var actualMealLogId: UUID? // Linked Actual Meal ID
    var eatenAt: Date?
    var isLocked: Bool = false
    var foodItems: [PlannedFoodItemModel]
    
    init(id: UUID = UUID(), 
         type: String = "", 
         convertedMealId: UUID? = nil, 
         status: String = "planned",
         actualMealLogId: UUID? = nil,
         eatenAt: Date? = nil,
         isLocked: Bool = false,
         foodItems: [PlannedFoodItemModel] = []) {
        self.id = id
        self.type = type
        self.convertedMealId = convertedMealId
        self.status = status
        self.actualMealLogId = actualMealLogId
        self.eatenAt = eatenAt
        self.isLocked = isLocked
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
