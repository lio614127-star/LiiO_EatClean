import Foundation
import CoreData

class BackgroundEnrichmentManager {
    static let shared = BackgroundEnrichmentManager()
    
    private let aiService = AIService.shared
    private let backgroundContext: NSManagedObjectContext
    private let mealRepository: MealRepository
    
    private var processingIds = Set<UUID>()
    
    private init() {
        let context = PersistenceController.shared.container.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        self.backgroundContext = context
        self.mealRepository = MealRepository(context: context)
    }
    
    func enrich(foods: [FoodItemModel]) {
        for food in foods {
            // Skip if already has ingredients or is already being processed
            if food.ingredients != nil && !food.ingredients!.isEmpty { 
                print("✨ Enrichment: Skipping \(food.name) - Already has ingredients")
                continue 
            }
            if processingIds.contains(food.id) { 
                print("✨ Enrichment: Skipping \(food.name) - Already processing")
                continue 
            }
            
            print("✨ Enrichment: Enqueuing \(food.name) (ID: \(food.id.uuidString.prefix(8))...)")
            processingIds.insert(food.id)
            
            Task.detached(priority: .background) {
                await self.process(food: food)
            }
        }
    }
    
    private func process(food: FoodItemModel) async {
        defer { 
            processingIds.remove(food.id) 
            print("✨ Enrichment: Finished attempt for \(food.name)")
        }
        
        do {
            print("✨ Enrichment: Starting AI analysis for \(food.name)...")
            if let result = try await aiService.enrichFoodItem(
                name: food.name,
                calories: food.calories,
                isInternal: true
            ) {
                print("✨ Enrichment: Received AI response for \(food.name), saving to DB...")
                let ingredients = result.ingredients?.map { 
                    IngredientModel(name: $0.name, amount: $0.amount, unit: $0.unit, protein: $0.protein, carbs: $0.carbs, fat: $0.fat)
                } ?? []
                let instructions = result.instructions ?? []
                
                try await mealRepository.updateFoodItemDetails(
                    id: food.id, 
                    ingredients: ingredients, 
                    instructions: instructions
                )
                print("✅ Enrichment SUCCESS: Saved \(food.name) details to database.")
            } else {
                print("⚠️ Enrichment: AI returned no suggestions for \(food.name)")
            }
        } catch {
            print("❌ Enrichment ERROR for \(food.name): \(error.localizedDescription)")
            if let aiError = error as? AIError {
                print("   AI Error details: \(aiError)")
            }
        }
    }
}
