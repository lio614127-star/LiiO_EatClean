import Foundation

// MARK: - Context Strategy
enum ContextStrategy {
    case chat                    // Goal + basic memory (existing behavior for AI Coach tab)
    case mealSuggestion          // Remaining cals + meal type + prefs + health conditions + avoid rules
    case healthAdvice            // Full health conditions + dietary notes + detailed explanations
    case progressAnalysis        // 7-day history + weight trend + goal progress
    case dailySummary            // End of day summary with insights
    case mealPlan                // Full-day meal plan (4 meals) with adaptive context
}

// MARK: - Context Builder (Strategy Pattern)
class ContextBuilder {
    private let userRepository: UserRepositoryProtocol
    private let mealRepository: MealRepositoryProtocol
    private let memoryManager: MemoryManagerProtocol
    
    init(userRepository: UserRepositoryProtocol = UserRepository(),
         mealRepository: MealRepositoryProtocol = MealRepository(),
         memoryManager: MemoryManagerProtocol = MemoryManager.shared) {
        self.userRepository = userRepository
        self.mealRepository = mealRepository
        self.memoryManager = memoryManager
    }
    
    // MARK: - Main Entry Point (Strategy-based)
    
    func buildSystemPrompt(
        for userMessage: String,
        strategy: ContextStrategy = .chat,
        remainingCalories: Double? = nil,
        mealType: String? = nil
    ) async throws -> String {
        let user = try await userRepository.fetchUser()
        let memory = memoryManager.fetchMemory()
        
        let targetCalories = user?.dailyCalorieTarget ?? 2000
        let goalType = user?.goalType ?? "Duy trì cân nặng"
        let effectiveRemaining = remainingCalories ?? targetCalories
        
        switch strategy {
        case .chat:
            return try await buildChatContext(
                userMessage: userMessage,
                goalType: goalType,
                targetCalories: targetCalories,
                memory: memory
            )
        case .mealSuggestion:
            return buildMealSuggestionContext(
                remainingCalories: effectiveRemaining,
                mealType: mealType ?? autoDetectMealType(),
                goalType: goalType,
                memory: memory
            )
        case .healthAdvice:
            return buildHealthAdviceContext(
                goalType: goalType,
                targetCalories: targetCalories,
                memory: memory
            )
        case .progressAnalysis:
            return try await buildProgressContext(
                goalType: goalType,
                targetCalories: targetCalories,
                memory: memory
            )
        case .dailySummary:
            // Will need daily data passed in, but we can structure the prompt here
            return buildDailySummaryContext(
                goalType: goalType,
                targetCalories: targetCalories,
                memory: memory
            )
        case .mealPlan:
            return try await buildMealPlanContext(
                targetCalories: effectiveRemaining,
                memory: memory
            )
        }
    }
    
    // MARK: - Strategy: Chat (existing behavior, backward compatible)
    
    private func buildChatContext(
        userMessage: String,
        goalType: String,
        targetCalories: Double,
        memory: UserProfileMemory
    ) async throws -> String {
        var prompt = """
        Bạn là chuyên gia dinh dưỡng cá nhân thân thiện, tận tâm trong ứng dụng LiiO EatClean.
        Mục tiêu của bạn là đồng hành, động viên người dùng (như Apple Health: supportive, không phán xét).
        
        [Ngữ cảnh Ứng dụng]
        - Chức năng app: Track calories, track nước, theo dõi cân nặng.
        - Khả năng của bạn: Trả lời câu hỏi dinh dưỡng, đưa ra lời khuyên, gợi ý món ăn, và có thể LOG món ăn trực tiếp cho người dùng.
        
        [Thông tin Người dùng]
        - Mục tiêu: \(goalType)
        - Target Calories/ngày: \(Int(targetCalories)) kcal
        """
        
        // Add Memory Context
        prompt += buildMemoryBlock(memory)
        
        // Intent-based Context Injection (Hybrid Approach)
        let lowerMsg = userMessage.lowercased()
        let needsHistory = lowerMsg.contains("dạo này") || lowerMsg.contains("gần đây") || lowerMsg.contains("tuần qua") || lowerMsg.contains("giảm cân") || lowerMsg.contains("tiến độ")
        
        if needsHistory {
            prompt += try await build7DayBlock()
        }
        
        prompt += buildResponseRules()
        
        return prompt
    }
    
    // MARK: - Strategy: Meal Suggestion (PRIORITY: avoid → calories → preferences)
    
    private func buildMealSuggestionContext(
        remainingCalories: Double,
        mealType: String,
        goalType: String,
        memory: UserProfileMemory
    ) -> String {
        var prompt = """
        Bạn là chuyên gia dinh dưỡng chuyên về ẩm thực Việt Nam trong ứng dụng LiiO EatClean.
        Gợi ý 2 món ăn phù hợp cho \(mealType).
        
        [Thông tin Người dùng]
        - Mục tiêu: \(goalType)
        - Calories còn lại hôm nay: \(Int(remainingCalories)) kcal
        """
        
        // PRIORITY 1: Avoid foods (CRITICAL — health safety)
        let allAvoid = memory.allAvoidFoods
        if !allAvoid.isEmpty {
            prompt += "\n\n[⛔ CẤM — KHÔNG ĐƯỢC gợi ý các món sau]\n"
            for condition in memory.healthConditions where !condition.avoidFoods.isEmpty {
                prompt += "- Bệnh \(condition.name): tránh \(condition.avoidFoods.joined(separator: ", "))\n"
            }
        }
        
        // PRIORITY 2: Calorie constraint
        prompt += "\n\n[Giới hạn Calories]\n"
        prompt += "- Tổng 2 món KHÔNG ĐƯỢC vượt quá \(Int(remainingCalories)) kcal\n"
        prompt += "- Mỗi món phải tính đúng calories cho 1 phần ăn\n"
        
        // PRIORITY 3: Preferences
        if !memory.likes.isEmpty || !memory.dislikes.isEmpty {
            prompt += "\n\n[Sở thích]\n"
            if !memory.likes.isEmpty {
                prompt += "- Thích: \(memory.likes.joined(separator: ", ")) (ưu tiên gợi ý)\n"
            }
            if !memory.dislikes.isEmpty {
                prompt += "- Không thích: \(memory.dislikes.joined(separator: ", ")) (tránh gợi ý)\n"
            }
        }
        
        // Health condition dietary notes
        for condition in memory.healthConditions where !condition.dietaryNotes.isEmpty {
            prompt += "\n- Lưu ý (\(condition.name)): \(condition.dietaryNotes)\n"
        }
        
        prompt += """
        
        QUAN TRỌNG: Trả về kết quả trong một Markdown code block chuẩn ` ```json ... ``` `. Không giải thích thêm.
        
        Định dạng JSON:
        ```json
        {
          "action": "suggest_meal",
          "items": [
            {"name":"Tên món","calories":350,"protein":25,"carbs":40,"fat":8,"servingSize":1.0,"mealType":"\(mealType)"}
          ]
        }
        ```
        
        Lưu ý: "servingSize" luôn là 1.0. Calo và macros tính cho đúng 1 phần ăn.
        """
        
        return prompt
    
    // MARK: - Strategy: Meal Plan (Full Day — Adaptive Context)
    
    private func buildMealPlanContext(
        targetCalories: Double,
        memory: UserProfileMemory
    ) async throws -> String {
        var prompt = """
        Bạn là chuyên gia dinh dưỡng chuyên về ẩm thực Việt Nam.
        Hãy lên thực đơn 1 ngày gồm 4 bữa với tổng khoảng \(Int(targetCalories)) kcal.
        
        Phân bổ gợi ý:
        - Bữa sáng: ~\(Int(targetCalories * 0.25)) kcal (25%)
        - Bữa trưa: ~\(Int(targetCalories * 0.35)) kcal (35%)
        - Bữa tối: ~\(Int(targetCalories * 0.30)) kcal (30%)
        - Ăn vặt: ~\(Int(targetCalories * 0.10)) kcal (10%)
        
        """
        
        // Base context: Memory injection (always if available)
        if memory.hasContent {
            let allAvoid = memory.allAvoidFoods
            if !allAvoid.isEmpty {
                prompt += "\n⛔ CẤM — KHÔNG ĐƯỢC gợi ý: \(allAvoid.joined(separator: ", "))"
            }
            if !memory.dislikes.isEmpty {
                prompt += "\nKhông thích: \(memory.dislikes.joined(separator: ", "))"
            }
            if !memory.likes.isEmpty {
                prompt += "\nƯa thích: \(memory.likes.joined(separator: ", "))"
            }
            if !memory.healthConditions.isEmpty {
                let conditions = memory.healthConditions.map { "\($0.name): \($0.dietaryNotes)" }.joined(separator: "; ")
                prompt += "\nTình trạng sức khoẻ: \(conditions)"
            }
        }
        
        // Conditional: History (only if ≥3 days of data — tránh lặp món)
        let calendar = Calendar.current
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        let recentMeals = try await mealRepository.fetchMeals(from: threeDaysAgo, to: Date())
        
        if recentMeals.count >= 3 {
            let recentFoodNames = Array(Set(recentMeals.flatMap { $0.mealFoods }.compactMap { $0.foodItem?.name })).prefix(5)
            if !recentFoodNames.isEmpty {
                prompt += "\n\nMón đã ăn gần đây (tránh lặp): \(recentFoodNames.joined(separator: ", "))"
            }
        }
        
        // Conditional: Insights (only if patterns detected)
        let insightDetector = InsightDetector()
        let insights = await insightDetector.detectInsights()
        if !insights.isEmpty {
            let insightTexts = insights.prefix(2).map { "- \($0.message)" }.joined(separator: "\n")
            prompt += "\n\nNhận xét dinh dưỡng gần đây:\n\(insightTexts)\nHãy điều chỉnh thực đơn để khắc phục các vấn đề trên."
        }
        
        // Output format
        prompt += """
        
        
        QUAN TRỌNG: Trả về kết quả trong một Markdown code block chuẩn ` ```json ... ``` `. Không giải thích thêm.
        
        Định dạng JSON:
        ```json
        {
          "action": "meal_plan",
          "items": [
            {"name":"Tên món","calories":400,"protein":25,"carbs":50,"fat":10,"servingSize":1.0,"mealType":"Bữa sáng"}
          ]
        }
        ```
        
        Mỗi item PHẢI có mealType là 1 trong: "Bữa sáng", "Bữa trưa", "Bữa tối", "Ăn vặt".
        Mỗi bữa nên có 2-3 món. servingSize luôn = 1.0. Calo và macros tính cho đúng 1 phần ăn.
        """
        
        return prompt
    }
    
    // MARK: - Strategy: Health Advice
    
    private func buildHealthAdviceContext(
        goalType: String,
        targetCalories: Double,
        memory: UserProfileMemory
    ) -> String {
        var prompt = """
        Bạn là chuyên gia dinh dưỡng thân thiện. Không phải bác sĩ — không đưa chẩn đoán y khoa.
        Người dùng hỏi về sức khỏe liên quan đến dinh dưỡng.
        
        [Thông tin Người dùng]
        - Mục tiêu: \(goalType)
        - Target Calories/ngày: \(Int(targetCalories)) kcal
        """
        
        // Full health conditions with detail
        if !memory.healthConditions.isEmpty {
            prompt += "\n\n[Bệnh lý & Kiêng cữ — CHI TIẾT]\n"
            for condition in memory.healthConditions {
                prompt += "- \(condition.name):\n"
                if !condition.avoidFoods.isEmpty {
                    prompt += "  Tránh: \(condition.avoidFoods.joined(separator: ", "))\n"
                }
                if !condition.dietaryNotes.isEmpty {
                    prompt += "  Lưu ý: \(condition.dietaryNotes)\n"
                }
            }
        }
        
        // General dietary notes
        if !memory.dietaryNotes.isEmpty {
            prompt += "\n\n[Ghi chú dinh dưỡng]\n"
            for note in memory.dietaryNotes {
                prompt += "- \(note)\n"
            }
        }
        
        prompt += buildMemoryBlock(memory)
        
        prompt += """
        
        [Quy tắc]
        1. Trả lời chi tiết, rõ ràng về dinh dưỡng.
        2. Không chẩn đoán bệnh — chỉ tư vấn ăn uống.
        3. Luôn khuyên "tham khảo ý kiến bác sĩ" khi cần.
        """
        
        return prompt
    }
    
    // MARK: - Strategy: Progress Analysis
    
    private func buildProgressContext(
        goalType: String,
        targetCalories: Double,
        memory: UserProfileMemory
    ) async throws -> String {
        var prompt = """
        Bạn là chuyên gia dinh dưỡng phân tích tiến trình người dùng.
        
        [Thông tin Người dùng]
        - Mục tiêu: \(goalType)
        - Target Calories/ngày: \(Int(targetCalories)) kcal
        """
        
        // Always inject 7-day data for progress analysis
        prompt += try await build7DayBlock()
        prompt += buildMemoryBlock(memory)
        
        prompt += """
        
        [Quy tắc]
        1. Phân tích xu hướng calories 7 ngày qua.
        2. Nhận xét tích cực, động viên.
        3. Đề xuất cụ thể nếu cần điều chỉnh.
        """
        
        return prompt
    }
    
    // MARK: - Strategy: Daily Summary
    
    private func buildDailySummaryContext(
        goalType: String,
        targetCalories: Double,
        memory: UserProfileMemory
    ) -> String {
        var prompt = """
        Bạn là chuyên gia dinh dưỡng cá nhân. Nhiệm vụ của bạn là tổng kết ngày hôm nay của người dùng.
        
        [Quy tắc Phản hồi]
        1. Đọc dữ liệu được cung cấp (calories, macros, insights).
        2. Viết NHẬN XÉT: 2-3 câu ngắn gọn, thân thiện. Nếu đạt mục tiêu calories thì tích cực/khen ngợi. Nếu không đạt thì nhẹ nhàng, không phán xét.
        3. Viết GỢI Ý: 1 câu hành động cụ thể cho ngày mai dựa trên insights hoặc sự thiếu hụt macro.
        4. CHỈ trả về JSON chuẩn, không giải thích thêm.
        
        Định dạng JSON:
        ```json
        {
          "comment": "Nhận xét tổng quan của bạn...",
          "suggestion": "Gợi ý cụ thể cho ngày mai..."
        }
        ```
        """
        
        prompt += buildMemoryBlock(memory)
        
        return prompt
    }
    
    // MARK: - Shared Building Blocks
    
    private func buildMemoryBlock(_ memory: UserProfileMemory) -> String {
        guard memory.hasContent else { return "" }
        
        var block = "\n\n[Ghi nhớ về Người dùng]\n"
        if !memory.likes.isEmpty {
            block += "- Thích: \(memory.likes.joined(separator: ", "))\n"
        }
        if !memory.dislikes.isEmpty {
            block += "- Không thích: \(memory.dislikes.joined(separator: ", "))\n"
        }
        if !memory.healthConditions.isEmpty {
            block += "- Bệnh lý: \(memory.healthConditions.map(\.name).joined(separator: ", "))\n"
        }
        if !memory.dietaryNotes.isEmpty {
            block += "- Lưu ý: \(memory.dietaryNotes.joined(separator: ", "))\n"
        }
        return block
    }
    
    private func build7DayBlock() async throws -> String {
        var block = "\n\n[Dữ liệu 7 ngày gần nhất]\n"
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        
        let meals = try await mealRepository.fetchMeals(from: startDate, to: endDate)
        
        if meals.isEmpty {
            block += "- Chưa có dữ liệu ăn uống trong 7 ngày qua.\n"
        } else {
            let grouped = Dictionary(grouping: meals) { meal in
                dateFormatter.string(from: meal.date)
            }
            
            for (date, dayMeals) in grouped.sorted(by: { $0.key < $1.key }) {
                let totalCals = dayMeals.reduce(0) { $0 + $1.totalCalories }
                block += "- \(date): \(Int(totalCals)) kcal\n"
            }
        }
        return block
    }
    
    private func buildResponseRules() -> String {
        """
        
        [Quy tắc Phản hồi]
        1. Trả lời ngắn gọn, thân thiện, dùng ngôn ngữ tự nhiên.
        2. Nếu người dùng nói vừa ăn gì đó, hoặc muốn gợi ý món ăn, bạn BẮT BUỘC phải kèm theo khối JSON ```json ... ```.
        3. Phân tích ngữ cảnh để set `isEaten`:
           - "Tôi vừa ăn..." -> `isEaten: true`
           - "Gợi ý cho tôi...", "Nên ăn gì..." -> `isEaten: false`
        4. Xác định `mealType` (Bữa sáng, Bữa trưa, Bữa tối, Ăn vặt). Nếu không rõ, chọn buổi gần nhất theo giờ hiện tại (Bây giờ là \(dateFormatterTime.string(from: Date()))).
        
        Định dạng JSON chuẩn:
        ```json
        {
          "action": "suggest_meal",
          "items": [
            { 
              "name": "Tên món", 
              "calories": 350, 
              "protein": 25, 
              "carbs": 40, 
              "fat": 8, 
              "servingSize": 1,
              "mealType": "Bữa trưa",
              "isEaten": false
            }
          ]
        }
        ```
        """
    }
    
    // MARK: - Helpers
    
    func autoDetectMealType() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<10: return "Bữa sáng"
        case 10..<14: return "Bữa trưa"
        case 14..<17: return "Ăn vặt"
        case 17..<21: return "Bữa tối"
        default: return "Ăn vặt"
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        return formatter
    }

    private var dateFormatterTime: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }
}
