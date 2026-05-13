import Foundation
import CoreData

protocol DailyPlanRepositoryProtocol {
    func fetchPlan(for date: Date) async throws -> DailyPlanModel?
    func savePlan(_ plan: DailyPlanModel, status: String) async throws
    func cleanupOldDrafts() async throws
}

class DailyPlanRepository: DailyPlanRepositoryProtocol {
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }
    
    func fetchPlan(for date: Date) async throws -> DailyPlanModel? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "DailyPlan")
            request.predicate = NSPredicate(format: "date == %@", startOfDay as CVarArg)
            request.returnsObjectsAsFaults = false
            
            let results = try self.context.fetch(request)
            guard let entity = results.first else { return nil }
            
            var plannedMeals: [PlannedMealModel] = []
            if let pms = entity.value(forKey: "plannedMeals") {
                if let pmsSet = pms as? Set<NSManagedObject> {
                    plannedMeals = pmsSet.map { self.mapPlannedMeal($0) }.sorted { $0.id.uuidString < $1.id.uuidString }
                } else if let pmsOrderedSet = pms as? NSOrderedSet {
                    plannedMeals = pmsOrderedSet.array.compactMap { $0 as? NSManagedObject }.map { self.mapPlannedMeal($0) }.sorted { $0.id.uuidString < $1.id.uuidString }
                }
            }
            
            return DailyPlanModel(
                id: entity.value(forKey: "id") as? UUID ?? UUID(),
                date: entity.value(forKey: "date") as? Date ?? startOfDay,
                status: entity.value(forKey: "status") as? String ?? "draft",
                targetCalories: entity.value(forKey: "targetCalories") as? Double ?? 0,
                targetProtein: entity.value(forKey: "targetProtein") as? Double ?? 0,
                targetCarbs: entity.value(forKey: "targetCarbs") as? Double ?? 0,
                targetFat: entity.value(forKey: "targetFat") as? Double ?? 0,
                plannedMeals: plannedMeals
            )
        }
    }
    
    private func mapPlannedMeal(_ entity: NSManagedObject) -> PlannedMealModel {
        var foodItems: [PlannedFoodItemModel] = []
        if let items = entity.value(forKey: "foodItems") {
            if let itemsSet = items as? Set<NSManagedObject> {
                foodItems = itemsSet.map { self.mapPlannedFoodItem($0) }.sorted { $0.id.uuidString < $1.id.uuidString }
            } else if let itemsOrderedSet = items as? NSOrderedSet {
                foodItems = itemsOrderedSet.array.compactMap { $0 as? NSManagedObject }.map { self.mapPlannedFoodItem($0) }.sorted { $0.id.uuidString < $1.id.uuidString }
            }
        }
        
        return PlannedMealModel(
            id: entity.value(forKey: "id") as? UUID ?? UUID(),
            type: entity.value(forKey: "type") as? String ?? "",
            convertedMealId: entity.value(forKey: "convertedMealId") as? UUID,
            status: entity.value(forKey: "status") as? String ?? "planned",
            actualMealLogId: entity.value(forKey: "actualMealLogId") as? UUID,
            eatenAt: entity.value(forKey: "eatenAt") as? Date,
            foodItems: foodItems
        )
    }
    
    private func mapPlannedFoodItem(_ entity: NSManagedObject) -> PlannedFoodItemModel {
        return PlannedFoodItemModel(
            id: entity.value(forKey: "id") as? UUID ?? UUID(),
            name: entity.value(forKey: "name") as? String ?? "",
            calories: entity.value(forKey: "calories") as? Double ?? 0,
            protein: entity.value(forKey: "protein") as? Double ?? 0,
            carbs: entity.value(forKey: "carbs") as? Double ?? 0,
            fat: entity.value(forKey: "fat") as? Double ?? 0,
            servingSize: entity.value(forKey: "servingSize") as? Double ?? 1.0
        )
    }
    
    func savePlan(_ plan: DailyPlanModel, status: String) async throws {
        try await context.perform {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: plan.date)
            
            let request = NSFetchRequest<NSManagedObject>(entityName: "DailyPlan")
            request.predicate = NSPredicate(format: "date == %@", startOfDay as CVarArg)
            
            let existingPlans = try self.context.fetch(request)
            let targetPlan: NSManagedObject
            
            if let firstPlan = existingPlans.first {
                targetPlan = firstPlan
                // Remove old meals from the relationship to replace them
                if let oldMeals = targetPlan.value(forKey: "plannedMeals") as? Set<NSManagedObject> {
                    for meal in oldMeals {
                        self.context.delete(meal)
                    }
                }
                targetPlan.mutableSetValue(forKey: "plannedMeals").removeAllObjects()
            } else {
                targetPlan = NSEntityDescription.insertNewObject(forEntityName: "DailyPlan", into: self.context)
                targetPlan.setValue(plan.id, forKey: "id")
                targetPlan.setValue(startOfDay, forKey: "date")
            }
            
            let mutableMeals = targetPlan.mutableSetValue(forKey: "plannedMeals")
            
            targetPlan.setValue(status, forKey: "status")
            targetPlan.setValue(plan.targetCalories, forKey: "targetCalories")
            targetPlan.setValue(plan.targetProtein, forKey: "targetProtein")
            targetPlan.setValue(plan.targetCarbs, forKey: "targetCarbs")
            targetPlan.setValue(plan.targetFat, forKey: "targetFat")
            
            for pm in plan.plannedMeals {
                let mealEntity = NSEntityDescription.insertNewObject(forEntityName: "PlannedMeal", into: self.context)
                mealEntity.setValue(pm.id, forKey: "id")
                mealEntity.setValue(pm.type, forKey: "type")
                mealEntity.setValue(pm.convertedMealId, forKey: "convertedMealId")
                mealEntity.setValue(pm.status, forKey: "status")
                mealEntity.setValue(pm.actualMealLogId, forKey: "actualMealLogId")
                mealEntity.setValue(pm.eatenAt, forKey: "eatenAt")
                
                mutableMeals.add(mealEntity)
                
                let mutableFoods = mealEntity.mutableSetValue(forKey: "foodItems")
                for food in pm.foodItems {
                    let foodEntity = NSEntityDescription.insertNewObject(forEntityName: "PlannedFoodItem", into: self.context)
                    foodEntity.setValue(food.id, forKey: "id")
                    foodEntity.setValue(food.name, forKey: "name")
                    foodEntity.setValue(food.calories, forKey: "calories")
                    foodEntity.setValue(food.protein, forKey: "protein")
                    foodEntity.setValue(food.carbs, forKey: "carbs")
                    foodEntity.setValue(food.fat, forKey: "fat")
                    foodEntity.setValue(food.servingSize, forKey: "servingSize")
                    
                    mutableFoods.add(foodEntity)
                }
            }
            
            try self.context.save()
        }
    }
    
    func cleanupOldDrafts() async throws {
        try await context.perform {
            let calendar = Calendar.current
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else { return }
            
            let request = NSFetchRequest<NSManagedObject>(entityName: "DailyPlan")
            request.predicate = NSPredicate(format: "status == %@ AND date <= %@", "draft", yesterday as CVarArg)
            
            let results = try self.context.fetch(request)
            for plan in results {
                self.context.delete(plan)
            }
            try self.context.save()
        }
    }
}
