import Foundation

struct MacroAggregate: Identifiable {
    let id = UUID()
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double
    let totalCalories: Double
    let daysCount: Int
    
    var avgDailyProtein: Double { totalProtein / Double(max(daysCount, 1)) }
    var avgDailyCarbs: Double { totalCarbs / Double(max(daysCount, 1)) }
    var avgDailyFat: Double { totalFat / Double(max(daysCount, 1)) }
    var avgDailyCalories: Double { totalCalories / Double(max(daysCount, 1)) }
    
    var proteinPercentage: Double {
        guard totalCalories > 0 else { return 0 }
        return (totalProtein * 4.0 / totalCalories) * 100
    }
    var carbsPercentage: Double {
        guard totalCalories > 0 else { return 0 }
        return (totalCarbs * 4.0 / totalCalories) * 100
    }
    var fatPercentage: Double {
        guard totalCalories > 0 else { return 0 }
        return (totalFat * 9.0 / totalCalories) * 100
    }
}

struct MacroTarget {
    let protein: Double
    let carbs: Double
    let fat: Double
    let calories: Double
    
    var proteinGrams: Double { protein }
    var carbsGrams: Double { carbs }
    var fatGrams: Double { fat }
    
    static func `default`(calories: Double) -> MacroTarget {
        // Standard 30% Protein, 40% Carbs, 30% Fat
        MacroTarget(
            protein: (calories * 0.3) / 4.0,
            carbs: (calories * 0.4) / 4.0,
            fat: (calories * 0.3) / 9.0,
            calories: calories
        )
    }
}

struct MacroTrend {
    enum TrendDirection: String {
        case up, down, stable
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .stable: return "minus"
            }
        }
        
        var rawValueVN: String {
            switch self {
            case .up: return "Tăng"
            case .down: return "Giảm"
            case .stable: return "Ổn định"
            }
        }
    }
    
    let proteinTrend: TrendDirection
    let carbsTrend: TrendDirection
    let fatTrend: TrendDirection
}

struct WeeklyAggregate: Identifiable {
    let id = UUID()
    let weekNumber: Int
    let averageCalories: Double
    let minCalories: Double
    let maxCalories: Double
    let lastWeight: Double?
    let startDate: Date
    let endDate: Date
}

struct MonthlyAggregate: Identifiable {
    let id = UUID()
    let month: Int
    let year: Int
    let averageCalories: Double
    let minCalories: Double
    let maxCalories: Double
    let lastWeight: Double?
    let startDate: Date
    let endDate: Date
}
