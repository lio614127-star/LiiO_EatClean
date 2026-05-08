import re

with open('/Users/liio/TooL_LiiO/LiiO_EatClean/LiiO_EatClean/Features/AI/AIService.swift', 'r') as f:
    content = f.read()

start_marker = "// MARK: - AIService"
end_marker = "    // MARK: - Gemini API"

start_idx = content.find(start_marker)
end_idx = content.find(end_marker)

if start_idx != -1 and end_idx != -1:
    new_chunk = """// MARK: - MealPlanDay Structure for Distributed Fetch
struct MealPlanDay {
    let dayIndex: Int
    let meals: [AISuggestedFood]
}

// MARK: - AIService
class AIService {
    static let shared = AIService()
    
    private let userRepository: UserRepositoryProtocol
    private let poolManager: APIKeyPoolManager
    
    init(userRepository: UserRepositoryProtocol = UserRepository()) {
        self.userRepository = userRepository
        self.poolManager = APIKeyPoolManager(repository: userRepository)
    }
    
    private func executeWithRetry<T>(operation: (APIKeyModel) async throws -> T) async throws -> T {
        try await poolManager.loadKeys()
        
        var lastError: Error = AIError.missingKey
        
        for _ in 0..<3 { // Max 3 retries
            guard let key = await poolManager.getBestKey() else {
                throw AIError.missingKey
            }
            
            do {
                let result = try await operation(key)
                try await poolManager.reportSuccess(keyID: key.id)
                return result
            } catch {
                lastError = error
                
                var statusCode = -1
                if let aiError = error as? AIError {
                    switch aiError {
                    case .invalidKey: statusCode = 401
                    case .quotaExceeded: statusCode = 429
                    default: statusCode = -1001
                    }
                } else if let nsError = error as NSError?, nsError.code == NSURLErrorTimedOut {
                    statusCode = -1001
                }
                
                try await poolManager.reportError(keyID: key.id, statusCode: statusCode)
            }
        }
        
        throw lastError
    }
    
    func suggestMeals(remainingCalories: Double, mealType: String, userGoal: String = "Duy trì cân nặng") async throws -> [AISuggestedFood] {
        return try await executeWithRetry { key in
            if key.provider == "gemini" {
                return try await self.callGemini(apiKey: key.key, remainingCalories: remainingCalories, mealType: mealType, userGoal: userGoal)
            } else {
                return try await self.callOpenAI(apiKey: key.key, remainingCalories: remainingCalories, mealType: mealType, userGoal: userGoal)
            }
        }
    }
    
    // MARK: - Distributed Workload
    func generateDistributedMealPlan(days: Int, dailyCalories: Double) async throws -> [MealPlanDay] {
        return try await withThrowingTaskGroup(of: MealPlanDay.self) { group in
            // Chunk into days, each day gets its own request to the pool manager
            for i in 1...days {
                group.addTask {
                    let meals = try await self.suggestMeals(remainingCalories: dailyCalories, mealType: "Cả ngày", userGoal: "Lên thực đơn")
                    return MealPlanDay(dayIndex: i, meals: meals)
                }
            }
            
            var allDays: [MealPlanDay] = []
            for try await dayResult in group {
                allDays.append(dayResult)
            }
            return allDays.sorted { $0.dayIndex < $1.dayIndex }
        }
    }
    
    // MARK: - Raw Generation API
    func generateText(prompt: String) async throws -> String {
        return try await executeWithRetry { key in
            let cleanKey = key.key.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if key.provider == "gemini" {
                let url = URL(string: "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=\(cleanKey)")!
                let requestBody: [String: Any] = [
                    "contents": [["parts": [["text": prompt]]]],
                    "generationConfig": ["temperature": 0.3]
                ]
                let data = try await self.performRequest(url: url, body: requestBody)
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let candidates = json["candidates"] as? [[String: Any]],
                      let first = candidates.first,
                      let content = first["content"] as? [String: Any],
                      let parts = content["parts"] as? [[String: Any]],
                      let text = parts.first?["text"] as? String else {
                    throw AIError.invalidResponse
                }
                return text
            } else {
                let url = URL(string: "https://api.openai.com/v1/chat/completions")!
                let requestBody: [String: Any] = [
                    "model": "gpt-4o-mini",
                    "messages": [["role": "user", "content": prompt]],
                    "temperature": 0.3
                ]
                let data = try await self.performRequest(url: url, body: requestBody, extraHeaders: ["Authorization": "Bearer \(cleanKey)"])
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let choices = json["choices"] as? [[String: Any]],
                      let first = choices.first,
                      let message = first["message"] as? [String: Any],
                      let text = message["content"] as? String else {
                    throw AIError.invalidResponse
                }
                return text
            }
        }
    }
    
    // MARK: - Chat API
    func sendChatMessage(history: [ChatMessage], systemPrompt: String) async throws -> ChatMessage {
        return try await executeWithRetry { key in
            if key.provider == "gemini" {
                return try await self.callGeminiChat(apiKey: key.key, history: history, systemPrompt: systemPrompt)
            } else {
                return try await self.callOpenAIChat(apiKey: key.key, history: history, systemPrompt: systemPrompt)
            }
        }
    }

"""
    new_content = content[:start_idx] + new_chunk + content[end_idx:]
    with open('/Users/liio/TooL_LiiO/LiiO_EatClean/LiiO_EatClean/Features/AI/AIService.swift', 'w') as f:
        f.write(new_content)
    print("Replaced successfully")
else:
    print("Could not find markers")
