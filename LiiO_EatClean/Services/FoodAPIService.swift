import Foundation

protocol FoodAPIServiceProtocol {
    func search(query: String) async throws -> [FoodItemModel]
}

class FoodAPIService: FoodAPIServiceProtocol {
    // Note: For production, fetch API key from CoreData or securely injected environment
    // Hardcoded demo key for v1.
    private let apiKey = "YOUR_CALORIENINJAS_API_KEY_HERE"
    private let baseURL = "https://api.calorieninjas.com/v1/nutrition"
    
    struct APIResponse: Codable {
        let items: [APIFoodItem]
    }
    
    struct APIFoodItem: Codable {
        let name: String
        let calories: Double
        let protein_g: Double
        let carbohydrates_total_g: Double
        let fat_total_g: Double
        let serving_size_g: Double
    }
    
    func search(query: String) async throws -> [FoodItemModel] {
        guard !query.isEmpty,
              let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)?query=\(encodedQuery)") else {
            return []
        }
        
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                // Silent fallback logic: if API fails, return empty array
                return []
            }
            
            let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
            
            return apiResponse.items.map { item in
                FoodItemModel(
                    id: UUID(),
                    name: item.name.capitalized,
                    calories: item.calories,
                    protein: item.protein_g,
                    carbs: item.carbohydrates_total_g,
                    fat: item.fat_total_g,
                    servingSize: item.serving_size_g,
                    source: "api",
                    isCustom: false
                )
            }
        } catch {
            // Silent fallback on any network/decoding error
            return []
        }
    }
}
