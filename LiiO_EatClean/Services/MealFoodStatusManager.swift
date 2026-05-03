import Foundation

class MealFoodStatusManager {
    static let shared = MealFoodStatusManager()
    private let key = "com.liio.EatClean.uncheckedMealFoodIds"
    
    private var uncheckedIds: Set<String> {
        get {
            let array = UserDefaults.standard.stringArray(forKey: key) ?? []
            return Set(array)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: key)
        }
    }
    
    func isEaten(id: UUID) -> Bool {
        return !uncheckedIds.contains(id.uuidString)
    }
    
    func setEaten(id: UUID, isEaten: Bool) {
        var current = uncheckedIds
        if isEaten {
            current.remove(id.uuidString)
        } else {
            current.insert(id.uuidString)
        }
        uncheckedIds = current
    }
    
    func clearAll() {
        uncheckedIds = []
    }
}
