import Foundation
import CoreData

class FoodRepository: FoodRepositoryProtocol {
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.newBackgroundContext()) {
        self.context = context
    }
    
    func fetchAllFoods() async throws -> [FoodItemModel] {
        return try await context.perform {
            let request: NSFetchRequest<FoodItem> = FoodItem.fetchRequest()
            let results = try self.context.fetch(request)
            return self.mapToModels(results)
        }
    }
    
    func searchFoods(query: String) async throws -> [FoodItemModel] {
        // Obsolete in Phase 4 due to searchLocalFoods, but kept for protocol adherence if needed
        return try await searchLocalFoods(query: query)
    }
    
    func searchLocalFoods(query: String) async throws -> [FoodItemModel] {
        guard !query.isEmpty else { return [] }
        return try await context.perform {
            let request: NSFetchRequest<FoodItem> = FoodItem.fetchRequest()
            request.predicate = NSPredicate(format: "name CONTAINS[cd] %@", query)
            let results = try self.context.fetch(request)
            return self.mapToModels(results)
        }
    }
    
    func fetchSuggestions() async throws -> [FoodItemModel] {
        return try await context.perform {
            let request: NSFetchRequest<FoodItem> = FoodItem.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \FoodItem.lastUsed, ascending: false)]
            request.fetchLimit = 10
            let results = try self.context.fetch(request)
            return self.mapToModels(results)
        }
    }
    
    func saveFood(_ food: FoodItemModel) async throws {
        try await context.perform {
            let request: NSFetchRequest<FoodItem> = FoodItem.fetchRequest()
            request.predicate = NSPredicate(format: "name ==[cd] %@", food.name)
            
            let entity: FoodItem
            if let existing = try self.context.fetch(request).first {
                entity = existing
            } else {
                entity = FoodItem(context: self.context)
                entity.id = food.id
                entity.createdAt = Date()
            }
            
            entity.name = food.name
            entity.calories = food.calories
            entity.protein = food.protein
            entity.carbs = food.carbs
            entity.fat = food.fat
            entity.servingSize = food.servingSize
            entity.source = "local" // Convert API source to local upon caching
            entity.apiId = food.apiId
            entity.isCustom = food.isCustom
            entity.lastUsed = food.lastUsed
            entity.updatedAt = Date()
            try self.context.save()
        }
    }
    
    func updateLastUsed(for id: UUID) async throws {
        try await context.perform {
            let request: NSFetchRequest<FoodItem> = FoodItem.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            if let entity = try self.context.fetch(request).first {
                entity.lastUsed = Date()
                try self.context.save()
            }
        }
    }
    
    func deleteFood(by id: UUID) async throws {
        try await context.perform {
            let request: NSFetchRequest<FoodItem> = FoodItem.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            if let entity = try self.context.fetch(request).first {
                self.context.delete(entity)
                try self.context.save()
            }
        }
    }
    
    func seedDatabaseIfNeeded() async throws {
        let count = try await context.perform {
            let request: NSFetchRequest<FoodItem> = FoodItem.fetchRequest()
            return try self.context.count(for: request)
        }
        
        if count == 0 {
            guard let url = Bundle.main.url(forResource: "VietnameseFoods", withExtension: "json"),
                  let data = try? Data(contentsOf: url) else { return }
            
            let decoder = JSONDecoder()
            let items = try decoder.decode([FoodItemDTO].self, from: data)
            
            try await context.perform {
                for item in items {
                    let entity = FoodItem(context: self.context)
                    entity.id = UUID()
                    entity.name = item.name
                    entity.calories = item.calories
                    entity.protein = item.protein
                    entity.carbs = item.carbs
                    entity.fat = item.fat
                    entity.servingSize = item.servingSize
                    entity.source = "local"
                    entity.isCustom = false
                }
                try self.context.save()
            }
        }
    }
    
    // MARK: - Custom Foods
    
    func fetchCustomFoods() async throws -> [FoodItemModel] {
        return try await context.perform {
            let request: NSFetchRequest<FoodItem> = FoodItem.fetchRequest()
            request.predicate = NSPredicate(format: "isCustom == true")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \FoodItem.updatedAt, ascending: false)]
            let results = try self.context.fetch(request)
            return self.mapToModels(results)
        }
    }

    func searchCustomFoods(query: String) async throws -> [FoodItemModel] {
        guard !query.isEmpty else { return [] }
        return try await context.perform {
            let request: NSFetchRequest<FoodItem> = FoodItem.fetchRequest()
            request.predicate = NSPredicate(format: "isCustom == true AND name CONTAINS[cd] %@", query)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \FoodItem.updatedAt, ascending: false)]
            let results = try self.context.fetch(request)
            return self.mapToModels(results)
        }
    }

    func saveCustomFood(_ food: FoodItemModel) async throws {
        try await context.perform {
            let entity = FoodItem(context: self.context)
            entity.id = food.id
            entity.name = food.name
            entity.calories = food.calories
            entity.protein = food.protein
            entity.carbs = food.carbs
            entity.fat = food.fat
            entity.servingSize = food.servingSize > 0 ? food.servingSize : 1.0
            entity.source = "custom"
            entity.isCustom = true
            entity.createdAt = Date()
            entity.updatedAt = Date()
            try self.context.save()
        }
    }

    func updateCustomFood(_ food: FoodItemModel) async throws {
        try await context.perform {
            let request: NSFetchRequest<FoodItem> = FoodItem.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", food.id as CVarArg)
            if let entity = try self.context.fetch(request).first {
                entity.name = food.name
                entity.calories = food.calories
                entity.protein = food.protein
                entity.carbs = food.carbs
                entity.fat = food.fat
                entity.servingSize = food.servingSize
                entity.updatedAt = Date()
                try self.context.save()
            }
        }
    }

    func duplicateCustomFood(_ food: FoodItemModel) async throws -> FoodItemModel {
        var duplicate = food
        duplicate = FoodItemModel(
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
    
    private func mapToModels(_ entities: [FoodItem]) -> [FoodItemModel] {
        return entities.map { food in
            FoodItemModel(
                id: food.id ?? UUID(),
                name: food.name ?? "",
                calories: food.calories,
                protein: food.protein,
                carbs: food.carbs,
                fat: food.fat,
                servingSize: food.servingSize,
                source: food.source ?? "",
                apiId: food.apiId,
                isCustom: food.isCustom,
                lastUsed: food.lastUsed,
                createdAt: food.createdAt,
                updatedAt: food.updatedAt
            )
        }
    }
}
