import Foundation

protocol MemoryManagerProtocol {
    func fetchMemory() -> UserProfileMemory
    func saveMemory(_ memory: UserProfileMemory)
    func applyMemoryUpdate(_ update: MemoryUpdate)
}

class MemoryManager: MemoryManagerProtocol {
    static let shared = MemoryManager()
    
    private let defaults = UserDefaults.standard
    private let memoryKey = "com.liio.EatClean.userMemory"
    
    // MARK: - Core CRUD
    
    func fetchMemory() -> UserProfileMemory {
        guard let data = defaults.data(forKey: memoryKey),
              let memory = try? JSONDecoder().decode(UserProfileMemory.self, from: data) else {
            return UserProfileMemory()
        }
        return memory
    }
    
    func saveMemory(_ memory: UserProfileMemory) {
        if let data = try? JSONEncoder().encode(memory) {
            defaults.set(data, forKey: memoryKey)
            NotificationCenter.default.post(name: .memoryDidUpdate, object: nil)
        }
    }
    
    // MARK: - Health Conditions
    
    func addHealthCondition(_ condition: HealthCondition) {
        var memory = fetchMemory()
        // Avoid duplicates by name
        guard !memory.healthConditions.contains(where: { $0.name.lowercased() == condition.name.lowercased() }) else { return }
        memory.healthConditions.append(condition)
        saveMemory(memory)
    }
    
    func removeHealthCondition(id: UUID) {
        var memory = fetchMemory()
        memory.healthConditions.removeAll(where: { $0.id == id })
        saveMemory(memory)
    }
    
    // MARK: - Likes & Dislikes
    
    func addLike(_ food: String) {
        var memory = fetchMemory()
        let trimmed = food.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !memory.likes.contains(where: { $0.lowercased() == trimmed.lowercased() }) else { return }
        memory.likes.append(trimmed)
        saveMemory(memory)
    }
    
    func removeLike(_ food: String) {
        var memory = fetchMemory()
        memory.likes.removeAll(where: { $0.lowercased() == food.lowercased() })
        saveMemory(memory)
    }
    
    func addDislike(_ food: String) {
        var memory = fetchMemory()
        let trimmed = food.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !memory.dislikes.contains(where: { $0.lowercased() == trimmed.lowercased() }) else { return }
        memory.dislikes.append(trimmed)
        saveMemory(memory)
    }
    
    func removeDislike(_ food: String) {
        var memory = fetchMemory()
        memory.dislikes.removeAll(where: { $0.lowercased() == food.lowercased() })
        saveMemory(memory)
    }
    
    // MARK: - Dietary Notes
    
    func addDietaryNote(_ note: String) {
        var memory = fetchMemory()
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        memory.dietaryNotes.append(trimmed)
        saveMemory(memory)
    }
    
    func removeDietaryNote(_ note: String) {
        var memory = fetchMemory()
        memory.dietaryNotes.removeAll(where: { $0 == note })
        saveMemory(memory)
    }
    
    // MARK: - Standardized Memory Update (from Learning System)
    
    func applyMemoryUpdate(_ update: MemoryUpdate) {
        switch update.type {
        case .addCondition:
            let condition = HealthCondition(
                name: update.value,
                avoidFoods: update.avoid ?? [],
                dietaryNotes: update.dietaryNotes ?? ""
            )
            addHealthCondition(condition)
        case .addLike:
            addLike(update.value)
        case .addDislike:
            addDislike(update.value)
        case .addNote:
            addDietaryNote(update.value)
        }
    }
}

extension Notification.Name {
    static let memoryDidUpdate = Notification.Name("memoryDidUpdate")
}
