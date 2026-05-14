import Foundation

enum VoiceCommandIntent: String {
    case dailyPlanRequest
    case weeklyPlanRequest
    case mealLogging
    case rebalanceRequest
    case nutritionQuestion
    case cookingQuestion
    case progressQuestion
    case weatherQuestion
    case generalChat
}

struct VoiceCommandIntentRouter {
    static func route(transcript: String) -> VoiceCommandIntent {
        let lower = transcript.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. Daily Plan Requests
        let dailyKeywords = [
            "lên thực đơn hôm nay", "lập thực đơn hôm nay", "tạo thực đơn hôm nay",
            "lên kế hoạch ăn hôm nay", "hôm nay ăn gì", "lên plan hôm nay",
            "tạo plan ngày", "gợi ý thực đơn ngày", "lên thực đơn ngày",
            "lên thực đơn cho tôi", "lên kế hoạch ngày", "hãy lên thực đơn"
        ]
        for kw in dailyKeywords {
            if lower.contains(kw) { return .dailyPlanRequest }
        }
        
        // Dual combination check (e.g., "thực đơn" + "hôm nay")
        if (lower.contains("thực đơn") || lower.contains("kế hoạch ăn") || lower.contains("plan")) && 
           (lower.contains("hôm nay") || lower.contains("ngày hôm nay")) {
            return .dailyPlanRequest
        }
        
        // 2. Weekly Plan Requests
        let weeklyKeywords = [
            "lên thực đơn tuần", "lập kế hoạch tuần", "plan tuần này", "thực đơn 7 ngày"
        ]
        for kw in weeklyKeywords {
            if lower.contains(kw) { return .weeklyPlanRequest }
        }
        
        // 3. Rebalance
        if lower.contains("cân đối") || lower.contains("rebalance") || lower.contains("chỉnh lại") || lower.contains("nhiều quá") {
            return .rebalanceRequest
        }
        
        // 4. Meal Logging
        if lower.contains("vừa ăn") || lower.contains("đã ăn") || lower.contains("ăn rồi") || lower.contains("ghi lại") {
            return .mealLogging
        }
        
        // 5. Progress
        if lower.contains("tiến độ") || lower.contains("tuần qua") || lower.contains("giảm cân") || lower.contains("cân nặng") {
            return .progressQuestion
        }
        
        // 6. Cooking
        if lower.contains("nấu") || lower.contains("chế biến") || lower.contains("làm") || lower.contains("công thức") {
            return .cookingQuestion
        }
        
        // 7. Nutrition / Health
        if lower.contains("sức khỏe") || lower.contains("bệnh") || lower.contains("dị ứng") || lower.contains("kiêng") {
            return .nutritionQuestion
        }
        
        // 8. Weather
        if lower.contains("trời thế nào") || lower.contains("thời tiết") || lower.contains("trời hôm nay") {
            return .weatherQuestion
        }
        
        return .generalChat
    }
}
