import Foundation

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
    
    func buildSystemPrompt(for userMessage: String) async throws -> String {
        let user = try await userRepository.fetchUser()
        let memory = memoryManager.fetchMemory()
        
        let targetCalories = user?.dailyCalorieTarget ?? 2000
        let goalType = user?.goalType ?? "Duy trì cân nặng"
        
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
        if !memory.dislikes.isEmpty || !memory.preferences.isEmpty || !memory.notes.isEmpty {
            prompt += "\n\n[Ghi nhớ về Người dùng]\n"
            if !memory.preferences.isEmpty {
                prompt += "- Thích: \(memory.preferences.joined(separator: ", "))\n"
            }
            if !memory.dislikes.isEmpty {
                prompt += "- Không thích: \(memory.dislikes.joined(separator: ", "))\n"
            }
            if !memory.notes.isEmpty {
                prompt += "- Lưu ý: \(memory.notes.joined(separator: ", "))\n"
            }
        }
        
        // Intent-based Context Injection (Hybrid Approach)
        let lowerMsg = userMessage.lowercased()
        let needsHistory = lowerMsg.contains("dạo này") || lowerMsg.contains("gần đây") || lowerMsg.contains("tuần qua") || lowerMsg.contains("giảm cân") || lowerMsg.contains("tiến độ")
        
        if needsHistory {
            prompt += "\n\n[Dữ liệu 7 ngày gần nhất]\n"
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate) ?? endDate
            
            let meals = try await mealRepository.fetchMeals(from: startDate, to: endDate)
            
            if meals.isEmpty {
                prompt += "- Chưa có dữ liệu ăn uống trong 7 ngày qua.\n"
            } else {
                // Group by day
                let grouped = Dictionary(grouping: meals) { meal in
                    dateFormatter.string(from: meal.date)
                }
                
                for (date, dayMeals) in grouped.sorted(by: { $0.key < $1.key }) {
                    let totalCals = dayMeals.reduce(0) { $0 + $1.totalCalories }
                    prompt += "- \(date): \(Int(totalCals)) kcal\n"
                }
            }
        }
        
        prompt += """
        
        [Quy tắc Phản hồi]
        1. Trả lời ngắn gọn, thân thiện, dùng ngôn ngữ tự nhiên.
        2. Nếu người dùng nói vừa ăn gì đó, hoặc muốn gợi ý món ăn, bạn BẮT BUỘC phải kèm theo khối JSON ```json ... ```.
        3. Phân tích ngữ cảnh để set `isEaten`:
           - "Tôi vừa ăn..." -> `isEaten: true`
           - "Gợi ý cho tôi...", "Nên ăn gì..." -> `isEaten: false`
        4. Xác định `mealType` (Bữa sáng, Bữa trưa, Bữa tối, Ăn vặt). Nếu không rõ, hãy hỏi người dùng trước khi gợi ý hoặc chọn buổi gần nhất theo giờ hiện tại (Bây giờ là \(dateFormatterTime.string(from: Date()))).
        
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
        
        return prompt
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
