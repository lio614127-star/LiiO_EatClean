import Foundation

class BarcodeResultService {
    private let openFoodFacts = OpenFoodFactsService()
    private let aiService = AIService.shared
    
    enum LookupResult {
        case found(FoodItemModel)           // Full data from OpenFoodFacts
        case aiEstimated(FoodItemModel)      // Name from OFF + AI estimated nutrition
        case notFound(barcode: String)       // Nothing found → suggest manual search
    }
    
    func lookup(barcode: String) async -> LookupResult {
        // Tier 1: OpenFoodFacts
        if let product = try? await openFoodFacts.lookupBarcode(barcode) {
            if product.calories > 0 {
                return .found(product)
            } else {
                // Has name but no nutrition → AI estimate
                if let estimated = try? await estimateNutrition(name: product.name) {
                    return .aiEstimated(estimated)
                } else {
                    // If AI fails but we have a name, return with 0 calories so user can edit it manually
                    return .aiEstimated(product)
                }
            }
        }
        
        // Tier 2: Nothing found
        return .notFound(barcode: barcode)
    }
    
    private func estimateNutrition(name: String) async throws -> FoodItemModel {
        let prompt = """
        Estimate nutrition for 1 serving of this food product: '\(name)'.
        Return ONLY a JSON object with this format (no explanation, no markdown):
        {"calories": 150, "protein": 5, "carbs": 20, "fat": 5}
        If you don't know, provide a best guess.
        """
        
        let responseText = try await aiService.generateText(prompt: prompt, requestType: .mealSuggestion, feature: "Quét Barcode")
        let cleanedText = extractJSON(from: responseText)
        
        guard let data = cleanedText.data(using: .utf8) else {
            throw NSError(domain: "BarcodeResult", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON"])
        }
        
        struct Estimate: Codable {
            let calories: Double
            let protein: Double
            let carbs: Double
            let fat: Double
        }
        
        let est = try JSONDecoder().decode(Estimate.self, from: data)
        
        return FoodItemModel(
            id: UUID(),
            name: name,
            calories: est.calories,
            protein: est.protein,
            carbs: est.carbs,
            fat: est.fat,
            servingSize: 1.0,
            source: "ai_estimate"
        )
    }
    
    private func extractJSON(from text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let firstBracket = cleaned.firstIndex(of: "{"),
           let lastBracket = cleaned.lastIndex(of: "}") {
            cleaned = String(cleaned[firstBracket...lastBracket])
        }
        return cleaned
    }
}
