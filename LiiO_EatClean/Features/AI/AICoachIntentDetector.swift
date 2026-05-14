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
        
        let intentMap: [ContextIntent: [String]] = [
            .mealLogging: ["an", "log", "ghi", "mon an", "bua phu", "sang", "trua", "toi", "vua an", "da an"],
            .todayNutrition: ["calo", "ninh duong", "macro", "nap", "protein", "carb", "fat", "duong", "con lai"],
            .dailyPlanStatus: ["ke hoach", "thuc don", "plan", "hom nay an gi", "dung ke hoach", "co thuc don chua"],
            .dailyPlanGeneration: ["len thuc don", "tao ke hoach", "tinh thuc don", "len plan"],
            .weeklyPlan: ["tuan nay", "ca tuan", "tuan toi"],
            .progress: ["tien do", "adherence", "bieu do", "hieu qua", "tuan thu"],
            .weightTrend: ["can nang", "can", "giam can", "tang can", "xu huong", "kg"],
            .adherence: ["tuan thu", "dung gio", "bo qua", "tuan thu ke hoach"],
            .metabolic: ["metabolic", "tdee", "bmr", "trao doi chat", "co dia", "hap thu"],
            .rebalance: ["rebalance", "can bang lai", "bu calo", "an lo", "quá chén", "an qua"],
            .cooking: ["nau", "che bien", "cong thuc", "nguyen lieu"],
            .healthNutrition: ["di ung", "suc khoe", "benh", "kieng"]
        ]
        
        for (intent, keywords) in intentMap {
            var matched: [String] = []
            for kw in keywords {
                if query.contains(kw) {
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
            case .generalChat:
                // Basic info
                sections.insert(.todayTargets)
                sections.insert(.todayMealLogs)
            }
        }
        return sections
    }
}
