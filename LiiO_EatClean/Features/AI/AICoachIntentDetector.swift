import Foundation

class AICoachIntentDetector {
    static let shared = AICoachIntentDetector()
    
    private init() {}
    
    func detectContextIntents(
        from text: String,
        currentTab: String? = nil,
        mode: AICoachContextMode = .chat
    ) -> [DetectedIntent] {
        let query = text.lowercased().folding(options: .diacriticInsensitive, locale: Locale(identifier: "vi"))
        var detected: [DetectedIntent] = []
        
        // Strict word lists to avoid greedy collisions (e.g., "an" in "bạn")
        let intentMap: [ContextIntent: [String]] = [
            .mealLogging: ["an", "log", "ghi", "mon an", "bua phu", "sang", "trua", "toi", "vua an", "da an", "ghi mon", "log mon"],
            .todayNutrition: ["calo", "dinh duong", "macro", "nap", "protein", "carb", "fat", "duong", "con lai"],
            .dailyPlanStatus: ["ke hoach", "thuc don", "plan", "dung ke hoach", "co thuc don chua", "the nao", "sao roi", "on chua"],
            .dailyPlanGeneration: ["len thuc don", "tao ke hoach", "tinh thuc don", "len plan", "thiet ke thuc don"],
            .weeklyPlan: ["tuan nay", "ca tuan", "tuan toi"],
            .progress: ["tien do", "adherence", "bieu do", "hieu qua", "tuan thu"],
            .weightTrend: ["can nang", "can", "giam can", "tang can", "xu huong", "kg", "ky"],
            .adherence: ["tuan thu", "dung gio", "bo qua", "tuan thu ke hoach"],
            .metabolic: ["metabolic", "tdee", "bmr", "trao doi chat", "co dia", "hap thu"],
            .rebalance: ["rebalance", "can bang lai", "bu calo", "an lo", "qua chen", "an qua"],
            .cooking: ["nau", "che bien", "cong thuc", "nguyen lieu"],
            .healthNutrition: ["di ung", "suc khoe", "benh", "kieng"],
            .dateTimeQuestion: ["ngay may", "thu may", "may gio", "hom nay", "ngay mai", "ngay kia", "bay gio"],
            .appQuestion: ["cai dat", "huong dan", "app nay", "liio"]
        ]
        
        for (intent, keywords) in intentMap {
            var matched: [String] = []
            for kw in keywords {
                // Use strict word boundary check to avoid collisions like "bạn" matching "an"
                if containsWordStrictly(query, keyword: kw) {
                    matched.append(kw)
                }
            }
            
            if !matched.isEmpty {
                // Simple confidence calculation
                let confidence = Double(matched.count) / Double(keywords.count) * 0.5 + 0.5
                detected.append(DetectedIntent(intent: intent, confidence: min(1.0, confidence), matchedKeywords: matched))
            }
        }
        
        // Confidence Filtering (>= 0.45)
        let filtered = detected.filter { $0.confidence >= 0.45 }
        
        if filtered.isEmpty {
            return [DetectedIntent(intent: .generalChat, confidence: 1.0, matchedKeywords: [])]
        }
        
        // Limit to top 4 intents to prevent bloating
        return Array(filtered.sorted(by: { $0.confidence > $1.confidence }).prefix(4))
    }
    
    private func containsWordStrictly(_ query: String, keyword: String) -> Bool {
        // Prevent greedy collisions like "bạn" -> "ban" contains "an"
        // Using word boundary regex pattern
        let escapedKw = NSRegularExpression.escapedPattern(for: keyword)
        let pattern = "\\b\(escapedKw)\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return query.contains(keyword) // Fallback
        }
        let range = NSRange(location: 0, length: (query as NSString).length)
        return regex.firstMatch(in: query, options: [], range: range) != nil
    }
    
    /// Checks if the current query context should be allowed to display food suggestion cards.
    func shouldAllowFoodSuggestions(for text: String) -> Bool {
        let query = text.lowercased().folding(options: .diacriticInsensitive, locale: Locale(identifier: "vi"))
        
        // 1. High Priority Exclusions (Explicitly Non-Food Intents)
        let exclusionKeywords = [
            "ngay may", "thu may", "may gio", "tien do", "can nang", "adherence", 
            "tai sao", "sao cu", "ly do gi", "the nao", "sao roi", "chuyen sang", 
            "chuyen qua", "thong tin", "thuc don hom nay the nao"
        ]
        for kw in exclusionKeywords {
            if query.contains(kw) {
                print("[FoodCard] blocked reason=ExplicitExclusionKeyword query='\(text)' matched='\(kw)'")
                return false
            }
        }
        
        // 2. STRICT ALLOWLIST FOR INTENTS
        let intents = detectContextIntents(from: text)
        let detectedTypes = intents.map { $0.intent }
        
        // Only explicitly allowed intents are cleared to show suggestion cards
        let allowedIntents: Set<ContextIntent> = [
            .mealLogging, 
            .dailyPlanGeneration, 
            .rebalance, 
            .cooking,
            .healthNutrition // User asking safety advice for meals
        ]
        
        let blockedIntents: Set<ContextIntent> = [
            .dailyPlanStatus,
            .dateTimeQuestion,
            .progress,
            .weightTrend,
            .appQuestion,
            .generalChat
        ]
        
        let hasBlocked = detectedTypes.contains { blockedIntents.contains($0) }
        let hasAllowed = detectedTypes.contains { allowedIntents.contains($0) }
        
        // CRITICAL: dailyPlanStatus ("Thực đơn hôm nay thế nào") NEVER triggers food card
        if detectedTypes.contains(.dailyPlanStatus) && !detectedTypes.contains(.mealLogging) {
            print("[FoodCard] blocked reason=IntentNotAllowed (dailyPlanStatus)")
            return false
        }
        
        if hasBlocked && !hasAllowed {
            print("[FoodCard] blocked reason=IntentNotAllowed (Explicit blocked intents detected: \(detectedTypes.map { "\($0)" }))")
            return false
        }
        
        // Check for explicit command overrides
        let explicitAllowedKeywords = ["goi y mon", "an gi tiep", "mon thay the", "nen an gi", "an gi hom nay", "log mon", "ghi mon"]
        let hasExplicit = explicitAllowedKeywords.contains { query.contains($0) }
        
        let shouldRender = (hasAllowed || hasExplicit) && !hasBlocked
        
        print("[FoodCard] intent=\(detectedTypes.map { $0.rawValue }.joined(separator: ", ")), explicitlyAllowed=\(hasExplicit), shouldRender=\(shouldRender)")
        
        return shouldRender
    }
    
    func mapIntentsToSections(_ intents: Set<ContextIntent>) -> Set<ContextSection> {
        var sections = Set<ContextSection>()
        // Luôn nạp profileMinimal cho mọi intent
        sections.insert(.profileMinimal)
        
        for intent in intents {
            switch intent {
            case .mealLogging, .todayNutrition:
                sections.insert(.todayTargets)
                sections.insert(.todayMealLogs)
            case .dailyPlanStatus, .dailyPlanGeneration, .dailyPlanRequest:
                sections.insert(.todayTargets)
                sections.insert(.todayMealLogs)
                sections.insert(.todayDailyPlan)
                sections.insert(.plannedVsActual)
            case .weeklyPlan:
                sections.insert(.weeklyPlans)
            case .progress, .weightTrend, .progressQuestion:
                sections.insert(.progressTrend)
                sections.insert(.weightTrend)
                sections.insert(.adherenceSummary)
            case .adherence:
                sections.insert(.adherenceSummary)
                sections.insert(.plannedVsActual)
            case .metabolic:
                sections.insert(.metabolicSummary)
                sections.insert(.weightTrend)
            case .rebalance, .rebalanceRequest:
                sections.insert(.todayMealLogs)
                sections.insert(.todayDailyPlan)
                sections.insert(.plannedVsActual)
            case .cooking:
                sections.insert(.cookingPreferences)
            case .healthNutrition:
                sections.insert(.healthConstraints)
            case .generalChat, .dateTimeQuestion, .appQuestion:
                // Minimal info for non-data queries
                sections.insert(.todayTargets)
                sections.insert(.todayMealLogs)
            }
        }
        return sections
    }
}
