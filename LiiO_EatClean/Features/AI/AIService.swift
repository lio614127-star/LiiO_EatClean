import Foundation

// MARK: - Error types
enum AIError: LocalizedError {
    case missingKey
    case invalidKey
    case networkError(String)
    case invalidResponse
    case quotaExceeded
    case offline
    
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
        case .offline:
            return "Không có kết nối mạng. Vui lòng thử lại khi có internet."
        }
    }
}

enum AIRequestType {
    // Lite Tier (v1beta, Flash-Lite)
    case parsing
    case classification
    case memoryExtraction
    case formatting
    case activityTracking
    case barcodeAnalysis
    case toneRewrite
    
    // Main Tier (v1beta, Flash)
    case chat
    case mealSuggestion
    case mealPlanDay
    case dailySummary
    case ocrRecognition
    case voiceParsing
    case insightDetection
    
    // Reasoning Tier (v1, Pro)
    case weeklyPlan
    case trendAnalysis
    case contextCompression
    case healthReasoning
    case personalization
}

struct AIModelInfo: Equatable, Codable {
    let name: String
    let provider: String
    let status: String
    var icon: String {
        provider == "gemini" ? "sparkles" : "bolt.fill"
    }
}

enum AIChatStreamResult {
    case modelInfo(AIModelInfo)
    case chunk(String)
    case suggestions([AISuggestedFood])
    case finalCleanText(String)  // Cleaned text with JSON blocks stripped — replaces accumulated chunks
    case error(String)
}

// MARK: - Response model for parsing AI-suggested foods
struct AISuggestedFood: Codable, Identifiable, Equatable {
    var id = UUID()
    let name: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var servingSize: Double
    var isEaten: Bool? = nil
    var mealType: String? = nil
    
    // v1.3: Smart Units & Recipe Details
    var unit: String? = nil
    var weightInGrams: Double? = nil
    var ingredients: [IngredientDTO]? = nil
    var instructions: [String]? = nil
    
    enum CodingKeys: String, CodingKey {
        case name, calories, protein, carbs, fat, servingSize, isEaten, mealType, unit, weightInGrams, ingredients, instructions
    }
}

struct IngredientDTO: Codable, Equatable {
    let name: String
    let amount: Double
    let unit: String
    let protein: Double?
    let carbs: Double?
    let fat: Double?
    
    init(name: String, amount: Double, unit: String, protein: Double? = nil, carbs: Double? = nil, fat: Double? = nil) {
        self.name = name
        self.amount = amount
        self.unit = unit
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }
}

extension AISuggestedFood {
    func toFoodItemModel() -> FoodItemModel {
        FoodItemModel(
            id: id,
            name: name,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            servingSize: servingSize,
            source: "local",
            unit: unit,
            weightInGrams: weightInGrams,
            ingredients: ingredients?.map { IngredientModel(name: $0.name, amount: $0.amount, unit: $0.unit, protein: $0.protein, carbs: $0.carbs, fat: $0.fat) },
            instructions: instructions,
            isRecipeCached: instructions != nil
        )
    }

    func toPlannedFoodItemModel() -> PlannedFoodItemModel {
        PlannedFoodItemModel(
            id: id,
            name: name,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            servingSize: servingSize
        )
    }

    func toMealFoodModel() -> MealFoodModel {
        // AI suggestions are always treated as 1 single portion initially
        let qty = 1.0
        let baseServingSize = servingSize > 0 ? servingSize : 100.0
        
        // Store the food item with the AI-provided calories as the value for 1 portion
        let food = FoodItemModel(
            id: id,
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

// MARK: - MealPlanDay Structure for Distributed Fetch
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
    
    private func executeWithRetry<T>(task: AIRequestType, feature: String, forcedKey: APIKeyModel? = nil, subTasks: [String] = [], isInternal: Bool = false, operation: @escaping (APIKeyModel, AIModelConfig) async throws -> T) async throws -> T {
        guard NetworkMonitor.shared.isConnected else {
            throw AIError.offline
        }
        
        try await poolManager.loadKeys()
        
        var lastError: Error = AIError.missingKey
        var activityID: UUID? = nil
        
        for attempt in 0..<3 {
            let key: APIKeyModel
            // Use forcedKey for first attempt, but allow fallback to best available key if it fails
            if attempt == 0, let forced = forcedKey {
                key = forced
            } else {
                guard let best = await poolManager.getBestKey(for: task) else {
                    throw AIError.missingKey
                }
                key = best
            }
            
            let tier: AIModelTier = (key.isPaid == true) ? .paid : .free
            let config = AIModelRouter.shared.getBestConfig(for: task, tier: tier, provider: key.provider)
            
            if activityID == nil {
                activityID = await AIActivityCenter.shared.startTask(
                    feature: feature,
                    model: config.modelName,
                    provider: key.provider,
                    initialStatus: "Đang chuẩn bị...",
                    keyName: key.name ?? (key.isPaid == true ? "Paid Key" : "Free Key"),
                    keyTier: key.isPaid == true ? "PAID" : "FREE",
                    subTasks: subTasks,
                    isInternal: isInternal
                )
            }
            
            do {
                await AIActivityCenter.shared.updateTask(id: activityID!, status: .processing("Đang xử lý..."), model: config.modelName, provider: key.provider)
                let result = try await operation(key, config)
                try await poolManager.reportSuccess(keyID: key.id)
                await AIActivityCenter.shared.updateTask(id: activityID!, status: .completed, progressText: "✓ Hoàn tất")
                return result
            } catch {
                lastError = error
                
                // Check if we should try a fallback config (e.g. v1 -> v1beta)
                if let aiError = error as? AIError, case .networkError(let msg) = aiError, msg.contains("404") {
                    if let fallbackConfig = AIModelRouter.shared.getFallbackConfig(for: config) {
                        await AIActivityCenter.shared.updateTask(id: activityID!, status: .swapping("Đang đổi endpoint..."), model: fallbackConfig.modelName)
                        do {
                            let result = try await operation(key, fallbackConfig)
                            try await poolManager.reportSuccess(keyID: key.id)
                            await AIActivityCenter.shared.updateTask(id: activityID!, status: .completed, progressText: "✓ Hoàn tất")
                            return result
                        } catch {
                            lastError = error
                        }
                    }
                }
                
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
                
                if attempt < 2 {
                    await AIActivityCenter.shared.updateTask(id: activityID!, status: .swapping("Lỗi, đang đổi key..."))
                }
            }
        }
        
        await AIActivityCenter.shared.updateTask(id: activityID!, status: .failed(lastError.localizedDescription))
        throw lastError
    }
    
    // MARK: - Streaming Orchestrator
    private func executeWithRetryStream(task: AIRequestType, feature: String, forcedKey: APIKeyModel? = nil, subTasks: [String] = [], isInternal: Bool = false, operation: @escaping (APIKeyModel, AIModelConfig) -> AsyncThrowingStream<AIChatStreamResult, Error>) -> AsyncThrowingStream<AIChatStreamResult, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                guard NetworkMonitor.shared.isConnected else {
                    continuation.finish(throwing: AIError.offline)
                    return
                }
                
                try await poolManager.loadKeys()
                
                var activityID: UUID? = nil
                var lastError: Error = AIError.missingKey
                
                for attempt in 0..<3 {
                    let key: APIKeyModel
                    // Use forcedKey for first attempt, but allow fallback to best available key if it fails
                    if attempt == 0, let forced = forcedKey {
                        key = forced
                    } else {
                        guard let best = await poolManager.getBestKey(for: task) else {
                            continuation.finish(throwing: AIError.missingKey)
                            return
                        }
                        key = best
                    }
                    
                    var success = false
                    let tier: AIModelTier = (key.isPaid == true) ? .paid : .free
                    var config = AIModelRouter.shared.getBestConfig(for: task, tier: tier, provider: key.provider)
                    
                    if activityID == nil {
                        activityID = await AIActivityCenter.shared.startTask(
                            feature: feature,
                            model: config.modelName,
                            provider: key.provider,
                            initialStatus: "Đang chuẩn bị...",
                            keyName: key.name ?? (key.isPaid == true ? "Paid Key" : "Free Key"),
                            keyTier: key.isPaid == true ? "PAID" : "FREE",
                            subTasks: subTasks,
                            isInternal: isInternal
                        )
                    }
                    
                    await AIActivityCenter.shared.updateTask(
                        id: activityID!,
                        status: .thinking,
                        model: config.modelName,
                        provider: key.provider,
                        progressText: "Đang suy nghĩ..."
                    )
                    
                    do {
                        for try await result in operation(key, config) {
                            success = true
                            switch result {
                            case .modelInfo(let info):
                                await AIActivityCenter.shared.updateTask(id: activityID!, status: .streaming("Đang phản hồi..."), progressText: info.status)
                                continuation.yield(.modelInfo(info))
                            case .chunk(let text):
                                continuation.yield(.chunk(text))
                            case .suggestions(let foods):
                                continuation.yield(.suggestions(foods))
                            case .finalCleanText(let text):
                                continuation.yield(.finalCleanText(text))
                            case .error(let msg):
                                continuation.yield(.error(msg))
                            }
                        }
                        
                        try await poolManager.reportSuccess(keyID: key.id)
                        await AIActivityCenter.shared.updateTask(id: activityID!, status: .completed, progressText: "✓ Hoàn tất")
                        continuation.finish()
                        return
                    } catch {
                        lastError = error
                        
                        // Check if fallback needed (404)
                        if let aiError = error as? AIError, case .networkError(let msg) = aiError, msg.contains("404"),
                           let fallbackConfig = AIModelRouter.shared.getFallbackConfig(for: config) {
                            config = fallbackConfig
                            await AIActivityCenter.shared.updateTask(id: activityID!, status: .swapping("Đang chuyển đổi..."), model: config.modelName)
                            do {
                                for try await result in operation(key, config) {
                                    success = true
                                    continuation.yield(result)
                                }
                                try await poolManager.reportSuccess(keyID: key.id)
                                await AIActivityCenter.shared.updateTask(id: activityID!, status: .completed, progressText: "✓ Hoàn tất")
                                continuation.finish()
                                return
                            } catch {
                                lastError = error
                            }
                        }
                        
                        var statusCode = -1
                        if let aiError = error as? AIError {
                            switch aiError {
                            case .invalidKey: statusCode = 401
                            case .quotaExceeded: statusCode = 429
                            default: statusCode = -1001
                            }
                        }
                        try await poolManager.reportError(keyID: key.id, statusCode: statusCode)
                        
                        if attempt < 2 {
                            await AIActivityCenter.shared.updateTask(id: activityID!, status: .swapping("Lỗi, đang đổi key..."))
                        }
                    }
                }
                
                await AIActivityCenter.shared.updateTask(id: activityID!, status: .failed(lastError.localizedDescription))
                continuation.finish(throwing: lastError)
            }
        }
    }
    
    func generateDayPlanStream(targetCalories: Double, userContext: String, completedMealTypes: [String] = [], isInternal: Bool = false) -> AsyncThrowingStream<AIChatStreamResult, Error> {
        let allMealTypes = ["Bữa sáng", "Bữa trưa", "Bữa tối", "Ăn vặt"]
        let mealsToPlan = allMealTypes.filter { !completedMealTypes.contains($0) }
        let mealsToPlanText = mealsToPlan.joined(separator: ", ")
        let completedText = completedMealTypes.isEmpty ? "Chưa có bữa nào được ăn." : "Các bữa đã ăn: \(completedMealTypes.joined(separator: ", "))."

        let prompt = """
        Bạn là chuyên gia dinh dưỡng chuyên về ẩm thực Việt Nam.
        Nhiệm vụ: Lên kế hoạch ăn uống ĐẦY ĐỦ cho ngày hôm nay.
        
        [Dữ liệu người dùng]
        \(userContext)
        
        YÊU CẦU:
        1. Bạn BẮT BUỘC phải đề xuất ĐỦ 4 BỮA: Bữa sáng, Bữa trưa, Bữa tối, Ăn vặt.
        2. Tổng ngân sách calo cả ngày: ~\(Int(targetCalories)) kcal.
        3. Hãy chia đều calo hợp lý: Sáng (25%), Trưa (35%), Tối (30%), Ăn vặt (10%).
        4. Mỗi bữa đề xuất 1 món chính kèm món phụ đặc trưng Việt Nam.
        5. Cung cấp chi tiết nguyên liệu, hướng dẫn nấu, đơn vị (unit) và khối lượng (weightInGrams) cho mỗi món.
        
        PHẢI TRẢ VỀ JSON ARRAY PHẲNG gồm đúng 4 đối tượng. Mỗi đối tượng có "mealType" là một trong: Bữa sáng, Bữa trưa, Bữa tối, Ăn vặt.
        
        Định dạng JSON:
        ```json
        [
          {
            "name": "Tên món",
            "calories": 350,
            "protein": 25,
            "carbs": 40,
            "fat": 8,
            "servingSize": 1.0,
            "mealType": "Bữa sáng",
            "unit": "tô",
            "weightInGrams": 450,
            "ingredients": [
              {"name": "Bánh canh", "amount": 150, "unit": "g", "protein": 5, "carbs": 30, "fat": 1},
              {"name": "Thịt heo", "amount": 50, "unit": "g", "protein": 10, "carbs": 0, "fat": 5}
            ],
            "instructions": [
              "Đun sôi nước dùng...",
              "Cho bánh canh vào..."
            ]
          }
        ]
        ```
        """
        
        return executeWithRetryStream(task: .mealPlanDay, feature: "Lập kế hoạch siêu tốc", subTasks: ["Tối ưu \(mealsToPlan.count) bữa ăn"], isInternal: isInternal) { key, config in
            self.callGeminiChatStream(apiKey: key.key, history: [], systemPrompt: prompt, config: config)
        }
    }
    
    func suggestMeals(remainingCalories: Double, mealType: String, userGoal: String = "Duy trì cân nặng", isInternal: Bool = false) async throws -> [AISuggestedFood] {
        return try await executeWithRetry(task: .mealSuggestion, feature: "Gợi ý món ăn", subTasks: ["Gợi ý: \(mealType)"], isInternal: isInternal) { key, config in
            if config.provider == "gemini" {
                return try await self.callGemini(apiKey: key.key, remainingCalories: remainingCalories, mealType: mealType, userGoal: userGoal, config: config)
            } else {
                return try await self.callOpenAI(apiKey: key.key, remainingCalories: remainingCalories, mealType: mealType, userGoal: userGoal, config: config)
            }
        }
    }
    
    func enrichFoodItem(name: String, calories: Double, isInternal: Bool = true) async throws -> AISuggestedFood? {
        return try await executeWithRetry(task: .formatting, feature: "Phân tích món ăn", subTasks: ["Bóc tách: \(name)"], isInternal: isInternal) { key, config in
            let prompt = """
            Bạn là chuyên gia dinh dưỡng. Hãy bóc tách chi tiết nguyên liệu và hướng dẫn nấu ăn cho món sau:
            Tên món: \(name)
            Lượng calo ước tính: \(Int(calories)) kcal
            
            YÊU CẦU:
            1. Bóc tách danh sách nguyên liệu (ingredients) với khối lượng (amount) và đơn vị (unit).
            2. Sắp xếp nguyên liệu: các nguyên liệu chính (thịt, cá, rau, gạo...) lên đầu, các gia vị (muối, đường, mắm, dầu ăn...) xuống cuối danh sách.
            3. Cung cấp hướng dẫn nấu ăn (instructions) ngắn gọn.
            4. Trả về DUY NHẤT một đối tượng JSON.
            
            Định dạng JSON:
            {
              "name": "\(name)",
              "calories": \(Int(calories)),
              "protein": 0,
              "carbs": 0,
              "fat": 0,
              "servingSize": 1.0,
              "unit": "phần",
              "ingredients": [{"name": "...", "amount": 100, "unit": "g", "protein": 10, "carbs": 20, "fat": 5}],
              "instructions": ["Bước 1...", "Bước 2..."]
            }
            """
            
            let text = if config.provider == "gemini" {
                try await self.executeGeminiRequest(version: config.endpoint, model: config.modelName, apiKey: key.key, prompt: prompt)
            } else {
                // OpenAI implementation similar to generateText
                try await self.generateText(prompt: prompt, requestType: .formatting, feature: "Phân tích món ăn", forcedKey: key, isInternal: true)
            }
            
            let msg = self.parseChatResponse(text)
            return msg.suggestedFoods?.first
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
    
    // MARK: - Validation
    func testGeminiKey(_ key: String) async throws -> (version: String, isPaid: Bool) {
        let cleanKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Step 1: Detect version using Flash (most compatible)
        let versions = ["v1beta", "v1"]
        var detectedVersion = "v1beta"
        var success = false
        
        for version in versions {
            let url = URL(string: "https://generativelanguage.googleapis.com/\(version)/models/gemini-2.5-flash:generateContent?key=\(cleanKey)")!
            let requestBody: [String: Any] = [
                "contents": [["parts": [["text": "hi"]]]],
                "generationConfig": ["maxOutputTokens": 5]
            ]
            
            do {
                _ = try await performRequest(url: url, body: requestBody)
                detectedVersion = version
                success = true
                break
            } catch {
                if let aiError = error as? AIError, case .networkError(let msg) = aiError, msg.contains("404") {
                    continue
                }
                // If it's a 403 or 429, the key might be valid but restricted/busy, but we'll consider it "working" if we get a response
                if let aiError = error as? AIError, case .networkError(let msg) = aiError, (msg.contains("403") || msg.contains("429")) {
                    detectedVersion = version
                    success = true
                    break
                }
            }
        }
        
        if !success { throw AIError.invalidKey }
        
        // Step 2: Detect if Paid (check if Pro is accessible on v1)
        var isPaid = false
        let proUrl = URL(string: "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-pro:generateContent?key=\(cleanKey)")!
        do {
            _ = try await performRequest(url: proUrl, body: [
                "contents": [["parts": [["text": "hi"]]]],
                "generationConfig": ["maxOutputTokens": 5]
            ])
            isPaid = true
        } catch {
            // Failure on Pro (403/404) means it's a Free key
            isPaid = false
        }
        
        return (version: detectedVersion, isPaid: isPaid)
    }
    
    func testOpenAIKey(_ key: String) async throws -> Bool {
        let cleanKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [["role": "user", "content": "hi"]],
            "max_tokens": 5
        ]
        
        do {
            _ = try await performRequest(url: url, body: requestBody, extraHeaders: ["Authorization": "Bearer \(cleanKey)"])
            return true
        } catch {
            // Enhanced error message for OpenAI
            if let aiError = error as? AIError, case .quotaExceeded = aiError {
                throw AIError.networkError("OpenAI: Tài khoản của bạn đã hết hạn mức (Quota) hoặc hết tiền. Vui lòng kiểm tra lại billing.")
            }
            throw error
        }
    }
    
    // MARK: - Raw Generation API
    func quickReask(prompt: String) async throws -> String {
        return try await generateText(prompt: prompt, requestType: .chat, feature: "Re-ask An Toàn", isInternal: true)
    }
    
    func quickReaskForFood(prompt: String, isInternal: Bool = false) async throws -> [AISuggestedFood] {
        let text = try await generateText(prompt: prompt, requestType: .chat, feature: "Re-ask An Toàn", isInternal: isInternal)
        let msg = parseChatResponse(text)
        return msg.suggestedFoods ?? []
    }
    
    func generateText(prompt: String, requestType: AIRequestType = .chat, feature: String = "AI Generation", forcedKey: APIKeyModel? = nil, subTasks: [String] = [], isInternal: Bool = false) async throws -> String {
        return try await executeWithRetry(task: requestType, feature: feature, forcedKey: forcedKey, subTasks: subTasks, isInternal: isInternal) { key, config in
            let cleanKey = key.key.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if config.provider == "gemini" {
                return try await self.executeGeminiRequest(version: config.endpoint, model: config.modelName, apiKey: cleanKey, prompt: prompt)
            } else {
                let url = URL(string: "https://api.openai.com/v1/chat/completions")!
                let requestBody: [String: Any] = [
                    "model": config.modelName,
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
    func sendChatMessage(history: [ChatMessageModel], systemPrompt: String, task: AIRequestType = .chat, feature: String = "AI Coach", forcedKey: APIKeyModel? = nil, subTasks: [String] = [], isInternal: Bool = false) async throws -> ChatMessageModel {
        return try await executeWithRetry(task: task, feature: feature, forcedKey: forcedKey, subTasks: subTasks, isInternal: isInternal) { key, config in
            try await self.callGeminiChat(apiKey: key.key, history: history, systemPrompt: systemPrompt, config: config)
        }
    }
    
    func sendChatMessageStream(history: [ChatMessageModel], systemPrompt: String, task: AIRequestType = .chat, feature: String = "AI Coach Chat", forcedKey: APIKeyModel? = nil, subTasks: [String] = [], isInternal: Bool = false) -> AsyncThrowingStream<AIChatStreamResult, Error> {
        return executeWithRetryStream(task: task, feature: feature, forcedKey: forcedKey, subTasks: subTasks, isInternal: isInternal) { key, config in
            self.callGeminiChatStream(apiKey: key.key, history: history, systemPrompt: systemPrompt, config: config)
        }
    }

    // MARK: - Gemini API
    private func callGemini(apiKey: String, remainingCalories: Double, mealType: String, userGoal: String, config: AIModelConfig) async throws -> [AISuggestedFood] {
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = URL(string: "https://generativelanguage.googleapis.com/\(config.endpoint)/models/\(config.modelName):generateContent?key=\(cleanKey)")!
        
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
    private func callOpenAI(apiKey: String, remainingCalories: Double, mealType: String, userGoal: String, config: AIModelConfig) async throws -> [AISuggestedFood] {
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        
        let prompt = buildPrompt(remainingCalories: remainingCalories, mealType: mealType, userGoal: userGoal)
        
        let requestBody: [String: Any] = [
            "model": config.modelName,
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
    private func callGeminiChat(apiKey: String, history: [ChatMessageModel], systemPrompt: String, config: AIModelConfig) async throws -> ChatMessageModel {
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = URL(string: "https://generativelanguage.googleapis.com/\(config.endpoint)/models/\(config.modelName):generateContent?key=\(cleanKey)")!
        
        // Convert history
        var contents: [[String: Any]] = []
        
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
    
    private func callOpenAIChat(apiKey: String, history: [ChatMessageModel], systemPrompt: String, config: AIModelConfig) async throws -> ChatMessageModel {
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        
        var messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt]
        ]
        
        for msg in history {
            messages.append(["role": msg.role.rawValue, "content": msg.text])
        }
        
        let requestBody: [String: Any] = [
            "model": config.modelName,
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
        
        YÊU CẦU:
        1. Món ăn phải PHÙ HỢP với thói quen ăn uống của người Việt theo \(mealType):
           - Bữa sáng: Ưu tiên món nước (Phở, Bún, Hủ tiếu), Bánh mì, Xôi, các món nhanh.
           - Bữa trưa/Bữa tối: Ưu tiên cơm gia đình (Món mặn + Canh + Rau), hoặc các món chính no lâu.
           - Ăn vặt: Trái cây, sữa chua, hạt, hoặc các món ăn nhẹ.
        2. Tự động nhận diện đơn vị phù hợp (chén, tô, dĩa, cái, gram) cho từng món.
        3. Bóc tách nguyên liệu (ingredients) và hướng dẫn nấu ăn (instructions).
        4. Sắp xếp nguyên liệu: các nguyên liệu chính (thịt, cá, rau, gạo...) lên đầu, các gia vị (muối, đường, mắm, dầu ăn...) xuống cuối danh sách.
        5. CHỈ sử dụng tên món bằng tiếng Việt, không kèm tên tiếng Anh.
        
        QUAN TRỌNG: Trả về JSON array nằm trong khối mã ```json ... ```.
        
        Định dạng JSON:
        [
          {
            "name": "Tên món",
            "calories": 350,
            "protein": 25,
            "carbs": 40,
            "fat": 8,
            "servingSize": 1.0,
            "unit": "chén",
            "weightInGrams": 200,
            "ingredients": [{"name": "...", "amount": 100, "unit": "g", "protein": 10, "carbs": 20, "fat": 5}],
            "instructions": ["Bước 1...", "Bước 2..."]
          }
        ]
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
    
    private func executeGeminiRequest(version: String, model: String, apiKey: String, prompt: String) async throws -> String {
        let url = URL(string: "https://generativelanguage.googleapis.com/\(version)/models/\(model):generateContent?key=\(apiKey)")!
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
    }
    
    // MARK: - Gemini Streaming Implementation
    private func callGeminiChatStream(apiKey: String, history: [ChatMessageModel], systemPrompt: String, config: AIModelConfig) -> AsyncThrowingStream<AIChatStreamResult, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                // Gemini streaming uses streamGenerateContent endpoint
                let url = URL(string: "https://generativelanguage.googleapis.com/\(config.endpoint)/models/\(config.modelName):streamGenerateContent?key=\(cleanKey)")!
                
                var contents: [[String: Any]] = []
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
                if isFirstUser { contents.append(["role": "user", "parts": [["text": systemPrompt]]]) }

                let requestBody: [String: Any] = [
                    "contents": contents,
                    "generationConfig": ["temperature": 0.7]
                ]
                
                do {
                    let (bytes, response) = try await self.performStreamRequest(url: url, body: requestBody)
                    var fullText = ""
                    
                    // Gemini stream is a JSON array of objects
                    // However, the bytes come in as a stream of JSON blocks.
                    // The standard Gemini stream response is a JSON array that grows.
                    // For simplicity, we use a custom parser or handle chunks.
                    
                    // Actually, streamGenerateContent returns a JSON array: [ {...}, {...} ]
                    // We need to parse each element as it arrives.
                    
                    var buffer = Data()
                    var isInsideJSON = false
                    
                    for try await byte in bytes {
                        buffer.append(byte)
                        
                        if let str = String(data: buffer, encoding: .utf8) {
                            if str.contains("{") && str.contains("}") {
                                if let start = str.range(of: "{")?.lowerBound,
                                   let end = str.range(of: "}", options: .backwards)?.upperBound {
                                    let jsonStr = String(str[start..<end])
                                    
                                    if let jsonData = jsonStr.data(using: .utf8),
                                       let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                                       let candidates = json["candidates"] as? [[String: Any]],
                                       let first = candidates.first,
                                       let content = first["content"] as? [String: Any],
                                       let parts = content["parts"] as? [[String: Any]],
                                       let text = parts.first?["text"] as? String {
                                        
                                        fullText += text
                                        
                                        // Detect if we've hit a JSON block
                                        if !isInsideJSON {
                                            if fullText.contains("```json") || fullText.contains("json {") || (fullText.contains("{") && fullText.contains("\"action\"")) {
                                                isInsideJSON = true
                                            }
                                        }
                                        
                                        // Only yield chunks if we're not in the middle of a JSON block
                                        if !isInsideJSON {
                                            continuation.yield(.chunk(text))
                                        }
                                        
                                        buffer = Data(str[end...].data(using: .utf8) ?? Data())
                                    }
                                }
                            }
                        }
                    }
                    
                    // Extract suggestions and clean text at the end
                    let finalMessage = parseChatResponse(fullText)
                    if let suggestions = finalMessage.suggestedFoods {
                        continuation.yield(.suggestions(suggestions))
                    }
                    // Always yield cleaned text to ensure UI reflects final cleaned text (and doesn't stay frozen/truncated)
                    continuation.yield(.finalCleanText(finalMessage.text))
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - OpenAI Streaming Implementation
    private func callOpenAIChatStream(apiKey: String, history: [ChatMessageModel], systemPrompt: String, config: AIModelConfig) -> AsyncThrowingStream<AIChatStreamResult, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                let url = URL(string: "https://api.openai.com/v1/chat/completions")!
                
                var messages: [[String: Any]] = [["role": "system", "content": systemPrompt]]
                for msg in history { messages.append(["role": msg.role.rawValue, "content": msg.text]) }
                
                let requestBody: [String: Any] = [
                    "model": config.modelName,
                    "messages": messages,
                    "temperature": 0.7,
                    "stream": true
                ]
                
                do {
                    let (bytes, response) = try await self.performStreamRequest(url: url, body: requestBody, extraHeaders: ["Authorization": "Bearer \(cleanKey)"])
                    var fullText = ""
                    var isInsideJSON = false
                    
                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let dataStr = line.replacingOccurrences(of: "data: ", with: "")
                            if dataStr == "[DONE]" { break }
                            
                            if let data = dataStr.data(using: .utf8),
                               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                               let choices = json["choices"] as? [[String: Any]],
                               let first = choices.first,
                               let delta = first["delta"] as? [String: Any],
                               let content = delta["content"] as? String {
                                
                                fullText += content
                                
                                // Detect if we've hit a JSON block
                                if !isInsideJSON {
                                    if fullText.contains("```json") || fullText.contains("json {") || (fullText.contains("{") && fullText.contains("\"action\"")) {
                                        isInsideJSON = true
                                    }
                                }
                                
                                // Only yield chunks if we're not in the middle of a JSON block
                                if !isInsideJSON {
                                    continuation.yield(.chunk(content))
                                }
                            }
                        }
                    }
                    
                    // Extract suggestions and clean text at the end
                    let finalMessage = parseChatResponse(fullText)
                    if let suggestions = finalMessage.suggestedFoods {
                        continuation.yield(.suggestions(suggestions))
                    }
                    // Always yield cleaned text to ensure UI reflects final cleaned text (and doesn't stay frozen/truncated)
                    continuation.yield(.finalCleanText(finalMessage.text))
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    private func performStreamRequest(url: URL, body: [String: Any], extraHeaders: [String: String] = [:]) async throws -> (URLSession.AsyncBytes, URLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        for (key, value) in extraHeaders { request.setValue(value, forHTTPHeaderField: key) }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 90
        
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.networkError("Không nhận được HTTP response")
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            // Read error body from stream if possible, but for simplicity we throw generic error
            if httpResponse.statusCode == 429 { throw AIError.quotaExceeded }
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 { throw AIError.invalidKey }
            throw AIError.networkError("HTTP \(httpResponse.statusCode)")
        }
        
        return (bytes, response)
    }

    private func parseChatResponse(_ text: String) -> ChatMessageModel {
        // Strategy 1: Look for ```json ... ``` markdown code blocks
        let pattern = "```json(.*?)```"
        let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
        let nsString = text as NSString
        let results = regex?.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        var cleanText = text
        var foods: [AISuggestedFood]? = nil
        
        if let match = results?.last { // Find the last JSON block
            let jsonString = nsString.substring(with: match.range(at: 1))
            foods = tryParseActionJSON(jsonString)
            
            // ALWAYS strip the JSON block from display, regardless of parsing success!
            cleanText = nsString.replacingCharacters(in: match.range, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Strategy 2: Fallback — AI returned raw JSON without markdown code block
        // Look for { "action": "suggest_meal" ... } or json { ... } patterns
        if foods == nil {
            let rawPatterns = [
                "(?:json\\s*)?\\{\\s*\"action\"\\s*:\\s*\"(?:suggest_meal|meal_plan)\".*?\\}\\s*\\]\\s*\\}",  // json { "action":... } with items array
                "\\{\\s*\"action\"\\s*:\\s*\"(?:suggest_meal|meal_plan)\"[^}]*\"items\"\\s*:\\s*\\[.*?\\]\\s*\\}"  // { "action":..., "items":[...] }
            ]
            
            for rawPattern in rawPatterns {
                if let rawRegex = try? NSRegularExpression(pattern: rawPattern, options: [.dotMatchesLineSeparators]),
                   let rawMatch = rawRegex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: nsString.length)) {
                    var rawJSON = nsString.substring(with: rawMatch.range)
                    // Strip leading "json " prefix if present
                    if rawJSON.hasPrefix("json") {
                        rawJSON = String(rawJSON.dropFirst(4)).trimmingCharacters(in: .whitespaces)
                    }
                    foods = tryParseActionJSON(rawJSON)
                    
                    // ALWAYS strip detected raw JSON from UI to maintain visual cleaniness!
                    cleanText = nsString.replacingCharacters(in: rawMatch.range, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    break
                }
            }
        }
        
        // Strategy 3: Emergency Fallback — Strip any remaining/unclosed JSON blocks (e.g. truncated by token limit)
        if cleanText.contains("```json") {
            if let jsonRange = cleanText.range(of: "```json") {
                cleanText = String(cleanText[..<jsonRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        if cleanText.contains("json {") {
            if let jsonRange = cleanText.range(of: "json {") {
                cleanText = String(cleanText[..<jsonRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // Final cleanup: Collapse redundant newlines (3 or more -> 2)
        // This prevents large gaps where JSON blocks were stripped out
        let newlineRegex = try? NSRegularExpression(pattern: "\n{3,}", options: [])
        cleanText = newlineRegex?.stringByReplacingMatches(in: cleanText, options: [], range: NSRange(location: 0, length: (cleanText as NSString).length), withTemplate: "\n\n") ?? cleanText
        
        return ChatMessageModel(role: .assistant, text: cleanText.trimmingCharacters(in: .whitespacesAndNewlines), suggestedFoods: foods)
    }
    
    /// Shared JSON parsing for both code-block and raw JSON strategies
    private func tryParseActionJSON(_ jsonString: String) -> [AISuggestedFood]? {
        struct ActionWrapper: Codable {
            let action: String
            let items: [AISuggestedFood]?
        }
        
        guard let data = jsonString.data(using: .utf8) else { return nil }
        
        // Try ActionWrapper first (for Chat/Special actions)
        if let wrapper = try? JSONDecoder().decode(ActionWrapper.self, from: data) {
            if wrapper.action == "suggest_meal" || wrapper.action == "meal_plan" {
                return wrapper.items
            }
        }
        // Fallback 1: Try plain array (for batched plans)
        if let plainItems = try? JSONDecoder().decode([AISuggestedFood].self, from: data) {
            return plainItems
        }
        
        // Fallback 2: Try single object (for enrichment results)
        do {
            let singleItem = try JSONDecoder().decode(AISuggestedFood.self, from: data)
            return [singleItem]
        } catch {
            print("❌ AISuggestedFood Decoding Error: \(error)")
            return nil
        }
    }
}
