import Foundation

// MARK: - Error types
enum AIError: LocalizedError {
    case missingKey
    case invalidKey
    case networkError(String)
    case invalidResponse
    case quotaExceeded
    
    var errorDescription: String? {
        switch self {
        case .missingKey:
            return "Chưa có API Key. Vui lòng thêm key trong mục Profile."
        case .invalidKey:
            return "API Key không hợp lệ. Vui lòng kiểm tra lại trong mục Profile."
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
struct AISuggestedFood: Codable, Identifiable, Equatable {
    var id = UUID()
    let name: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    var servingSize: Double
    var isEaten: Bool? = nil
    var mealType: String? = nil
    
    enum CodingKeys: String, CodingKey {
        case name, calories, protein, carbs, fat, servingSize, isEaten, mealType
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
            source: "local"
        )
    }
    
    func toMealFoodModel() -> MealFoodModel {
        // AI suggestions are always treated as 1 single portion initially
        let qty = 1.0
        let baseServingSize = servingSize > 0 ? servingSize : 100.0
        
        // Store the food item with the AI-provided calories as the value for 1 portion
        let food = FoodItemModel(
            id: UUID(),
            name: name,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            servingSize: baseServingSize,
            source: "ai"
        )
        
        return MealFoodModel(
            quantity: qty,
            caloriesSnapshot: calories,
            proteinSnapshot: protein,
            carbsSnapshot: carbs,
            fatSnapshot: fat,
            isEaten: isEaten ?? false,
            foodItem: food
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
        
        var lastError: Error = AIError.quotaExceeded
        
        // Try Gemini first
        if let gemKey = geminiKey {
            do {
                return try await callGemini(apiKey: gemKey.key, remainingCalories: remainingCalories, mealType: mealType, userGoal: userGoal)
            } catch {
                lastError = error
                // Only fall through if we have OpenAI as backup
            }
        }
        
        // Fallback to OpenAI
        if let oaiKey = openAIKey {
            do {
                return try await callOpenAI(apiKey: oaiKey.key, remainingCalories: remainingCalories, mealType: mealType, userGoal: userGoal)
            } catch {
                lastError = error
            }
        }
        
        // If we reach here, both failed or only one was tried and failed
        throw lastError
    }
    
    // MARK: - Raw Generation API
    func generateText(prompt: String) async throws -> String {
        let keys = try await userRepository.fetchAPIKeys()
        let geminiKey = keys.first(where: { $0.provider == "gemini" && $0.isActive })
        let openAIKey = keys.first(where: { $0.provider == "openai" && $0.isActive })
        
        guard geminiKey != nil || openAIKey != nil else {
            throw AIError.missingKey
        }
        
        var lastError: Error = AIError.quotaExceeded
        
        if let gemKey = geminiKey {
            do {
                let cleanKey = gemKey.key.trimmingCharacters(in: .whitespacesAndNewlines)
                let url = URL(string: "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=\(cleanKey)")!
                let requestBody: [String: Any] = [
                    "contents": [["parts": [["text": prompt]]]],
                    "generationConfig": ["temperature": 0.3]
                ]
                let data = try await performRequest(url: url, body: requestBody)
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let candidates = json["candidates"] as? [[String: Any]],
                      let first = candidates.first,
                      let content = first["content"] as? [String: Any],
                      let parts = content["parts"] as? [[String: Any]],
                      let text = parts.first?["text"] as? String else {
                    throw AIError.invalidResponse
                }
                return text
            } catch {
                lastError = error
            }
        }
        
        if let oaiKey = openAIKey {
            do {
                let cleanKey = oaiKey.key.trimmingCharacters(in: .whitespacesAndNewlines)
                let url = URL(string: "https://api.openai.com/v1/chat/completions")!
                let requestBody: [String: Any] = [
                    "model": "gpt-4o-mini",
                    "messages": [["role": "user", "content": prompt]],
                    "temperature": 0.3
                ]
                let data = try await performRequest(url: url, body: requestBody, extraHeaders: ["Authorization": "Bearer \(cleanKey)"])
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let choices = json["choices"] as? [[String: Any]],
                      let first = choices.first,
                      let message = first["message"] as? [String: Any],
                      let text = message["content"] as? String else {
                    throw AIError.invalidResponse
                }
                return text
            } catch {
                lastError = error
            }
        }
        
        throw lastError
    }
    // MARK: - Chat API
    func sendChatMessage(history: [ChatMessage], systemPrompt: String) async throws -> ChatMessage {
        let keys = try await userRepository.fetchAPIKeys()
        
        let geminiKey = keys.first(where: { $0.provider == "gemini" && $0.isActive })
        let openAIKey = keys.first(where: { $0.provider == "openai" && $0.isActive })
        
        guard geminiKey != nil || openAIKey != nil else {
            throw AIError.missingKey
        }
        
        var lastError: Error = AIError.quotaExceeded
        
        if let gemKey = geminiKey {
            do {
                return try await callGeminiChat(apiKey: gemKey.key, history: history, systemPrompt: systemPrompt)
            } catch {
                lastError = error
            }
        }
        
        if let oaiKey = openAIKey {
            do {
                return try await callOpenAIChat(apiKey: oaiKey.key, history: history, systemPrompt: systemPrompt)
            } catch {
                lastError = error
            }
        }
        
        throw lastError
    }

    
    // MARK: - Gemini API
    private func callGemini(apiKey: String, remainingCalories: Double, mealType: String, userGoal: String) async throws -> [AISuggestedFood] {
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = URL(string: "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=\(cleanKey)")!
        
        let prompt = buildPrompt(remainingCalories: remainingCalories, mealType: mealType, userGoal: userGoal)
        
        let requestBody: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]],
            "generationConfig": [
                "temperature": 0.7
            ]
        ]
        
        let data = try await performRequest(url: url, body: requestBody)
        
        // Parse Gemini response structure
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let first = candidates.first,
              let content = first["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            let rawStr = String(data: data, encoding: .utf8) ?? "unknown"
            throw AIError.networkError("Cấu trúc trả về không hợp lệ:\n\(rawStr)")
        }
        
        return try parseJSONResponse(text)
    }
    
    // MARK: - OpenAI API
    private func callOpenAI(apiKey: String, remainingCalories: Double, mealType: String, userGoal: String) async throws -> [AISuggestedFood] {
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        
        let prompt = buildPrompt(remainingCalories: remainingCalories, mealType: mealType, userGoal: userGoal)
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [["role": "user", "content": prompt]],
            "temperature": 0.7,
            "max_tokens": 512
        ]
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(cleanKey)", forHTTPHeaderField: "Authorization")
        
        let data = try await performRequest(url: url, body: requestBody, extraHeaders: ["Authorization": "Bearer \(cleanKey)"])
        
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
    
    // MARK: - Chat API Implementations
    private func callGeminiChat(apiKey: String, history: [ChatMessage], systemPrompt: String) async throws -> ChatMessage {
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = URL(string: "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=\(cleanKey)")!
        
        // Convert history
        var contents: [[String: Any]] = []
        // System instructions in Gemini API are ideally passed via system_instruction field, but injecting into first user prompt is a common fallback
        // We'll inject system prompt into a dummy user message at the start if history is empty, or prepend to the first user message.
        // For simplicity, we prepend it to the first message we send, or create one.
        
        var isFirstUser = true
        for msg in history {
            let role = msg.role == .user ? "user" : "model"
            var text = msg.text
            if isFirstUser && msg.role == .user {
                text = "\(systemPrompt)\n\n\(text)"
                isFirstUser = false
            }
            contents.append(["role": role, "parts": [["text": text]]])
        }
        
        if isFirstUser { // History was empty?
            contents.append(["role": "user", "parts": [["text": systemPrompt]]])
        }

        let requestBody: [String: Any] = [
            "contents": contents,
            "generationConfig": [
                "temperature": 0.7
            ]
        ]
        
        let data = try await performRequest(url: url, body: requestBody)
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let first = candidates.first,
              let content = first["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw AIError.invalidResponse
        }
        
        return parseChatResponse(text)
    }
    
    private func callOpenAIChat(apiKey: String, history: [ChatMessage], systemPrompt: String) async throws -> ChatMessage {
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        
        var messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt]
        ]
        
        for msg in history {
            messages.append(["role": msg.role.rawValue, "content": msg.text])
        }
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 4096
        ]
        
        let data = try await performRequest(url: url, body: requestBody, extraHeaders: ["Authorization": "Bearer \(cleanKey)"])
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let text = message["content"] as? String else {
            throw AIError.invalidResponse
        }
        
        return parseChatResponse(text)
    }

    
    // MARK: - Shared Helpers
    private func buildPrompt(remainingCalories: Double, mealType: String, userGoal: String) -> String {
        """
        Bạn là chuyên gia dinh dưỡng chuyên về ẩm thực Việt Nam.
        Gợi ý 2 món ăn phù hợp cho \(mealType) với tổng lượng calo khoảng \(Int(remainingCalories)) kcal.
        Mục tiêu của người dùng: \(userGoal).
        
        QUAN TRỌNG: Chỉ trả về JSON array hợp lệ. Không giải thích thêm. Không dùng markdown code block.
        
        Định dạng JSON:
        [{"name":"Tên món","calories":350,"protein":25,"carbs":40,"fat":8,"servingSize":1.0}]
        
        Lưu ý: "servingSize" là số phần ăn (thường là 1.0). Calo và macros phải tính theo đúng số phần ăn này.
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
        request.timeoutInterval = 90
        
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
            throw AIError.invalidKey
        default:
            let errorBody = String(data: data, encoding: .utf8) ?? ""
            var errorMessage = "HTTP \(httpResponse.statusCode)"
            
            // Try to extract Google's JSON error message
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorDict = json["error"] as? [String: Any],
               let message = errorDict["message"] as? String {
                errorMessage += ": \(message)"
            }
            
            throw AIError.networkError(errorMessage)
        }
    }
    
    private func parseJSONResponse(_ text: String) throws -> [AISuggestedFood] {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Find the first '[' and last ']' to extract the JSON array
        if let firstBracket = cleaned.firstIndex(of: "["),
           let lastBracket = cleaned.lastIndex(of: "]") {
            cleaned = String(cleaned[firstBracket...lastBracket])
        } else {
            throw AIError.networkError("Không tìm thấy JSON array trong phản hồi: \(cleaned)")
        }
        
        guard let data = cleaned.data(using: .utf8) else {
            throw AIError.networkError("Không thể chuyển đổi text sang data: \(cleaned)")
        }
        
        do {
            let foods = try JSONDecoder().decode([AISuggestedFood].self, from: data)
            return foods
        } catch {
            throw AIError.networkError("Lỗi parse JSON: \(error.localizedDescription) \n\nRaw text: \(cleaned)")
        }
    }
    
    private func parseChatResponse(_ text: String) -> ChatMessage {
        let pattern = "```json(.*?)```"
        let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
        let nsString = text as NSString
        let results = regex?.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        var cleanText = text
        var foods: [AISuggestedFood]? = nil
        
        if let match = results?.last { // Find the last JSON block
            let jsonString = nsString.substring(with: match.range(at: 1))
            
            struct ActionWrapper: Codable {
                let action: String
                let items: [AISuggestedFood]?
            }
            
            if let data = jsonString.data(using: .utf8),
               let wrapper = try? JSONDecoder().decode(ActionWrapper.self, from: data) {
                if wrapper.action == "suggest_meal" || wrapper.action == "meal_plan" {
                    foods = wrapper.items
                    // Only remove the block from the text if it's a known chat/daily action
                    cleanText = nsString.replacingCharacters(in: match.range, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                }
                // For "weekly_plan", we intentionally leave the JSON in cleanText
                // so MealPlanViewModel can parse it manually.
            }
        }
        
        return ChatMessage(role: .assistant, text: cleanText, suggestedFoods: foods)
    }
}
