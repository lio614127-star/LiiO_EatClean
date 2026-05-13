import Foundation
import CoreData

class MealRepository: MealRepositoryProtocol {
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
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
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return [] }
        
        let request: NSFetchRequest<Meal> = Meal.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as CVarArg, endOfDay as CVarArg)
        request.returnsObjectsAsFaults = false
        request.includesPendingChanges = true
        
        return try await context.perform {
            self.context.processPendingChanges()
            let results = try self.context.fetch(request)
            let mappedResults: [MealModel] = results.map { meal in
                var mealFoods: [MealFoodModel] = []
                
                // Use KVC to avoid missing member issues
                if let foods = meal.value(forKey: "mealFoods") {
                    if let foodsSet = foods as? Set<NSManagedObject> {
                        mealFoods = foodsSet.map { mf in
                            self.mapMealFood(mf, date: date)
                        }.sorted(by: { $0.id.uuidString < $1.id.uuidString })
                    } else if let foodsOrderedSet = foods as? NSOrderedSet {
                        mealFoods = foodsOrderedSet.array.compactMap { $0 as? NSManagedObject }.map { mf in
                            self.mapMealFood(mf, date: date)
                        }.sorted(by: { $0.id.uuidString < $1.id.uuidString })
                    }
                }
                
                return MealModel(
                    id: meal.value(forKey: "id") as? UUID ?? UUID(),
                    date: meal.value(forKey: "date") as? Date ?? date,
                    mealType: meal.value(forKey: "mealType") as? String ?? "",
                    source: meal.value(forKey: "source") as? String ?? "manual",
                    linkedPlannedMealId: meal.value(forKey: "linkedPlannedMealId") as? UUID,
                    mealFoods: mealFoods
                )
            }
            return mappedResults
        }
    }
    
    func fetchMeals(from startDate: Date, to endDate: Date) async throws -> [MealModel] {
        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "Meal")
            request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as CVarArg, endDate as CVarArg)
            request.returnsObjectsAsFaults = false
            
            let results = try self.context.fetch(request)
            let mappedResults: [MealModel] = results.map { meal in
                var mealFoods: [MealFoodModel] = []
                if let foods = meal.value(forKey: "mealFoods") {
                    if let foodsSet = foods as? Set<NSManagedObject> {
                        mealFoods = foodsSet.map { mf in
                            self.mapMealFood(mf, date: startDate)
                        }.sorted(by: { $0.id.uuidString < $1.id.uuidString })
                    } else if let foodsOrderedSet = foods as? NSOrderedSet {
                        mealFoods = foodsOrderedSet.array.compactMap { $0 as? NSManagedObject }.map { mf in
                            self.mapMealFood(mf, date: startDate)
                        }.sorted(by: { $0.id.uuidString < $1.id.uuidString })
                    }
                }
                
                return MealModel(
                    id: meal.value(forKey: "id") as? UUID ?? UUID(),
                    date: meal.value(forKey: "date") as? Date ?? Date(),
                    mealType: meal.value(forKey: "mealType") as? String ?? "",
                    source: meal.value(forKey: "source") as? String ?? "manual",
                    linkedPlannedMealId: meal.value(forKey: "linkedPlannedMealId") as? UUID,
                    mealFoods: mealFoods
                )
            }
            return mappedResults
        }
    }
    
    private func mapMealFood(_ mf: NSManagedObject, date: Date) -> MealFoodModel {
        var foodItemModel: FoodItemModel? = nil
        if let foodEntity = mf.value(forKey: "foodItem") as? NSManagedObject {
            foodItemModel = FoodItemModel(
                id: foodEntity.value(forKey: "id") as? UUID ?? UUID(),
                name: foodEntity.value(forKey: "name") as? String ?? "",
                calories: foodEntity.value(forKey: "calories") as? Double ?? 0,
                protein: foodEntity.value(forKey: "protein") as? Double ?? 0,
                carbs: foodEntity.value(forKey: "carbs") as? Double ?? 0,
                fat: foodEntity.value(forKey: "fat") as? Double ?? 0,
                servingSize: foodEntity.value(forKey: "servingSize") as? Double ?? 100.0,
                source: foodEntity.value(forKey: "source") as? String ?? "",
                apiId: foodEntity.value(forKey: "apiId") as? String,
                isCustom: foodEntity.value(forKey: "isCustom") as? Bool ?? false,
                lastUsed: foodEntity.value(forKey: "lastUsed") as? Date,
                unit: foodEntity.value(forKey: "unit") as? String,
                weightInGrams: foodEntity.value(forKey: "weightInGrams") as? Double ?? 0,
                ingredients: {
                    if let json = (foodEntity.value(forKey: "ingredientsJson") as? String)?.data(using: .utf8) {
                        return try? JSONDecoder().decode([IngredientModel].self, from: json)
                    }
                    return nil
                }(),
                instructions: {
                    if let json = (foodEntity.value(forKey: "instructionsJson") as? String)?.data(using: .utf8) {
                        return try? JSONDecoder().decode([String].self, from: json)
                    }
                    return nil
                }()
            )
        }
        
        let id = mf.value(forKey: "id") as? UUID ?? UUID()
        return MealFoodModel(
            id: id,
            quantity: mf.value(forKey: "quantity") as? Double ?? 1.0,
            caloriesSnapshot: mf.value(forKey: "caloriesSnapshot") as? Double ?? 0,
            proteinSnapshot: mf.value(forKey: "proteinSnapshot") as? Double ?? 0,
            carbsSnapshot: mf.value(forKey: "carbsSnapshot") as? Double ?? 0,
            fatSnapshot: mf.value(forKey: "fatSnapshot") as? Double ?? 0,
            isEaten: MealFoodStatusManager.shared.isEaten(id: id),
            foodItem: foodItemModel
        )
    }
    
    func fetchDailyLog(by date: Date) async throws -> DailyLogModel? {
        return nil
    }
    
    func saveMeal(_ meal: MealModel, for date: Date) async throws {
        try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "Meal")
            request.predicate = NSPredicate(format: "id == %@", meal.id as CVarArg)
            
            let existingMeals = try self.context.fetch(request)
            let targetMeal: NSManagedObject
            
            if let firstMeal = existingMeals.first {
                targetMeal = firstMeal
                targetMeal.setValue(date, forKey: "date")
                targetMeal.setValue(meal.mealType, forKey: "mealType")
                targetMeal.setValue(meal.source, forKey: "source")
                targetMeal.setValue(meal.linkedPlannedMealId, forKey: "linkedPlannedMealId")
                
                // CRITICAL: Delete existing MealFoods to avoid duplication
                if let oldFoods = targetMeal.value(forKey: "mealFoods") as? NSSet {
                    for case let oldFood as NSManagedObject in oldFoods {
                        self.context.delete(oldFood)
                    }
                }
            } else {
                targetMeal = NSEntityDescription.insertNewObject(forEntityName: "Meal", into: self.context)
                targetMeal.setValue(meal.id, forKey: "id")
                targetMeal.setValue(date, forKey: "date")
                targetMeal.setValue(meal.mealType, forKey: "mealType")
                targetMeal.setValue(meal.source, forKey: "source")
                targetMeal.setValue(meal.linkedPlannedMealId, forKey: "linkedPlannedMealId")
            }
            
            for food in meal.mealFoods {
                let mealFood = NSEntityDescription.insertNewObject(forEntityName: "MealFood", into: self.context)
                mealFood.setValue(food.id, forKey: "id")
                mealFood.setValue(food.quantity, forKey: "quantity")
                mealFood.setValue(food.caloriesSnapshot, forKey: "caloriesSnapshot")
                mealFood.setValue(food.proteinSnapshot, forKey: "proteinSnapshot")
                mealFood.setValue(food.carbsSnapshot, forKey: "carbsSnapshot")
                mealFood.setValue(food.fatSnapshot, forKey: "fatSnapshot")
                mealFood.setValue(targetMeal, forKey: "meal")
                
                // Save eaten status to Manager
                MealFoodStatusManager.shared.setEaten(id: food.id, isEaten: food.isEaten)
                
                if let foodItemModel = food.foodItem {
                    let foodRequest = NSFetchRequest<NSManagedObject>(entityName: "FoodItem")
                    foodRequest.predicate = NSPredicate(format: "id == %@", foodItemModel.id as CVarArg)
                    if let foodEntity = try self.context.fetch(foodRequest).first {
                        mealFood.setValue(foodEntity, forKey: "foodItem")
                    } else {
                        let newFoodEntity = NSEntityDescription.insertNewObject(forEntityName: "FoodItem", into: self.context)
                        newFoodEntity.setValue(foodItemModel.id, forKey: "id")
                        newFoodEntity.setValue(foodItemModel.name, forKey: "name")
                        newFoodEntity.setValue(foodItemModel.calories, forKey: "calories")
                        newFoodEntity.setValue(foodItemModel.protein, forKey: "protein")
                        newFoodEntity.setValue(foodItemModel.carbs, forKey: "carbs")
                        newFoodEntity.setValue(foodItemModel.fat, forKey: "fat")
                        newFoodEntity.setValue(foodItemModel.servingSize, forKey: "servingSize")
                        newFoodEntity.setValue(foodItemModel.source, forKey: "source")
                        newFoodEntity.setValue(foodItemModel.apiId, forKey: "apiId")
                        newFoodEntity.setValue(foodItemModel.isCustom, forKey: "isCustom")
                        newFoodEntity.setValue(Date(), forKey: "lastUsed")
                        newFoodEntity.setValue(foodItemModel.unit, forKey: "unit")
                        newFoodEntity.setValue(foodItemModel.weightInGrams ?? 0.0, forKey: "weightInGrams")
                        
                        if let ingredients = foodItemModel.ingredients,
                           let data = try? JSONEncoder().encode(ingredients) {
                            newFoodEntity.setValue(String(data: data, encoding: .utf8), forKey: "ingredientsJson")
                        }
                        
                        if let instructions = foodItemModel.instructions,
                           let data = try? JSONEncoder().encode(instructions) {
                            newFoodEntity.setValue(String(data: data, encoding: .utf8), forKey: "instructionsJson")
                        }
                        mealFood.setValue(newFoodEntity, forKey: "foodItem")
                    }
                }
            }
            try self.context.save()
            self.context.processPendingChanges()
            NotificationCenter.default.post(name: NSNotification.Name("mealLogDidUpdate"), object: nil)
        }
    }
    
    func deleteMeal(by id: UUID) async throws {
        try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "Meal")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            if let meal = try self.context.fetch(request).first {
                let linkedId = meal.value(forKey: "linkedPlannedMealId") as? UUID
                self.context.delete(meal)
                
                if let linkedId = linkedId {
                    try self.resetPlannedStatus(for: linkedId)
                }
                
                try self.context.save()
                NotificationCenter.default.post(name: NSNotification.Name("mealLogDidUpdate"), object: nil)
            }
        }
    }
    
    func deleteMealFood(by id: UUID) async throws {
        try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "MealFood")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            if let mealFood = try self.context.fetch(request).first {
                let parentMeal = mealFood.value(forKey: "meal") as? NSManagedObject
                let linkedId = parentMeal?.value(forKey: "linkedPlannedMealId") as? UUID
                
                self.context.delete(mealFood)
                
                if let parentMeal = parentMeal {
                    let remainingFoods = parentMeal.value(forKey: "mealFoods") as? NSSet
                    if remainingFoods?.count == 0 {
                        self.context.delete(parentMeal)
                        if let linkedId = linkedId {
                            try self.resetPlannedStatus(for: linkedId)
                        }
                    }
                }
                
                try self.context.save()
                NotificationCenter.default.post(name: NSNotification.Name("mealLogDidUpdate"), object: nil)
            }
        }
    }
    
    private func resetPlannedStatus(for plannedMealId: UUID) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: "PlannedMeal")
        request.predicate = NSPredicate(format: "id == %@", plannedMealId as CVarArg)
        if let plannedMeal = try self.context.fetch(request).first {
            plannedMeal.setValue("planned", forKey: "status")
            plannedMeal.setValue(nil, forKey: "actualMealLogId")
            plannedMeal.setValue(nil, forKey: "eatenAt")
            // No need to save here as it will be saved by the caller
        }
    }
    
    func saveDailyLog(_ log: DailyLogModel) async throws {
        // Implementation stub
    }
    
    func updateMealFoodStatus(id: UUID, isEaten: Bool) async throws {
        MealFoodStatusManager.shared.setEaten(id: id, isEaten: isEaten)
    }
    
    func updateFoodItemDetails(id: UUID, ingredients: [IngredientModel], instructions: [String]) async throws {
        try await context.perform {
            let request: NSFetchRequest<FoodItem> = FoodItem.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            
            if let foodEntity = try self.context.fetch(request).first {
                if let data = try? JSONEncoder().encode(ingredients) {
                    foodEntity.ingredientsJson = String(data: data, encoding: .utf8)
                }
                if let data = try? JSONEncoder().encode(instructions) {
                    foodEntity.instructionsJson = String(data: data, encoding: .utf8)
                }
                try self.context.save()
            }
        }
    }

    func fetchFoodItem(id: UUID) async throws -> FoodItemModel? {
        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "FoodItem")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            if let result = try self.context.fetch(request).first {
                return FoodItemModel(
                    id: result.value(forKey: "id") as? UUID ?? id,
                    name: result.value(forKey: "name") as? String ?? "",
                    calories: result.value(forKey: "calories") as? Double ?? 0,
                    protein: result.value(forKey: "protein") as? Double ?? 0,
                    carbs: result.value(forKey: "carbs") as? Double ?? 0,
                    fat: result.value(forKey: "fat") as? Double ?? 0,
                    servingSize: result.value(forKey: "servingSize") as? Double ?? 1.0,
                    isCustom: result.value(forKey: "isCustom") as? Bool ?? false,
                    unit: result.value(forKey: "unit") as? String,
                    weightInGrams: result.value(forKey: "weightInGrams") as? Double,
                    ingredients: (result.value(forKey: "ingredientsJson") as? String)?.data(using: .utf8).flatMap { try? JSONDecoder().decode([IngredientModel].self, from: $0) },
                    instructions: (result.value(forKey: "instructionsJson") as? String)?.data(using: .utf8).flatMap { try? JSONDecoder().decode([String].self, from: $0) }
                )
            }
            return nil
        }
    }
}
