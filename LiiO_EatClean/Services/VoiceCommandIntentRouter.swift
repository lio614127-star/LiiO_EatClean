import Foundation

enum VoiceCommandIntent: String {
    case dailyPlanRequest       // Legacy name for generation/creation flow
    case dailyPlanStatus        // Status review, evaluation, comparison
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
        let normalized = lower.folding(options: .diacriticInsensitive, locale: Locale(identifier: "vi"))
        
        print("[IntentRouter 1] raw='\(lower)'")
        print("[IntentRouter 2] normalized='\(normalized)'")
        
        // 1. Daily Plan Creation (Strict creation verbs)
        let dailyCreationKeywords = [
            "len thuc don", "lap thuc don", "tao thuc don", "thiet ke thuc don",
            "len ke hoach an", "len plan", "tao plan moi", "generate plan",
            "goi y thuc don", "len ke hoach ngay", "lap ke hoach"
        ]
        for kw in dailyCreationKeywords {
            if normalized.contains(kw) {
                print("[IntentRouter 3] matched dailyPlanRequest (generation)")
                return .dailyPlanRequest
            }
        }
        
        // 2. Daily Plan Status Check (Review, evaluate, remaining items)
        let hasPlanKeyword = normalized.contains("ke hoach") || normalized.contains("thuc don") || normalized.contains("plan")
        let statusReviewKeywords = [
            "the nao", "ra sao", "nhu the nao", "dung chua", "con gi", 
            "xem", "danh gia", "cua toi", "con thieu", "bua nao", "bua toi", "bua sang", "bua trua"
        ]
        
        if hasPlanKeyword {
            let isStatus = statusReviewKeywords.contains { normalized.contains($0) }
            if isStatus {
                print("[IntentRouter 3] matched dailyPlanStatus")
                return .dailyPlanStatus
            }
        }
        
        // Dual combination fallback for dailyPlanRequest ONLY IF not status-based
        if hasPlanKeyword && (normalized.contains("hom nay") || normalized.contains("ngay hom nay")) {
            // Example: "thực đơn hôm nay" -> default to status review if it's open ended
            // Let's treat general "thực đơn hôm nay" as status request to prevent disruptive regen overlays
            print("[IntentRouter 3] general plan question -> dailyPlanStatus")
            return .dailyPlanStatus
        }
        
        // 3. Weekly Plan Requests
        let weeklyKeywords = [
            "len thuc don tuan", "lap ke hoach tuan", "plan tuan nay", "thuc don 7 ngay"
        ]
        for kw in weeklyKeywords {
            if normalized.contains(kw) { return .weeklyPlanRequest }
        }
        
        // 4. Rebalance
        if normalized.contains("can doi") || normalized.contains("rebalance") || normalized.contains("chinh lai") || normalized.contains("nhieu qua") {
            return .rebalanceRequest
        }
        
        // 5. Meal Logging
        if normalized.contains("vua an") || normalized.contains("da an") || normalized.contains("an roi") || normalized.contains("ghi lai") {
            return .mealLogging
        }
        
        // 6. Progress
        if normalized.contains("tien do") || normalized.contains("tuan qua") || normalized.contains("giam can") || normalized.contains("can nang") {
            return .progressQuestion
        }
        
        // 7. Cooking
        if normalized.contains("nau") || normalized.contains("che bien") || normalized.contains("lam") || normalized.contains("cong thuc") {
            return .cookingQuestion
        }
        
        // 8. Nutrition / Health
        if normalized.contains("suc khoe") || normalized.contains("benh") || normalized.contains("di ung") || normalized.contains("kieng") {
            return .nutritionQuestion
        }
        
        // 9. Weather
        if normalized.contains("troi the nao") || normalized.contains("thoi tiet") || normalized.contains("troi hom nay") {
            return .weatherQuestion
        }
        
        print("[IntentRouter 3] matched generalChat")
        return .generalChat
    }
}
