import Foundation

class MagicSwapEngine {
    static let shared = MagicSwapEngine()
    
    private let foodRepository: FoodRepositoryProtocol
    private let memoryRepository: AIMemoryRepositoryProtocol
    
    init(foodRepository: FoodRepositoryProtocol = FoodRepository(),
         memoryRepository: AIMemoryRepositoryProtocol = AIMemoryRepository.shared) {
        self.foodRepository = foodRepository
        self.memoryRepository = memoryRepository
    }
    
    /// Find a replacement food from local database with similar calories and macros
    func swap(originalFood: FoodItemModel, targetCalories: Double? = nil) async throws -> FoodItemModel? {
        let memory = try await memoryRepository.fetchMemory()
        let allFoods = try await foodRepository.fetchAllFoods()
        
        let targetCals = targetCalories ?? originalFood.calories
        
        // Filter out avoided foods and recently swapped foods (Variety Memory)
        let candidates = allFoods.filter { food in
            !memory.shouldAvoid(food.name) && 
            !memory.recentSwaps.contains(food.name) &&
            food.name != originalFood.name
        }
        
        // Score candidates based on calorie proximity and macro similarity
        let scored = candidates.map { food in
            let calDiff = abs(food.calories - targetCals) / targetCals
            let pDiff = abs(food.protein - originalFood.protein) / max(1.0, originalFood.protein)
            let cDiff = abs(food.carbs - originalFood.carbs) / max(1.0, originalFood.carbs)
            let fDiff = abs(food.fat - originalFood.fat) / max(1.0, originalFood.fat)
            
            // Total score: lower is better
            let score = calDiff * 2.0 + pDiff + cDiff + fDiff
            return (food, score)
        }
        
        // Get the best match (within 20% calorie range)
        if let best = scored.filter({ $0.1 < 0.5 }).sorted(by: { $0.1 < $1.1 }).first {
            // Update Variety Memory
            var updatedMemory = memory
            updatedMemory.addRecentSwap(best.0.name)
            try await memoryRepository.saveMemory(updatedMemory)
            
            return best.0
        }
        
        return nil
    }
}
