import Foundation

struct OpenFoodFactsProduct: Codable {
    let productName: String?
    let nutriments: Nutriments?
    let brands: String?
    
    struct Nutriments: Codable {
        let energyKcal100g: Double?
        let proteins100g: Double?
        let carbohydrates100g: Double?
        let fat100g: Double?
        
        enum CodingKeys: String, CodingKey {
            case energyKcal100g = "energy-kcal_100g"
            case proteins100g = "proteins_100g"
            case carbohydrates100g = "carbohydrates_100g"
            case fat100g = "fat_100g"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case nutriments
        case brands
    }
}

struct OpenFoodFactsResponse: Codable {
    let product: OpenFoodFactsProduct?
    let status: Int
}

class OpenFoodFactsService {
    private var cache: [String: FoodItemModel] = [:]
    
    func lookupBarcode(_ barcode: String) async throws -> FoodItemModel? {
        if let cached = cache[barcode] {
            return cached
        }
        
        let urlString = "https://world.openfoodfacts.org/api/v2/product/\(barcode).json"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("LiiO_EatClean - iOS - Version 1.1", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return nil // Not found or error
        }
        
        let offResponse = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: data)
        
        guard offResponse.status == 1, let product = offResponse.product else {
            return nil
        }
        
        let name = product.productName ?? "Sản phẩm không tên"
        let brand = product.brands.flatMap { " (\($0))" } ?? ""
        let fullName = name + brand
        
        let cals = product.nutriments?.energyKcal100g ?? 0.0
        let protein = product.nutriments?.proteins100g ?? 0.0
        let carbs = product.nutriments?.carbohydrates100g ?? 0.0
        let fat = product.nutriments?.fat100g ?? 0.0
        
        let food = FoodItemModel(
            id: UUID(),
            name: fullName,
            calories: cals,
            protein: protein,
            carbs: carbs,
            fat: fat,
            servingSize: 1.0, // Assuming 1 serving = 100g/ml by default from this API if no serving size provided
            source: "openfoodfacts"
        )
        
        cache[barcode] = food
        return food
    }
}
