import Foundation
import CoreData

class FoodRepository: FoodRepositoryProtocol {
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.newBackgroundContext()) {
        self.context = context
    }
    
    func fetchAllFoods() async throws -> [FoodItemModel] {
        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "FoodItem")
            let results = try self.context.fetch(request)
            return self.mapToModels(results)
        }
    }
    
    func searchFoods(query: String) async throws -> [FoodItemModel] {
        return try await searchLocalFoods(query: query)
    }
    
    func searchLocalFoods(query: String) async throws -> [FoodItemModel] {
        guard !query.isEmpty else { return [] }
        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "FoodItem")
            request.predicate = NSPredicate(format: "name CONTAINS[cd] %@", query)
            let results = try self.context.fetch(request)
            return self.mapToModels(results)
        }
    }
    
    func fetchSuggestions() async throws -> [FoodItemModel] {
        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "FoodItem")
            request.sortDescriptors = [NSSortDescriptor(key: "lastUsed", ascending: false)]
            request.fetchLimit = 10
            let results = try self.context.fetch(request)
            return self.mapToModels(results)
        }
    }
    
    func saveFood(_ food: FoodItemModel) async throws {
        try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "FoodItem")
            request.predicate = NSPredicate(format: "name ==[cd] %@", food.name)
            
            let entity: NSManagedObject
            if let existing = try self.context.fetch(request).first {
                entity = existing
            } else {
                entity = NSEntityDescription.insertNewObject(forEntityName: "FoodItem", into: self.context)
                entity.setValue(food.id, forKey: "id")
                entity.setValue(Date(), forKey: "createdAt")
            }
            
            entity.setValue(food.name, forKey: "name")
            entity.setValue(food.calories, forKey: "calories")
            entity.setValue(food.protein, forKey: "protein")
            entity.setValue(food.carbs, forKey: "carbs")
            entity.setValue(food.fat, forKey: "fat")
            entity.setValue(food.servingSize, forKey: "servingSize")
            entity.setValue("local", forKey: "source")
            entity.setValue(food.apiId, forKey: "apiId")
            entity.setValue(food.isCustom, forKey: "isCustom")
            entity.setValue(food.lastUsed, forKey: "lastUsed")
            entity.setValue(Date(), forKey: "updatedAt")
            try self.context.save()
        }
    }
    
    func updateLastUsed(for id: UUID) async throws {
        try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "FoodItem")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            if let entity = try self.context.fetch(request).first {
                entity.setValue(Date(), forKey: "lastUsed")
                try self.context.save()
            }
        }
    }
    
    func deleteFood(by id: UUID) async throws {
        try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "FoodItem")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            if let entity = try self.context.fetch(request).first {
                self.context.delete(entity)
                try self.context.save()
            }
        }
    }
    
    func seedDatabaseIfNeeded() async throws {
        let count = try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "FoodItem")
            return try self.context.count(for: request)
        }
        
        if count == 0 {
            guard let url = Bundle.main.url(forResource: "VietnameseFoods", withExtension: "json"),
                  let data = try? Data(contentsOf: url) else { return }
            
            let items = try JSONDecoder().decode([FoodItemDTO].self, from: data)
            
            try await context.perform {
                for item in items {
                    let entity = NSEntityDescription.insertNewObject(forEntityName: "FoodItem", into: self.context)
                    entity.setValue(UUID(), forKey: "id")
                    entity.setValue(item.name, forKey: "name")
                    entity.setValue(item.calories, forKey: "calories")
                    entity.setValue(item.protein, forKey: "protein")
                    entity.setValue(item.carbs, forKey: "carbs")
                    entity.setValue(item.fat, forKey: "fat")
                    entity.setValue(item.servingSize, forKey: "servingSize")
                    entity.setValue("local", forKey: "source")
                    entity.setValue(false, forKey: "isCustom")
                }
                try self.context.save()
            }
        }
    }
    
    func fetchCustomFoods() async throws -> [FoodItemModel] {
        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "FoodItem")
            request.predicate = NSPredicate(format: "isCustom == true")
            request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
            let results = try self.context.fetch(request)
            return self.mapToModels(results)
        }
    }

    func searchCustomFoods(query: String) async throws -> [FoodItemModel] {
        guard !query.isEmpty else { return [] }
        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "FoodItem")
            request.predicate = NSPredicate(format: "isCustom == true AND name CONTAINS[cd] %@", query)
            request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
            let results = try self.context.fetch(request)
            return self.mapToModels(results)
        }
    }

    func saveCustomFood(_ food: FoodItemModel) async throws {
        try await context.perform {
            let entity = NSEntityDescription.insertNewObject(forEntityName: "FoodItem", into: self.context)
            entity.setValue(food.id, forKey: "id")
            entity.setValue(food.name, forKey: "name")
            entity.setValue(food.calories, forKey: "calories")
            entity.setValue(food.protein, forKey: "protein")
            entity.setValue(food.carbs, forKey: "carbs")
            entity.setValue(food.fat, forKey: "fat")
            entity.setValue(food.servingSize > 0 ? food.servingSize : 1.0, forKey: "servingSize")
            entity.setValue("custom", forKey: "source")
            entity.setValue(true, forKey: "isCustom")
            entity.setValue(Date(), forKey: "createdAt")
            entity.setValue(Date(), forKey: "updatedAt")
            try self.context.save()
        }
    }

    func updateCustomFood(_ food: FoodItemModel) async throws {
        try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "FoodItem")
            request.predicate = NSPredicate(format: "id == %@", food.id as CVarArg)
            if let entity = try self.context.fetch(request).first {
                entity.setValue(food.name, forKey: "name")
                entity.setValue(food.calories, forKey: "calories")
                entity.setValue(food.protein, forKey: "protein")
                entity.setValue(food.carbs, forKey: "carbs")
                entity.setValue(food.fat, forKey: "fat")
                entity.setValue(food.servingSize, forKey: "servingSize")
                entity.setValue(Date(), forKey: "updatedAt")
                try self.context.save()
            }
        }
    }

    func duplicateCustomFood(_ food: FoodItemModel) async throws -> FoodItemModel {
        let duplicate = FoodItemModel(
            id: UUID(),
            name: food.name + " (bản sao)",
            calories: food.calories,
            protein: food.protein,
            carbs: food.carbs,
            fat: food.fat,
            servingSize: food.servingSize,
            source: "custom",
            isCustom: true,
            createdAt: Date(),
            updatedAt: Date()
        )
        try await saveCustomFood(duplicate)
        return duplicate
    }
    
    private func mapToModels(_ entities: [NSManagedObject]) -> [FoodItemModel] {
        return entities.map { food in
            FoodItemModel(
                id: food.value(forKey: "id") as? UUID ?? UUID(),
                name: food.value(forKey: "name") as? String ?? "",
                calories: food.value(forKey: "calories") as? Double ?? 0,
                protein: food.value(forKey: "protein") as? Double ?? 0,
                carbs: food.value(forKey: "carbs") as? Double ?? 0,
                fat: food.value(forKey: "fat") as? Double ?? 0,
                servingSize: food.value(forKey: "servingSize") as? Double ?? 0,
                source: food.value(forKey: "source") as? String ?? "",
                apiId: food.value(forKey: "apiId") as? String,
                isCustom: food.value(forKey: "isCustom") as? Bool ?? false,
                lastUsed: food.value(forKey: "lastUsed") as? Date,
                createdAt: food.value(forKey: "createdAt") as? Date,
                updatedAt: food.value(forKey: "updatedAt") as? Date
            )
        }
    }
}
