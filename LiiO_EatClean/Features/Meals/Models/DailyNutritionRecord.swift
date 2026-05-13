import Foundation

struct DailyNutritionRecord: Identifiable {
    let id: UUID = UUID()
    let date: Date
    let dailyPlan: DailyPlanModel?
    let actualMeals: [MealModel]
    let adherence: MealAdherenceResult
    
    var targetCalories: Double { dailyPlan?.targetCalories ?? 2000 }
    var targetProtein: Double { dailyPlan?.targetProtein ?? 150 }
    
    var actualCalories: Double {
        actualMeals.reduce(0) { $0 + $1.totalCalories }
    }
    
    var actualProtein: Double {
        actualMeals.reduce(0) { sum, meal in
            sum + meal.mealFoods.reduce(0) { $0 + ($1.proteinSnapshot * $1.quantity) }
        }
    }
    
    // ⚡ Phase 28: Rebalance Helpers
    var actualTotals: RebalanceResult.MacroTotals {
        let calories = actualCalories
        let protein = actualProtein
        let carbs = actualMeals.reduce(0) { sum, meal in
            sum + meal.mealFoods.reduce(0) { $0 + ($1.carbsSnapshot * $1.quantity) }
        }
        let fat = actualMeals.reduce(0) { sum, meal in
            sum + meal.mealFoods.reduce(0) { $0 + ($1.fatSnapshot * $1.quantity) }
        }
        return RebalanceResult.MacroTotals(calories: calories, protein: protein, carbs: carbs, fat: fat)
    }
    
    var remainingPlannedTotals: RebalanceResult.MacroTotals {
        guard let dailyPlan = dailyPlan else { return RebalanceResult.MacroTotals(calories: 0, protein: 0, carbs: 0, fat: 0) }
        let planned = dailyPlan.plannedMeals.filter { $0.status == "planned" }
        
        let calories = planned.reduce(0) { $0 + $1.totalCalories }
        let protein = planned.reduce(0) { sum, meal in
            sum + meal.foodItems.reduce(0) { $0 + $1.protein }
        }
        let carbs = planned.reduce(0) { sum, meal in
            sum + meal.foodItems.reduce(0) { $0 + $1.carbs }
        }
        let fat = planned.reduce(0) { sum, meal in
            sum + meal.foodItems.reduce(0) { $0 + $1.fat }
        }
        return RebalanceResult.MacroTotals(calories: calories, protein: protein, carbs: carbs, fat: fat)
    }
    
    var targetTotals: RebalanceResult.MacroTotals {
        RebalanceResult.MacroTotals(
            calories: dailyPlan?.targetCalories ?? 2000,
            protein: dailyPlan?.targetProtein ?? 150,
            carbs: dailyPlan?.targetCarbs ?? 200,
            fat: dailyPlan?.targetFat ?? 60
        )
    }
    
    // Grouped timeline items
    var timelineItems: [TimelineItem] {
        var items: [TimelineItem] = []
        
        // Define meal types in order (canonical strings from MealPlanViewModel)
        let mealTypes = ["Bữa sáng", "Bữa trưa", "Bữa tối", "Ăn vặt"]
        
        for type in mealTypes {
            // Find planned meal for this type
            let planned = dailyPlan?.plannedMeals.first { $0.type == type }
            
            // Find actual meals for this type
            let actuals = actualMeals.filter { $0.mealType == type }
            
            if planned != nil || !actuals.isEmpty {
                items.append(TimelineItem(type: type, planned: planned, actuals: actuals))
            }
        }
        
        // Add "Other" if any actual meal doesn't match standard types
        let others = actualMeals.filter { !mealTypes.contains($0.mealType) }
        if !others.isEmpty {
            items.append(TimelineItem(type: "Khác", planned: nil, actuals: others))
        }
        
        return items
    }
}

struct TimelineItem: Identifiable {
    let id: UUID = UUID()
    let type: String
    let planned: PlannedMealModel?
    let actuals: [MealModel]
}
