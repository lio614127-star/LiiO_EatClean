import Foundation

struct UnitConversionEngine {
    static let shared = UnitConversionEngine()
    
    // Standard weights for Vietnamese units
    private let standardWeights: [String: Double] = [
        "chén": 200.0,
        "tô": 450.0,
        "dĩa": 350.0,
        "cái": 150.0,
        "quả": 100.0,
        "phần": 1.0,  // Serving multiplier
        "gram": 1.0,
        "g": 1.0
    ]
    
    /// Convert macro values when switching units
    func convert(food: FoodItemModel, to newUnit: String, newAmount: Double) -> FoodItemModel {
        var updated = food
        let currentWeight = food.weightInGrams ?? (standardWeights[food.unit?.lowercased() ?? ""] ?? 100.0)
        let targetWeightMultiplier = standardWeights[newUnit.lowercased()] ?? 100.0
        
        let actualNewWeight = newUnit.lowercased() == "gram" || newUnit.lowercased() == "g" 
            ? newAmount 
            : newAmount * targetWeightMultiplier
        
        // Base macro per 1 gram from original food
        let factor = actualNewWeight / currentWeight
        
        updated.calories = food.calories * factor
        updated.protein = food.protein * factor
        updated.carbs = food.carbs * factor
        updated.fat = food.fat * factor
        updated.unit = newUnit
        updated.weightInGrams = actualNewWeight
        
        return updated
    }
    
    func getStandardWeight(for unit: String) -> Double {
        standardWeights[unit.lowercased()] ?? 100.0
    }
    
    func formatDisplayUnit(unit: String?, weight: Double?) -> String {
        guard let unit = unit else { return "" }
        if unit.lowercased() == "gram" || unit.lowercased() == "g" {
            return "\(Int(weight ?? 0))g"
        }
        if let weight = weight {
            return "\(unit) (~\(Int(weight))g)"
        }
        return unit
    }
}
