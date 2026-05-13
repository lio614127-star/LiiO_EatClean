import Foundation
import CoreData
import Observation

protocol AIMemoryRepositoryProtocol {
    func fetchMemory() async throws -> UserProfileMemory
    func updatePersonalityTone(_ tone: AIPersonalityTone) async throws
    func saveMemory(_ memory: UserProfileMemory) async throws
}

@Observable
class AIMemoryRepository: AIMemoryRepositoryProtocol {
    static let shared = AIMemoryRepository()
    let context: NSManagedObjectContext
    
    var currentMemory: UserProfileMemory = UserProfileMemory()
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        Task { @MainActor in
            try? await self.loadIntoState()
        }
    }
    
    @MainActor
    func loadIntoState() async throws {
        self.currentMemory = try await fetchMemory()
    }
    
    func fetchMemory() async throws -> UserProfileMemory {
        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "AIMemory")
            request.fetchLimit = 1
            let results = try self.context.fetch(request)
            
            if let memoryEntity = results.first {
                return self.mapToModel(memoryEntity)
            } else {
                return UserProfileMemory()
            }
        }
    }
    
    func updatePersonalityTone(_ tone: AIPersonalityTone) async throws {
        try await context.perform {
            let entity = try self.fetchOrCreateEntity()
            entity.setValue(tone.rawValue, forKey: "personalityTone")
            try self.context.save()
            self.context.processPendingChanges()
        }
        await MainActor.run {
            self.currentMemory.personalityTone = tone
        }
    }
    
    func saveMemory(_ memory: UserProfileMemory) async throws {
        try await context.perform {
            let entity = try self.fetchOrCreateEntity()
            
            entity.setValue(memory.personalityTone.rawValue, forKey: "personalityTone")
            
            // Health conditions
            if let existing = entity.value(forKey: "healthConditions") as? Set<NSManagedObject> {
                for obj in existing { self.context.delete(obj) }
            }
            for hc in memory.healthConditions {
                let hcEntity = NSEntityDescription.insertNewObject(forEntityName: "HealthCondition", into: self.context)
                hcEntity.setValue(hc.id, forKey: "id")
                hcEntity.setValue(hc.name, forKey: "name")
                hcEntity.setValue(hc.dietaryNotes, forKey: "dietaryNotes")
                hcEntity.setValue(entity, forKey: "memory")
            }
            
            // Avoid Foods
            if let existing = entity.value(forKey: "avoidFoods") as? Set<NSManagedObject> {
                for obj in existing { self.context.delete(obj) }
            }
            for af in memory.avoidFoods {
                let afEntity = NSEntityDescription.insertNewObject(forEntityName: "AvoidFood", into: self.context)
                afEntity.setValue(UUID(), forKey: "id")
                afEntity.setValue(af, forKey: "name")
                afEntity.setValue(entity, forKey: "memory")
            }
            
            // Preferences (Likes/Dislikes)
            if let existing = entity.value(forKey: "foodPreferences") as? Set<NSManagedObject> {
                for obj in existing { self.context.delete(obj) }
            }
            for like in memory.likes {
                let fpEntity = NSEntityDescription.insertNewObject(forEntityName: "FoodPreference", into: self.context)
                fpEntity.setValue(UUID(), forKey: "id")
                fpEntity.setValue(like, forKey: "name")
                fpEntity.setValue("like", forKey: "type")
                fpEntity.setValue(entity, forKey: "memory")
            }
            for dislike in memory.dislikes {
                let fpEntity = NSEntityDescription.insertNewObject(forEntityName: "FoodPreference", into: self.context)
                fpEntity.setValue(UUID(), forKey: "id")
                fpEntity.setValue(dislike, forKey: "name")
                fpEntity.setValue("dislike", forKey: "type")
                fpEntity.setValue(entity, forKey: "memory")
            }
            
            // Dietary Notes
            if let existing = entity.value(forKey: "dietaryNotes") as? Set<NSManagedObject> {
                for obj in existing { self.context.delete(obj) }
            }
            for note in memory.dietaryNotes {
                let dnEntity = NSEntityDescription.insertNewObject(forEntityName: "DietaryNote", into: self.context)
                dnEntity.setValue(UUID(), forKey: "id")
                dnEntity.setValue(note, forKey: "content")
                dnEntity.setValue(entity, forKey: "memory")
            }
            
            try self.context.save()
            self.context.processPendingChanges()
        }
        await MainActor.run {
            self.currentMemory = memory
        }
    }
    
    private func fetchOrCreateEntity() throws -> NSManagedObject {
        let request = NSFetchRequest<NSManagedObject>(entityName: "AIMemory")
        request.fetchLimit = 1
        if let existing = try context.fetch(request).first {
            return existing
        }
        let newEntity = NSEntityDescription.insertNewObject(forEntityName: "AIMemory", into: context)
        newEntity.setValue(UUID(), forKey: "id")
        newEntity.setValue(AIPersonalityTone.friendly.rawValue, forKey: "personalityTone")
        return newEntity
    }
    
    private func mapToModel(_ entity: NSManagedObject) -> UserProfileMemory {
        var model = UserProfileMemory()
        
        if let toneString = entity.value(forKey: "personalityTone") as? String, let tone = AIPersonalityTone(rawValue: toneString) {
            model.personalityTone = tone
        }
        
        if let conditionsSet = entity.value(forKey: "healthConditions") as? Set<NSManagedObject> {
            model.healthConditions = conditionsSet.map {
                HealthConditionModel(
                    id: $0.value(forKey: "id") as? UUID ?? UUID(),
                    name: $0.value(forKey: "name") as? String ?? "",
                    dietaryNotes: $0.value(forKey: "dietaryNotes") as? String ?? ""
                )
            }
        }
        
        if let avoidFoodsSet = entity.value(forKey: "avoidFoods") as? Set<NSManagedObject> {
            model.avoidFoods = avoidFoodsSet.compactMap { $0.value(forKey: "name") as? String }
        }
        
        if let prefsSet = entity.value(forKey: "foodPreferences") as? Set<NSManagedObject> {
            model.likes = prefsSet.filter { ($0.value(forKey: "type") as? String) == "like" }.compactMap { $0.value(forKey: "name") as? String }
            model.dislikes = prefsSet.filter { ($0.value(forKey: "type") as? String) == "dislike" }.compactMap { $0.value(forKey: "name") as? String }
        }
        
        if let notesSet = entity.value(forKey: "dietaryNotes") as? Set<NSManagedObject> {
            model.dietaryNotes = notesSet.compactMap { $0.value(forKey: "content") as? String }
        }
        
        return model
    }
}
