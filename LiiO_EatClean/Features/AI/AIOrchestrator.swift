import Foundation

struct AIOrchestrator {
    static let shared = AIOrchestrator()
    private let aiService = AIService.shared
    private let poolManager = APIKeyPoolManager.shared
    
    // MARK: - Distributed Orchestration Models
    struct MealAllocation: Codable {
        let mealType: String
        let calories: Int
        let protein: Int
        let carbs: Int
        let fat: Int
    }
    
    struct DayMasterPlan: Codable {
        let allocations: [MealAllocation]
        let totalCalories: Int
    }
    
    /// Streaming generate a day plan (Single-pass All-in-one)
    func generateDayPlanStreaming(
        targetCalories: Double,
        userContext: String,
        completedMealTypes: [String] = [],
        isInternal: Bool = false,
        onMeal: @escaping @Sendable (AISuggestedFood) -> Void
    ) async throws -> [AISuggestedFood] {
        try await poolManager.loadKeys()
        
        var allFoods: [AISuggestedFood] = []
        var currentJSONBuffer = ""
        var isInsideArray = false
        
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let stream = aiService.generateDayPlanStream(targetCalories: targetCalories, userContext: userContext, completedMealTypes: completedMealTypes, isInternal: isInternal)
                    
                    for try await result in stream {
                        switch result {
                        case .chunk(let text):
                            currentJSONBuffer += text
                            
                            // Detect and parse individual meal objects from the stream
                            let parsedMeals = extractCompleteMeals(from: &currentJSONBuffer, isInsideArray: &isInsideArray)
                            for meal in parsedMeals {
                                allFoods.append(meal)
                                onMeal(meal)
                            }
                            
                        case .suggestions(let foods):
                            // Final safety catch-all
                            let newFoods = foods.filter { newFood in !allFoods.contains(where: { $0.name == newFood.name }) }
                            for food in newFoods {
                                allFoods.append(food)
                                onMeal(food)
                            }
                            
                        case .error(let msg):
                            throw AIError.networkError(msg)
                            
                        default:
                            break
                        }
                    }
                    continuation.resume(returning: allFoods)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func extractCompleteMeals(from buffer: inout String, isInsideArray: inout Bool) -> [AISuggestedFood] {
        var results: [AISuggestedFood] = []
        
        // Find the start of the JSON array if not already inside
        if !isInsideArray {
            if let index = buffer.firstIndex(of: "[") {
                buffer.removeSubrange(...index)
                isInsideArray = true
            }
        }
        
        guard isInsideArray else { return [] }
        
        // Try to find a complete JSON object { ... }
        var searchRange = buffer.startIndex..<buffer.endIndex
        while let start = buffer.range(of: "{", range: searchRange)?.lowerBound {
            var braceCount = 0
            var end: String.Index? = nil
            
            for index in buffer.indices[start...] {
                if buffer[index] == "{" { braceCount += 1 }
                else if buffer[index] == "}" {
                    braceCount -= 1
                    if braceCount == 0 {
                        end = buffer.index(after: index)
                        break
                    }
                }
            }
            
            if let foundEnd = end {
                let jsonObject = String(buffer[start..<foundEnd])
                if let data = jsonObject.data(using: .utf8),
                   let food = try? JSONDecoder().decode(AISuggestedFood.self, from: data) {
                    results.append(food)
                }
                
                // Move search range forward
                searchRange = foundEnd..<buffer.endIndex
                
                // If this was the last object in the buffer, clear the processed part
                if foundEnd == buffer.endIndex {
                    buffer = ""
                    break
                }
            } else {
                // Incomplete object, keep it in buffer for next chunk
                buffer = String(buffer[start...])
                break
            }
        }
        
        return results
    }

    /// Batch generate a day plan (Breakfast, Lunch, Dinner, Snack)
    func generateDayPlanBatched(
        mealTypes: [String], 
        userContext: String, 
        targetCalories: Double,
        onProgress: @escaping @Sendable ([AISuggestedFood]) -> Void = { _ in }
    ) async throws -> [AISuggestedFood] {
        try await poolManager.loadKeys()
        let activeKeys = await poolManager.getKeys().filter { $0.isActive }
        if activeKeys.isEmpty { throw AIError.missingKey }
        
        // Phase 1: Master Planning (Global Reasoning)
        // Use the best available key for the master plan
        let masterPlan = try await generateMasterPlan(targetCalories: targetCalories, mealTypes: mealTypes, userContext: userContext)
        
        // Phase 2: Dynamic Task Distribution
        let keysToUse = activeKeys.sorted { (k1, k2) -> Bool in
            let p1 = k1.isPaid == true
            let p2 = k2.isPaid == true
            if p1 != p2 { return !p1 } // Free first for workers
            return k1.healthScore > k2.healthScore
        }
        
        // Limit maximum parallel calls to 2 to minimize overhead and token duplication
        let parallelCount = min(keysToUse.count, 2)
        let taskGroups = splitWorkload(masterPlan.allocations, across: parallelCount)
        
        var allResults: [AISuggestedFood] = []
        
        try await withThrowingTaskGroup(of: [AISuggestedFood].self) { group in
            for (index, allocations) in taskGroups.enumerated() {
                let key = keysToUse[min(index, keysToUse.count - 1)]
                group.addTask {
                    return try await self.executeWorkerBatch(allocations: allocations, key: key, userContext: userContext)
                }
            }
            
            for try await result in group {
                allResults.append(contentsOf: result)
                onProgress(result) // ⚡ Streaming: Yield partial results immediately
            }
        }
        
        // Phase 3: Local Validation & Final Polish
        return allResults.sorted { m1, m2 in
            let order = ["Bữa sáng": 0, "Bữa trưa": 1, "Bữa tối": 2, "Ăn vặt": 3]
            let o1 = order[m1.mealType ?? ""] ?? 99
            let o2 = order[m2.mealType ?? ""] ?? 99
            return o1 < o2
        }
    }
    
    /// Batch generate a weekly plan (7 days)
    func generateWeekPlanBatched(userContext: String, dates: [Date]) async throws -> [WeeklyDayPlan] {
        try await poolManager.loadKeys()
        let activeKeys = await poolManager.getKeys().filter { $0.isActive }
        if activeKeys.isEmpty { throw AIError.missingKey }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        
        let dayNames = dates.map { formatter.string(from: $0) }
        
        // Priority: PAID keys first for heavy reasoning (weekly plans)
        let keysToUse = activeKeys.sorted { (k1, k2) -> Bool in
            let p1 = k1.isPaid == true
            let p2 = k2.isPaid == true
            if p1 != p2 { return p1 } // Paid first
            return k1.healthScore > k2.healthScore
        }
        
        // Use as many keys as possible, capped only by number of tasks (7 days)
        let parallelCount = min(keysToUse.count, dates.count)
        let taskGroups = splitWorkload(dates, across: parallelCount)
        var allResults: [WeeklyDayPlan] = []
        
        try await withThrowingTaskGroup(of: [WeeklyDayPlan].self) { group in
            for (index, dateGroup) in taskGroups.enumerated() {
                let key = keysToUse[index]
                group.addTask {
                    return try await self.executeWeekBatch(dates: dateGroup, key: key, userContext: userContext)
                }
            }
            
            for try await result in group {
                allResults.append(contentsOf: result)
            }
        }
        
        return allResults.sorted { d1, d2 in
            guard let date1 = d1.date, let date2 = d2.date else { return false }
            return date1 < date2
        }
    }
    
    private func splitWorkload<T>(_ items: [T], across count: Int) -> [[T]] {
        let actualCount = min(max(1, count), items.count)
        var result = [[T]](repeating: [], count: actualCount)
        
        // Sequential chunking (e.g., Breakfast+Lunch, Dinner+Snack)
        let chunkSize = Int(ceil(Double(items.count) / Double(actualCount)))
        
        for (index, item) in items.enumerated() {
            let groupIndex = min(index / chunkSize, actualCount - 1)
            result[groupIndex].append(item)
        }
        return result
    }
    
    private func generateMasterPlan(targetCalories: Double, mealTypes: [String], userContext: String) async throws -> DayMasterPlan {
        let prompt = """
        Bạn là Master Planner của hệ thống AI dinh dưỡng. 
        Nhiệm vụ: Chia ngân sách calo và macro cho từng bữa ăn.
        
        Mục tiêu tổng: ~\(Int(targetCalories)) kcal.
        Dung sai cho phép (TOLERANCE): ±100 kcal (khoảng \(Int(targetCalories - 100))-\(Int(targetCalories + 100)) kcal).
        Các bữa cần chia: \(mealTypes.joined(separator: ", ")).
        
        YÊU CẦU:
        1. Phân bổ calo cho các bữa sao cho TỔNG NẰM TRONG KHOẢNG dung sai trên. KHÔNG cần chính xác tuyệt đối.
        2. Macro balance: Protein 25-30%, Carbs 45-50%, Fat 20-25%.
        3. REALISTIC MEALS: Ưu tiên phân bổ để bữa ăn thực tế, dễ nấu hơn là ép từng số lẻ.
        
        PHẢI TRẢ VỀ JSON TRONG KHỐI MÃ ```json ... ```:
        {
          "allocations": [
            {"mealType": "Bữa sáng", "calories": 450, "protein": 30, "carbs": 50, "fat": 15},
            ...
          ],
          "totalCalories": \(Int(targetCalories))
        }
        """
        
        let response = try await aiService.generateText(
            prompt: prompt,
            requestType: .healthReasoning,
            feature: "Master Planner: Phân bổ ngân sách",
            isInternal: true
        )
        
        let jsonStr = extractJSON(from: response)
        guard let data = jsonStr.data(using: .utf8) else { throw AIError.invalidResponse }
        return try JSONDecoder().decode(DayMasterPlan.self, from: data)
    }
    
    private func executeWorkerBatch(allocations: [MealAllocation], key: APIKeyModel, userContext: String) async throws -> [AISuggestedFood] {
        let mealNames = allocations.map { $0.mealType }.joined(separator: " và ")
        let allocationsText = allocations.map { 
            "- \($0.mealType): \($0.calories) kcal (Protein: \($0.protein)g, Carbs: \($0.carbs)g, Fat: \($0.fat)g)" 
        }.joined(separator: "\n")
        
        // Context Compression (Simulate Cache ID logic for prompt brevity)
        let compressedContext = """
        [CACHED CONTEXT ID: LIIO-GLOBAL-PLANNER-ALLOCATED]
        Bỏ qua các bước tính toán phức tạp. Tập trung tạo món ăn theo ngân sách cứng.
        
        \(userContext)
        """
        
        let prompt = """
        Bạn là Worker Agent. Nhiệm vụ: Tạo món ăn Việt Nam cho: \(mealNames).
        
        NGÂN SÁCH MỤC TIÊU TỪNG BỮA (SOFT CONSTRAINTS):
        \(allocationsText)
        
        Dữ liệu người dùng (HARD CONSTRAINTS - PHẢI TUÂN THỦ):
        \(compressedContext)
        
        YÊU CẦU:
        1. Mỗi bữa ăn đề xuất 1 món chính (có thể kèm món phụ). Tổng calo xoay quanh ngân sách trên.
        2. ƯU TIÊN SỐ 1: Khẩu phần thực tế, tự nhiên của người Việt (VD: 1 chén cơm, 1 tô phở). KHÔNG ép phần ăn ra số lẻ (VD: 0.83 chén) chỉ để khớp calo!
        3. ƯU TIÊN SỐ 2: Dung sai calo ±10% là HOÀN TOÀN CHẤP NHẬN ĐƯỢC. Realistic meals > Exact calories.
        4. PHẢI trả về JSON array phẳng (không lồng nhau) nằm trong khối mã ```json ... ```.
        
        Định dạng mẫu:
        ```json
        [
          {"name": "...", "calories": ..., "protein": ..., "carbs": ..., "fat": ..., "servingSize": 1.0, "mealType": "\(allocations.first?.mealType ?? "Bữa sáng")"},
          {"name": "...", "calories": ..., "protein": ..., "carbs": ..., "fat": ..., "servingSize": 1.0, "mealType": "\(allocations.last?.mealType ?? "Bữa tối")"}
        ]
        ```
        """
        
        let chatMessage = try await aiService.sendChatMessage(
            history: [],
            systemPrompt: prompt,
            task: .mealPlanDay,
            feature: "Lập kế hoạch: \(mealNames)",
            forcedKey: key,
            isInternal: true
        )
        
        guard let foods = chatMessage.suggestedFoods else { return [] }
        return foods
    }
    
    private func executeWeekBatch(dates: [Date], key: APIKeyModel, userContext: String) async throws -> [WeeklyDayPlan] {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        let dayList = dates.map { formatter.string(from: $0) }.joined(separator: ", ")
        
        let systemPrompt = """
        Bạn là chuyên gia dinh dưỡng. Hãy lên kế hoạch ăn uống chi tiết cho các ngày cụ thể sau: \(dayList).
        
        Dữ liệu người dùng:
        \(userContext)
        
        YÊU CẦU QUAN TRỌNG:
        1. Mỗi ngày đề xuất đủ 4 bữa: Bữa sáng, Bữa trưa, Bữa tối, Ăn vặt.
        2. TỪNG MÓN ĂN PHẢI có đầy đủ:
           - "ingredients": Danh sách nguyên liệu chi tiết (tên, khối lượng g, đơn vị).
           - "instructions": Các bước nấu ăn ngắn gọn (array of strings).
           - Macro: calories, protein, carbs, fat.
        3. Phải đảm bảo thực đơn thực tế, phù hợp với người Việt Nam.
        4. TRẢ VỀ ĐÚNG NGÀY TRONG JSON: Trường "date" phải là chuỗi định dạng "dd/MM/yyyy" khớp với danh sách trên.
        
        Định dạng JSON:
        [
          {
            "day": "Thứ ...",
            "date": "14/05/2026",
            "breakfast": {
              "name": "...", 
              "calories": 400, "protein": 20, "carbs": 50, "fat": 10, "servingSize": 1.0,
              "unit": "tô", "weightInGrams": 450,
              "ingredients": [{"name": "...", "amount": 100, "unit": "g"}],
              "instructions": ["Bước 1...", "Bước 2..."]
            },
            "lunch": { ... },
            "dinner": { ... },
            "snack": { ... }
          }
        ]
        """
        
        let response = try await aiService.generateText(
            prompt: systemPrompt,
            requestType: .weeklyPlan,
            feature: "Kế hoạch: \(dates.count) ngày cụ thể",
            forcedKey: key,
            subTasks: dates.map { "Lập kế hoạch: \(formatter.string(from: $0))" },
            isInternal: true
        )
        
        let jsonStr = extractJSON(from: response)
        guard let data = jsonStr.data(using: .utf8) else { return [] }
        
        // Custom decoder to handle date string
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        return try decoder.decode([WeeklyDayPlan].self, from: data)
    }
    
    private func extractJSON(from text: String) -> String {
        var cleaned = text
        
        // Find the first occurrence of either [ or {
        let firstBracket = cleaned.firstIndex(where: { $0 == "[" || $0 == "{" })
        // Find the last occurrence of either ] or }
        let lastBracket = cleaned.lastIndex(where: { $0 == "]" || $0 == "}" })
        
        if let start = firstBracket, let end = lastBracket, start < end {
            cleaned = String(cleaned[start...end])
        }
        
        return cleaned
    }
}
