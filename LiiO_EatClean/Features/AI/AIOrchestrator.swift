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
    func generateWeekPlanBatched(userContext: String) async throws -> [WeeklyDayPlan] {
        try await poolManager.loadKeys()
        let activeKeys = await poolManager.getKeys().filter { $0.isActive }
        if activeKeys.isEmpty { throw AIError.missingKey }
        
        let days = ["Thứ 2", "Thứ 3", "Thứ 4", "Thứ 5", "Thứ 6", "Thứ 7", "Chủ Nhật"]
        
        // Priority: PAID keys first for heavy reasoning (weekly plans)
        let keysToUse = activeKeys.sorted { (k1, k2) -> Bool in
            let p1 = k1.isPaid == true
            let p2 = k2.isPaid == true
            if p1 != p2 { return p1 } // Paid first
            return k1.healthScore > k2.healthScore
        }
        
        // Use as many keys as possible, capped only by number of tasks (7 days)
        let parallelCount = min(keysToUse.count, days.count)
        let taskGroups = splitWorkload(days, across: parallelCount)
        var allResults: [WeeklyDayPlan] = []
        
        try await withThrowingTaskGroup(of: [WeeklyDayPlan].self) { group in
            for (index, dayGroup) in taskGroups.enumerated() {
                let key = keysToUse[index]
                group.addTask {
                    return try await self.executeWeekBatch(days: dayGroup, key: key, userContext: userContext)
                }
            }
            
            for try await result in group {
                allResults.append(contentsOf: result)
            }
        }
        
        return allResults.sorted { d1, d2 in
            let order = ["Thứ 2": 0, "Thứ 3": 1, "Thứ 4": 2, "Thứ 5": 3, "Thứ 6": 4, "Thứ 7": 5, "Chủ Nhật": 6]
            return (order[d1.day] ?? 0) < (order[d2.day] ?? 0)
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
    
    private func executeWeekBatch(days: [String], key: APIKeyModel, userContext: String) async throws -> [WeeklyDayPlan] {
        let dayList = days.joined(separator: ", ")
        let systemPrompt = """
        Bạn là chuyên gia dinh dưỡng. Hãy lên kế hoạch ăn uống cho các ngày sau: \(dayList).
        
        Dữ liệu người dùng:
        \(userContext)
        
        YÊU CẦU:
        1. Mỗi ngày đề xuất đủ các bữa: Sáng, Trưa, Tối, Ăn vặt.
        2. Trả về JSON array phẳng chứa các đối tượng ngày.
        
        Định dạng JSON:
        [
          {
            "day": "Thứ 2",
            "breakfast": {"name": "...", "calories": 400, "protein": 20, "carbs": 50, "fat": 10, "servingSize": 1.0},
            "lunch": {"name": "...", "calories": 600, "protein": 30, "carbs": 70, "fat": 15, "servingSize": 1.0},
            "dinner": {"name": "...", "calories": 500, "protein": 25, "carbs": 60, "fat": 12, "servingSize": 1.0},
            "snack": {"name": "...", "calories": 200, "protein": 10, "carbs": 30, "fat": 5, "servingSize": 1.0}
          }
        ]
        """
        
        let response = try await aiService.generateText(
            prompt: systemPrompt,
            requestType: .weeklyPlan,
            feature: "Kế hoạch: Gom \(days.count) ngày",
            forcedKey: key,
            subTasks: days.map { "Lập kế hoạch: \($0)" },
            isInternal: true
        )
        
        let jsonStr = extractJSON(from: response)
        guard let data = jsonStr.data(using: .utf8) else { return [] }
        return try JSONDecoder().decode([WeeklyDayPlan].self, from: data)
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
