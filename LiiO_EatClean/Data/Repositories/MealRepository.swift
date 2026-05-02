import Foundation
import CoreData

class MealRepository: MealRepositoryProtocol {
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.newBackgroundContext()) {
        self.context = context
    }
    
    func fetchMeals(by date: Date) async throws -> [MealModel] {
        return try await context.perform {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return [] }
            
            let request: NSFetchRequest<Meal> = Meal.fetchRequest()
            request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as CVarArg, endOfDay as CVarArg)
            
            let results = try self.context.fetch(request)
            return results.map { meal in
                var mealFoods: [MealFoodModel] = []
                if let foodsSet = meal.mealFoods as? Set<MealFood> {
                    mealFoods = foodsSet.map { mf in
                        var foodItemModel: FoodItemModel? = nil
                        if let foodEntity = mf.foodItem {
                            foodItemModel = FoodItemModel(
                                id: foodEntity.id ?? UUID(),
                                name: foodEntity.name ?? "",
                                calories: foodEntity.calories,
                                protein: foodEntity.protein,
                                carbs: foodEntity.carbs,
                                fat: foodEntity.fat,
                                servingSize: foodEntity.servingSize,
                                source: foodEntity.source ?? "",
                                apiId: foodEntity.apiId,
                                isCustom: foodEntity.isCustom,
                                lastUsed: foodEntity.lastUsed
                            )
                        }
                        
                        return MealFoodModel(
                            id: mf.id ?? UUID(),
                            quantity: mf.quantity,
                            caloriesSnapshot: mf.caloriesSnapshot,
                            proteinSnapshot: mf.proteinSnapshot,
                            carbsSnapshot: mf.carbsSnapshot,
                            fatSnapshot: mf.fatSnapshot,
                            foodItem: foodItemModel
                        )
                    }
                }
                
                return MealModel(
                    id: meal.id ?? UUID(),
                    date: meal.date ?? date,
                    mealType: meal.mealType ?? "",
                    mealFoods: mealFoods
                )
            }
        }
    }
    
    func fetchMeals(from startDate: Date, to endDate: Date) async throws -> [MealModel] {
        return try await context.perform {
            let request: NSFetchRequest<Meal> = Meal.fetchRequest()
            request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as CVarArg, endDate as CVarArg)
            
            let results = try self.context.fetch(request)
            return results.map { meal in
                var mealFoods: [MealFoodModel] = []
                if let foodsSet = meal.mealFoods as? Set<MealFood> {
                    mealFoods = foodsSet.map { mf in
                        MealFoodModel(
                            id: mf.id ?? UUID(),
                            quantity: mf.quantity,
                            caloriesSnapshot: mf.caloriesSnapshot,
                            proteinSnapshot: mf.proteinSnapshot,
                            carbsSnapshot: mf.carbsSnapshot,
                            fatSnapshot: mf.fatSnapshot,
                            foodItem: nil // Not needed for aggregate charts
                        )
                    }
                }
                
                return MealModel(
                    id: meal.id ?? UUID(),
                    date: meal.date ?? Date(),
                    mealType: meal.mealType ?? "",
                    mealFoods: mealFoods
                )
            }
        }
    }
    
    func fetchDailyLog(by date: Date) async throws -> DailyLogModel? {
        return nil
    }
    
    func saveMeal(_ meal: MealModel, for date: Date) async throws {
        try await context.perform {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
            
            // Check if meal of this type already exists for this date
            let request: NSFetchRequest<Meal> = Meal.fetchRequest()
            request.predicate = NSPredicate(format: "date >= %@ AND date < %@ AND mealType ==[c] %@", startOfDay as CVarArg, endOfDay as CVarArg, meal.mealType)
            
            let existingMeals = try self.context.fetch(request)
            let targetMeal: Meal
            
            if let firstMeal = existingMeals.first {
                targetMeal = firstMeal
            } else {
                targetMeal = Meal(context: self.context)
                targetMeal.id = meal.id
                targetMeal.date = date
                targetMeal.mealType = meal.mealType
            }
            
            for food in meal.mealFoods {
                let mealFood = MealFood(context: self.context)
                mealFood.id = food.id
                mealFood.quantity = food.quantity
                mealFood.caloriesSnapshot = food.caloriesSnapshot
                mealFood.proteinSnapshot = food.proteinSnapshot
                mealFood.carbsSnapshot = food.carbsSnapshot
                mealFood.fatSnapshot = food.fatSnapshot
                
                // Link FoodItem if it exists
                if let foodItemId = food.foodItem?.id {
                    let foodRequest: NSFetchRequest<FoodItem> = FoodItem.fetchRequest()
                    foodRequest.predicate = NSPredicate(format: "id == %@", foodItemId as CVarArg)
                    if let foodEntity = try self.context.fetch(foodRequest).first {
                        mealFood.foodItem = foodEntity
                    }
                }
                
                targetMeal.addToMealFoods(mealFood)
            }
            try self.context.save()
        }
    }
    
    func deleteMeal(by id: UUID) async throws {
        try await context.perform {
            let request: NSFetchRequest<Meal> = Meal.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            if let meal = try self.context.fetch(request).first {
                self.context.delete(meal)
                try self.context.save()
            }
        }
    }
    
    func deleteMealFood(by id: UUID) async throws {
        try await context.perform {
            let request: NSFetchRequest<MealFood> = MealFood.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            if let mealFood = try self.context.fetch(request).first {
                let parentMeal = mealFood.meal
                self.context.delete(mealFood)
                
                // Clean up parent meal if empty
                if let parentMeal = parentMeal, let remainingFoods = parentMeal.mealFoods, remainingFoods.count == 0 {
                    self.context.delete(parentMeal)
                }
                
                try self.context.save()
            }
        }
    }
    
    func saveDailyLog(_ log: DailyLogModel) async throws {
        // Implementation stub
    }
}
