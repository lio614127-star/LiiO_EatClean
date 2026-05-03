import Foundation
import CoreData

class MealRepository: MealRepositoryProtocol {
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.newBackgroundContext()) {
        self.context = context
    }
    
    func deleteAllMeals() async throws {
        try await context.perform {
            let request: NSFetchRequest<NSFetchRequestResult> = Meal.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            try self.context.execute(deleteRequest)
            
            let foodRequest: NSFetchRequest<NSFetchRequestResult> = MealFood.fetchRequest()
            let deleteFoodRequest = NSBatchDeleteRequest(fetchRequest: foodRequest)
            try self.context.execute(deleteFoodRequest)
            
            try self.context.save()
            // Clear status manager too
            MealFoodStatusManager.shared.clearAll()
        }
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
                            isEaten: MealFoodStatusManager.shared.isEaten(id: mf.id ?? UUID()),
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
                            isEaten: MealFoodStatusManager.shared.isEaten(id: mf.id ?? UUID()),
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
                
                // Save eaten status to Manager
                MealFoodStatusManager.shared.setEaten(id: food.id, isEaten: food.isEaten)
                
                // Link FoodItem if it exists, otherwise create it
                if let foodItemModel = food.foodItem {
                    let foodRequest: NSFetchRequest<FoodItem> = FoodItem.fetchRequest()
                    foodRequest.predicate = NSPredicate(format: "id == %@", foodItemModel.id as CVarArg)
                    if let foodEntity = try self.context.fetch(foodRequest).first {
                        mealFood.foodItem = foodEntity
                    } else {
                        // Create it!
                        let newFoodEntity = FoodItem(context: self.context)
                        newFoodEntity.id = foodItemModel.id
                        newFoodEntity.name = foodItemModel.name
                        newFoodEntity.calories = foodItemModel.calories
                        newFoodEntity.protein = foodItemModel.protein
                        newFoodEntity.carbs = foodItemModel.carbs
                        newFoodEntity.fat = foodItemModel.fat
                        newFoodEntity.servingSize = foodItemModel.servingSize
                        newFoodEntity.source = foodItemModel.source
                        newFoodEntity.apiId = foodItemModel.apiId
                        newFoodEntity.isCustom = foodItemModel.isCustom
                        newFoodEntity.lastUsed = Date()
                        mealFood.foodItem = newFoodEntity
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
