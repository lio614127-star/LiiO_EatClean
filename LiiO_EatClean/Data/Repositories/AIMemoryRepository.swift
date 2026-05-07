import Foundation
import CoreData

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
            let request: NSFetchRequest<AIMemory> = AIMemory.fetchRequest()
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
            entity.personalityTone = tone.rawValue
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
            
            entity.personalityTone = memory.personalityTone.rawValue
            
            // Health conditions
            if let existing = entity.healthConditions as? Set<NSManagedObject> {
                for obj in existing { self.context.delete(obj) }
            }
            for hc in memory.healthConditions {
                let hcEntity = HealthCondition(context: self.context)
                hcEntity.id = hc.id
                hcEntity.name = hc.name
                hcEntity.dietaryNotes = hc.dietaryNotes
                hcEntity.memory = entity
                entity.addToHealthConditions(hcEntity)
            }
            
            // Avoid Foods
            if let existing = entity.avoidFoods as? Set<NSManagedObject> {
                for obj in existing { self.context.delete(obj) }
            }
            for af in memory.avoidFoods {
                let afEntity = AvoidFood(context: self.context)
                afEntity.id = UUID()
                afEntity.name = af
                afEntity.memory = entity
                entity.addToAvoidFoods(afEntity)
            }
            
            // Preferences (Likes/Dislikes)
            if let existing = entity.foodPreferences as? Set<NSManagedObject> {
                for obj in existing { self.context.delete(obj) }
            }
            for like in memory.likes {
                let fpEntity = FoodPreference(context: self.context)
                fpEntity.id = UUID()
                fpEntity.name = like
                fpEntity.type = "like"
                fpEntity.memory = entity
                entity.addToFoodPreferences(fpEntity)
            }
            for dislike in memory.dislikes {
                let fpEntity = FoodPreference(context: self.context)
                fpEntity.id = UUID()
                fpEntity.name = dislike
                fpEntity.type = "dislike"
                fpEntity.memory = entity
                entity.addToFoodPreferences(fpEntity)
            }
            
            // Dietary Notes
            if let existing = entity.dietaryNotes as? Set<NSManagedObject> {
                for obj in existing { self.context.delete(obj) }
            }
            for note in memory.dietaryNotes {
                let dnEntity = DietaryNote(context: self.context)
                dnEntity.id = UUID()
                dnEntity.content = note
                dnEntity.memory = entity
                entity.addToDietaryNotes(dnEntity)
            }
            
            try self.context.save()
            self.context.processPendingChanges()
        }
        await MainActor.run {
            self.currentMemory = memory
        }
    }
    
    private func fetchOrCreateEntity() throws -> AIMemory {
        let request: NSFetchRequest<AIMemory> = AIMemory.fetchRequest()
        request.fetchLimit = 1
        if let existing = try context.fetch(request).first {
            return existing
        }
        let newEntity = AIMemory(context: context)
        newEntity.id = UUID()
        newEntity.personalityTone = AIPersonalityTone.friendly.rawValue
        return newEntity
    }
    
    private func mapToModel(_ entity: AIMemory) -> UserProfileMemory {
        var model = UserProfileMemory()
        
        if let toneString = entity.personalityTone, let tone = AIPersonalityTone(rawValue: toneString) {
            model.personalityTone = tone
        }
        
        if let conditionsSet = entity.healthConditions as? Set<HealthCondition> {
            model.healthConditions = conditionsSet.map {
                HealthConditionModel(id: $0.id ?? UUID(), name: $0.name ?? "", dietaryNotes: $0.dietaryNotes ?? "")
            }
        }
        
        if let avoidFoodsSet = entity.avoidFoods as? Set<AvoidFood> {
            model.avoidFoods = avoidFoodsSet.compactMap { $0.name }
        }
        
        if let prefsSet = entity.foodPreferences as? Set<FoodPreference> {
            model.likes = prefsSet.filter { $0.type == "like" }.compactMap { $0.name }
            model.dislikes = prefsSet.filter { $0.type == "dislike" }.compactMap { $0.name }
        }
        
        if let notesSet = entity.dietaryNotes as? Set<DietaryNote> {
            model.dietaryNotes = notesSet.compactMap { $0.content }
        }
        
        return model
    }
}
