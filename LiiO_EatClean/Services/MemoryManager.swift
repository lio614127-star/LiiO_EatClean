import Foundation

protocol MemoryManagerProtocol {
    func fetchMemory() -> UserProfileMemory
    func saveMemory(_ memory: UserProfileMemory)
}

class MemoryManager: MemoryManagerProtocol {
    static let shared = MemoryManager()
    
    private let defaults = UserDefaults.standard
    private let memoryKey = "com.liio.EatClean.userMemory"
    
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
        }
    }
}
