import Foundation

// MARK: - Error types
enum AIError: LocalizedError {
    case missingKey
    case networkError(String)
    case invalidResponse
    case quotaExceeded
    
    var errorDescription: String? {
        switch self {
        case .missingKey:
            return "Chưa có API Key. Vui lòng thêm key trong mục Profile."
        case .networkError(let msg):
            return "Lỗi mạng: \(msg)"
        case .invalidResponse:
            return "AI trả về dữ liệu không hợp lệ. Vui lòng thử lại."
        case .quotaExceeded:
            return "Hệ thống AI đang bận. Vui lòng thử lại sau."
        }
    }
}

// MARK: - Response model for parsing AI-suggested foods
struct AISuggestedFood: Codable, Identifiable {
    var id = UUID()
    let name: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let servingSize: Double
    
    enum CodingKeys: String, CodingKey {
        case name, calories, protein, carbs, fat, servingSize
    }
    
    func toFoodItemModel() -> FoodItemModel {
        FoodItemModel(
            id: UUID(),
            name: name,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            servingSize: servingSize,
            source: .local
        )
    }
}

// MARK: - AIService
class AIService {
    static let shared = AIService()
    
    private let userRepository: UserRepositoryProtocol
    
    init(userRepository: UserRepositoryProtocol = UserRepository()) {
        self.userRepository = userRepository
    }
    
    func suggestMeals(remainingCalories: Double, mealType: String, userGoal: String = "Duy trì cân nặng") async throws -> [AISuggestedFood] {
        let keys = try await userRepository.fetchAPIKeys()
        
        // Try Gemini first, then OpenAI
        let geminiKey = keys.first(where: { $0.provider == "gemini" && $0.isActive })
        let openAIKey = keys.first(where: { $0.provider == "openai" && $0.isActive })
        
        guard geminiKey != nil || openAIKey != nil else {
            throw AIError.missingKey
        }
        
        // Try Gemini first
        if let gemKey = geminiKey {
            do {
                return try await callGemini(apiKey: gemKey.key, remainingCalories: remainingCalories, mealType: mealType, userGoal: userGoal)
            } catch AIError.quotaExceeded {
                // Fall through to OpenAI
            } catch AIError.missingKey {
                // Fall through
            }
        }
        
        // Fallback to OpenAI
        if let oaiKey = openAIKey {
            return try await callOpenAI(apiKey: oaiKey.key, remainingCalories: remainingCalories, mealType: mealType, userGoal: userGoal)
        }
        
        throw AIError.quotaExceeded
    }
    
    // MARK: - Gemini API
    private func callGemini(apiKey: String, remainingCalories: Double, mealType: String, userGoal: String) async throws -> [AISuggestedFood] {
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=\(apiKey)")!
        
        let prompt = buildPrompt(remainingCalories: remainingCalories, mealType: mealType, userGoal: userGoal)
        
        let requestBody: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]],
            "generationConfig": ["temperature": 0.7, "maxOutputTokens": 512]
        ]
        
        let data = try await performRequest(url: url, body: requestBody)
        
        // Parse Gemini response structure
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let first = candidates.first,
              let content = first["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw AIError.invalidResponse
        }
        
        return try parseJSONResponse(text)
    }
    
    // MARK: - OpenAI API
    private func callOpenAI(apiKey: String, remainingCalories: Double, mealType: String, userGoal: String) async throws -> [AISuggestedFood] {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        
        let prompt = buildPrompt(remainingCalories: remainingCalories, mealType: mealType, userGoal: userGoal)
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [["role": "user", "content": prompt]],
            "temperature": 0.7,
            "max_tokens": 512
        ]
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let data = try await performRequest(url: url, body: requestBody, extraHeaders: ["Authorization": "Bearer \(apiKey)"])
        
        // Parse OpenAI response structure
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let text = message["content"] as? String else {
            throw AIError.invalidResponse
        }
        
        return try parseJSONResponse(text)
    }
    
    // MARK: - Shared Helpers
    private func buildPrompt(remainingCalories: Double, mealType: String, userGoal: String) -> String {
        """
        Bạn là chuyên gia dinh dưỡng chuyên về ẩm thực Việt Nam.
        Gợi ý 2 món ăn phù hợp cho \(mealType) với tổng lượng calo khoảng \(Int(remainingCalories)) kcal.
        Mục tiêu của người dùng: \(userGoal).
        
        QUAN TRỌNG: Chỉ trả về JSON array hợp lệ. Không giải thích thêm. Không dùng markdown code block.
        
        Định dạng JSON:
        [{"name":"Tên món","calories":350,"protein":25,"carbs":40,"fat":8,"servingSize":200}]
        """
    }
    
    private func performRequest(url: URL, body: [String: Any], extraHeaders: [String: String] = [:]) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        for (key, value) in extraHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.networkError("Không nhận được HTTP response")
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return data
        case 429:
            throw AIError.quotaExceeded
        case 401, 403:
            throw AIError.missingKey
        default:
            throw AIError.networkError("HTTP \(httpResponse.statusCode)")
        }
    }
    
    private func parseJSONResponse(_ text: String) throws -> [AISuggestedFood] {
        // Clean markdown fences if present
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```") {
            // Remove first and last ``` lines
            let lines = cleaned.components(separatedBy: "\n")
            let bodyLines = lines.dropFirst().dropLast().filter { !$0.hasPrefix("```") }
            cleaned = bodyLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Also handle ```json prefix specifically
        cleaned = cleaned.replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleaned.data(using: .utf8) else {
            throw AIError.invalidResponse
        }
        
        do {
            let foods = try JSONDecoder().decode([AISuggestedFood].self, from: data)
            return foods
        } catch {
            throw AIError.invalidResponse
        }
    }
}
