import Foundation

struct LinkCandidate {
    let mealLog: MealModel
    let plannedMeal: PlannedMealModel
    let confidence: Double // 0.0 to 1.0
    let nameScore: Double
    let calorieScore: Double
    let mealTypeScore: Double
}

/// Result of auto-link attempt
enum AutoLinkResult {
    case linked(plannedMealType: String)
    case suggested(mealId: UUID, plannedMealType: String)
    case none
}

class MealPlanLinkingService {
    static let shared = MealPlanLinkingService()
    
    private init() {}
    
    // MARK: - Scoring Weights (per user spec)
    
    private static let nameWeight: Double = 0.60
    private static let calorieWeight: Double = 0.20
    private static let mealTypeWeight: Double = 0.15
    private static let bonusWeight: Double = 0.05 // time proximity / bonus
    
    private static let autoLinkThreshold: Double = 0.88
    private static let suggestThreshold: Double = 0.70
    
    // MARK: - Vietnamese Food Name Synonyms
    
    private static let synonymMap: [String: String] = [
        "chicken pho": "pho ga",
        "beef pho": "pho bo",
        "pho ga": "pho ga",
        "pho bo": "pho bo",
        "com tam": "com tam",
        "broken rice": "com tam",
        "bun bo hue": "bun bo hue",
        "banh mi": "banh mi",
        "goi cuon": "goi cuon",
        "spring rolls": "goi cuon",
        "bun cha": "bun cha",
        "yaourt": "sua chua",
        "yogurt": "sua chua",
        "greek yogurt": "sua chua hy lap",
        "chia": "hat chia",
        "dragon fruit": "thanh long",
    ]
    
    /// Vietnamese connector/filler words to strip during normalization
    private static let stopWords: Set<String> = [
        // Vietnamese connectors
        "voi", "va", "cung", "kem", "mon", "phan",
        // English descriptors
        "light", "healthy", "version", "phien", "ban", "lanh", "manh",
        "it", "beo", "low", "sugar", "fat",
        "diet", "clean", "homemade", "tu", "lam",
        // Portion descriptors
        "nho", "vua", "lon", "to",
    ]
    
    // MARK: - Name Normalization (v2)
    
    /// Normalize Vietnamese food name for comparison
    /// "Sữa chua không đường với hạt chia & thanh long" → "sua chua khong duong hat chia thanh long"
    static func normalizeFoodName(_ name: String) -> String {
        var result = name
        
        // 1. Remove text in parentheses: "(Light Chicken Pho)" → ""
        result = result.replacingOccurrences(of: "\\([^)]*\\)", with: "", options: .regularExpression)
        
        // 2. Replace & with space
        result = result.replacingOccurrences(of: "&", with: " ")
        
        // 3. Lowercase
        result = result.lowercased()
        
        // 4. Remove Vietnamese accents
        result = result.folding(options: .diacriticInsensitive, locale: Locale(identifier: "vi"))
        
        // 5. Remove all non-alphanumeric except spaces
        result = result.components(separatedBy: CharacterSet.alphanumerics.union(.whitespaces).inverted).joined(separator: " ")
        
        // 6. Split into tokens, remove stop words
        var tokens = result.split(separator: " ").map(String.init).filter { !$0.isEmpty }
        tokens = tokens.filter { !stopWords.contains($0) }
        
        // 7. Apply per-token synonym mapping
        tokens = tokens.map { token in
            synonymMap[token] ?? token
        }
        
        // 8. Also try full-phrase synonym mapping
        let fullPhrase = tokens.joined(separator: " ")
        if let synonym = synonymMap[fullPhrase] {
            return synonym
        }
        
        // 9. Collapse multiple spaces, trim
        result = tokens.joined(separator: " ").trimmingCharacters(in: .whitespaces)
        
        return result
    }
    
    // MARK: - Token Overlap Score
    
    /// Calculate token overlap between two normalized strings
    /// Returns 0.0 to 1.0
    static func tokenOverlap(_ a: String, _ b: String) -> Double {
        let tokensA = Set(a.split(separator: " ").map(String.init))
        let tokensB = Set(b.split(separator: " ").map(String.init))
        
        guard !tokensA.isEmpty || !tokensB.isEmpty else { return 0.0 }
        
        let intersection = tokensA.intersection(tokensB)
        let maxCount = max(tokensA.count, tokensB.count)
        
        return Double(intersection.count) / Double(maxCount)
    }
    
    // MARK: - Name Similarity Score
    
    /// Calculate name similarity between two food names
    /// Returns 0.0 to 1.0
    static func nameSimilarity(_ actualName: String, _ plannedName: String) -> Double {
        let normActual = normalizeFoodName(actualName)
        let normPlanned = normalizeFoodName(plannedName)
        
        // Exact match after normalization
        if normActual == normPlanned {
            return 1.0
        }
        
        // One contains the other
        if normActual.contains(normPlanned) || normPlanned.contains(normActual) {
            return 0.92
        }
        
        // Token overlap
        let overlap = tokenOverlap(normActual, normPlanned)
        
        if overlap >= 0.85 { return 0.90 }
        if overlap >= 0.70 { return 0.75 }
        if overlap >= 0.50 { return 0.55 }
        
        return overlap * 0.6 // Scale down low overlaps
    }
    
    // MARK: - Calorie Similarity Score
    
    /// Calculate calorie similarity
    /// Returns 0.0 to 1.0
    static func calorieSimilarity(actual: Double, planned: Double) -> Double {
        guard planned > 0 else { return 0.5 }
        
        let diff = abs(actual - planned)
        
        if diff <= 30 { return 1.0 }
        if diff <= 80 { return 0.9 }
        
        let percentDiff = diff / planned
        if percentDiff <= 0.15 { return 0.8 }
        if percentDiff <= 0.25 { return 0.6 }
        if percentDiff <= 0.40 { return 0.3 }
        
        return 0.1
    }
    
    // MARK: - MealType Score
    
    static func mealTypeSimilarity(actual: String, planned: String) -> Double {
        let normActual = actual.lowercased().trimmingCharacters(in: .whitespaces)
        let normPlanned = planned.lowercased().trimmingCharacters(in: .whitespaces)
        
        if normActual == normPlanned { return 1.0 }
        
        // Map both to canonical types
        let canonicalMap: [String: String] = [
            "bữa sáng": "breakfast", "breakfast": "breakfast", "sang": "breakfast",
            "bữa trưa": "lunch", "lunch": "lunch", "trưa": "lunch", "trua": "lunch",
            "bữa tối": "dinner", "dinner": "dinner", "tối": "dinner", "toi": "dinner",
            "ăn vặt": "snack", "snack": "snack", "an vat": "snack",
        ]
        
        let canonA = canonicalMap[normActual] ?? normActual
        let canonB = canonicalMap[normPlanned] ?? normPlanned
        
        if canonA == canonB { return 1.0 }
        
        // Different main meals
        return 0.0
    }
    
    // MARK: - Combined Similarity Score
    
    /// Calculate overall similarity between a meal log and a planned meal
    func calculateSimilarity(mealLog: MealModel, plannedMeal: PlannedMealModel) -> (total: Double, name: Double, calorie: Double, mealType: Double) {
        
        // 1. MealType score (gate — if 0, total is 0)
        let mealTypeScore = Self.mealTypeSimilarity(actual: mealLog.mealType, planned: plannedMeal.type)
        if mealTypeScore == 0.0 {
            return (0.0, 0.0, 0.0, 0.0)
        }
        
        // 2. Name similarity — compare ALL actual food names against ALL planned food names
        //    Use the best match per actual food, then average
        let actualNames = mealLog.mealFoods.compactMap { $0.foodItem?.name }
        let plannedNames = plannedMeal.foodItems.map { $0.name }
        
        var nameScore: Double = 0.0
        
        if actualNames.isEmpty && plannedNames.isEmpty {
            nameScore = 0.5
        } else if actualNames.isEmpty || plannedNames.isEmpty {
            nameScore = 0.0
        } else {
            // For each actual food, find best matching planned food
            var totalBestScore: Double = 0.0
            for actualName in actualNames {
                var bestScore: Double = 0.0
                for plannedName in plannedNames {
                    let sim = Self.nameSimilarity(actualName, plannedName)
                    bestScore = max(bestScore, sim)
                }
                totalBestScore += bestScore
            }
            nameScore = totalBestScore / Double(max(actualNames.count, plannedNames.count))
        }
        
        // 3. Calorie similarity
        let calorieScore = Self.calorieSimilarity(actual: mealLog.totalCalories, planned: plannedMeal.totalCalories)
        
        // 4. Combined score
        let total = nameScore * Self.nameWeight
                  + calorieScore * Self.calorieWeight
                  + mealTypeScore * Self.mealTypeWeight
                  + 0.02 // Small time bonus (same day = assumed close enough)
        
        return (min(total, 1.0), nameScore, calorieScore, mealTypeScore)
    }
    
    // MARK: - Find Candidates
    
    func findCandidateLinks(for mealLog: MealModel, in dailyPlan: DailyPlanModel) -> [LinkCandidate] {
        var candidates: [LinkCandidate] = []
        
        for plannedMeal in dailyPlan.plannedMeals {
            // Skip already eaten/skipped/replaced meals
            guard plannedMeal.status == "planned" else { continue }
            // Skip if already linked to another meal
            guard plannedMeal.actualMealLogId == nil else { continue }
            
            let (score, nameScore, calorieScore, mealTypeScore) = calculateSimilarity(mealLog: mealLog, plannedMeal: plannedMeal)
            
            // Debug logging
            let actualFoodName = mealLog.mealFoods.first?.foodItem?.name ?? "?"
            let plannedFoodName = plannedMeal.foodItems.first?.name ?? "?"
            let normActual = Self.normalizeFoodName(actualFoodName)
            let normPlanned = Self.normalizeFoodName(plannedFoodName)
            
            print("""
            🔍 Smart Link Check:
               Logged:    "\(actualFoodName)" → normalized: "\(normActual)"
               Planned:   "\(plannedFoodName)" → normalized: "\(normPlanned)"
               nameScore: \(String(format: "%.2f", nameScore))
               calScore:  \(String(format: "%.2f", calorieScore))
               typeScore: \(String(format: "%.2f", mealTypeScore))
               TOTAL:     \(String(format: "%.2f", score))
               Threshold: autoLink=\(Self.autoLinkThreshold) suggest=\(Self.suggestThreshold)
               Result:    \(score >= Self.autoLinkThreshold ? "🟢 AUTO-LINK" : score >= Self.suggestThreshold ? "🟡 SUGGEST" : "🔴 NO MATCH")
            """)
            
            if score >= Self.suggestThreshold * 0.85 { // Capture candidates slightly below suggest threshold for debugging
                candidates.append(LinkCandidate(
                    mealLog: mealLog,
                    plannedMeal: plannedMeal,
                    confidence: score,
                    nameScore: nameScore,
                    calorieScore: calorieScore,
                    mealTypeScore: mealTypeScore
                ))
            }
        }
        
        return candidates.sorted { $0.confidence > $1.confidence }
    }
    
    // MARK: - Auto-Link Logic
    
    func forceLink(
        mealLog: MealModel,
        dailyPlan: DailyPlanModel,
        plannedMealId: UUID,
        mealRepository: MealRepositoryProtocol,
        dailyPlanRepository: DailyPlanRepositoryProtocol
    ) async -> Bool {
        guard let plannedMeal = dailyPlan.plannedMeals.first(where: { $0.id == plannedMealId }) else { return false }
        
        do {
            var updatedMeal = mealLog
            updatedMeal.linkedPlannedMealId = plannedMeal.id
            try await mealRepository.saveMeal(updatedMeal, for: mealLog.date)
            
            var updatedPlan = dailyPlan
            if let idx = updatedPlan.plannedMeals.firstIndex(where: { $0.id == plannedMeal.id }) {
                updatedPlan.plannedMeals[idx].status = "eaten"
                updatedPlan.plannedMeals[idx].actualMealLogId = mealLog.id
                updatedPlan.plannedMeals[idx].eatenAt = Date()
                try await dailyPlanRepository.savePlan(updatedPlan, status: updatedPlan.status)
            }
            return true
        } catch {
            print("❌ Force link failed: \(error)")
            return false
        }
    }
    
    func tryAutoLink(
        mealLog: MealModel,
        dailyPlan: DailyPlanModel?,
        mealRepository: MealRepositoryProtocol,
        dailyPlanRepository: DailyPlanRepositoryProtocol
    ) async -> AutoLinkResult {
        guard let plan = dailyPlan else {
            print("🔗 Auto-link: No daily plan found")
            return .none
        }
        
        let candidates = findCandidateLinks(for: mealLog, in: plan)
        guard let best = candidates.first else {
            print("🔗 Auto-link: No candidates found")
            return .none
        }
        
        // Check for ambiguity: if top 2 candidates are very close, suggest instead of auto-link
        if candidates.count >= 2 {
            let second = candidates[1]
            let scoreDiff = best.confidence - second.confidence
            if scoreDiff < 0.05 && best.confidence >= Self.autoLinkThreshold {
                print("🔗 Auto-link: Ambiguous — top 2 scores too close (\(String(format: "%.2f", best.confidence)) vs \(String(format: "%.2f", second.confidence))). Suggesting instead.")
                return .suggested(mealId: mealLog.id, plannedMealType: best.plannedMeal.type)
            }
        }
        
        if best.confidence >= Self.autoLinkThreshold {
            // High confidence: auto-link
            do {
                var updatedMeal = mealLog
                updatedMeal.linkedPlannedMealId = best.plannedMeal.id
                try await mealRepository.saveMeal(updatedMeal, for: mealLog.date)
                
                // Update plan status
                var updatedPlan = plan
                if let idx = updatedPlan.plannedMeals.firstIndex(where: { $0.id == best.plannedMeal.id }) {
                    updatedPlan.plannedMeals[idx].status = "eaten"
                    updatedPlan.plannedMeals[idx].actualMealLogId = mealLog.id
                    updatedPlan.plannedMeals[idx].eatenAt = Date()
                    try await dailyPlanRepository.savePlan(updatedPlan, status: updatedPlan.status)
                }
                
                let actualName = mealLog.mealFoods.first?.foodItem?.name ?? "?"
                let plannedName = best.plannedMeal.foodItems.first?.name ?? "?"
                print("🔗✅ Auto-linked '\(actualName)' → '\(plannedName)' (score: \(String(format: "%.2f", best.confidence)))")
                print("   linkedPlannedMealId = \(best.plannedMeal.id)")
                
                return .linked(plannedMealType: best.plannedMeal.type)
            } catch {
                print("❌ Auto-link save failed: \(error)")
                return .none
            }
        } else if best.confidence >= Self.suggestThreshold {
            let actualName = mealLog.mealFoods.first?.foodItem?.name ?? "?"
            print("🔗🟡 Suggesting link for '\(actualName)' (score: \(String(format: "%.2f", best.confidence)))")
            return .suggested(mealId: mealLog.id, plannedMealType: best.plannedMeal.type)
        }
        
        print("🔗🔴 No match for '\(mealLog.mealFoods.first?.foodItem?.name ?? "?")' (best score: \(String(format: "%.2f", best.confidence)))")
        return .none
    }
}
