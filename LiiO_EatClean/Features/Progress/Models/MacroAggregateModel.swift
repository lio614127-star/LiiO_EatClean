import Foundation
import SwiftUI

struct MacroAggregate: Identifiable {
    let id = UUID()
    let totalProtein: Double    // grams
    let totalCarbs: Double      // grams
    let totalFat: Double        // grams
    let totalCalories: Double   // kcal
    let daysCount: Int          // number of days in range
    
    var proteinPercentage: Double {
        let proteinCals = totalProtein * 4
        guard totalCalories > 0 else { return 0 }
        return (proteinCals / totalCalories) * 100
    }
    
    var carbsPercentage: Double {
        let carbsCals = totalCarbs * 4
        guard totalCalories > 0 else { return 0 }
        return (carbsCals / totalCalories) * 100
    }
    
    var fatPercentage: Double {
        let fatCals = totalFat * 9
        guard totalCalories > 0 else { return 0 }
        return (fatCals / totalCalories) * 100
    }
    
    var avgDailyProtein: Double { daysCount > 0 ? totalProtein / Double(daysCount) : 0 }
    var avgDailyCarbs: Double { daysCount > 0 ? totalCarbs / Double(daysCount) : 0 }
    var avgDailyFat: Double { daysCount > 0 ? totalFat / Double(daysCount) : 0 }
}

struct MacroTarget {
    let proteinRatio: Double  // 0.30 = 30%
    let carbsRatio: Double    // 0.40 = 40%
    let fatRatio: Double      // 0.30 = 30%
    let dailyCalories: Double
    
    static func `default`(calories: Double) -> MacroTarget {
        MacroTarget(proteinRatio: 0.30, carbsRatio: 0.40, fatRatio: 0.30, dailyCalories: calories)
    }
    
    var proteinGrams: Double { (dailyCalories * proteinRatio) / 4 }
    var carbsGrams: Double { (dailyCalories * carbsRatio) / 4 }
    var fatGrams: Double { (dailyCalories * fatRatio) / 9 }
}

struct MacroTrend {
    let proteinTrend: TrendDirection
    let carbsTrend: TrendDirection
    let fatTrend: TrendDirection
    
    enum TrendDirection: String {
        case up = "↑"
        case down = "↓"
        case stable = "→"
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .stable: return "arrow.right"
            }
        }
        
        var color: (protein: Color, carbs: Color, fat: Color) {
            // Context-dependent: up protein = good, up fat = caution
            return (.blue, .purple, .orange)
        }
    }
}
