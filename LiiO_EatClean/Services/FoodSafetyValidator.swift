import Foundation

class FoodSafetyValidator {
    
    // MARK: - Singleton
    static let shared = FoodSafetyValidator()
    
    // MARK: - Data
    private var mapping: HealthFoodMapping?
    
    private init() {
        loadMapping()
    }
    
    // MARK: - Load JSON
    private func loadMapping() {
        guard let url = Bundle.main.url(forResource: "health_food_mapping", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return }
        mapping = try? JSONDecoder().decode(HealthFoodMapping.self, from: data)
    }
    
    // MARK: - Text Normalization
    
    /// Normalize Vietnamese text: lowercase, remove diacritics
    func normalizeText(_ text: String) -> String {
        text.lowercased()
            .folding(options: .diacriticInsensitive, locale: Locale(identifier: "vi"))
    }
    
    // MARK: - Validation (Layer 2)
    
    /// Check if a food name violates any health restrictions
    /// Returns list of violated condition names
    func validateFood(name: String, against memory: UserProfileMemory) -> [String] {
        let normalized = normalizeText(name)
        var violations: [String] = []
        
        // Check direct avoidFoods from memory
        for avoid in memory.avoidFoods {
            let normalizedAvoid = normalizeText(avoid)
            if normalized.contains(normalizedAvoid) || normalizedAvoid.contains(normalized) {
                violations.append("Kiêng cữ: \(avoid)")
            }
        }
        
        // Check against alias dictionary
        for condition in memory.healthConditions {
            let conditionName = condition.name
            guard let conditionData = mapping?.conditions[conditionName] else { continue }
            
            // Check avoid list
            for avoidItem in conditionData.avoid {
                let normalizedAvoid = normalizeText(avoidItem)
                if normalized.contains(normalizedAvoid) || normalizedAvoid.contains(normalized) {
                    violations.append(conditionName)
                    break
                }
            }
            
            // Check aliases
            for (_, aliases) in conditionData.aliases {
                for alias in aliases {
                    let normalizedAlias = normalizeText(alias)
                    if normalized.contains(normalizedAlias) || normalizedAlias.contains(normalized) {
                        violations.append(conditionName)
                        break
                    }
                }
            }
        }
        
        return Array(Set(violations)) // Deduplicate
    }
    
    /// Validate a list of suggested food items, return indices of violations
    func validateFoodItems(_ items: [[String: Any]], against memory: UserProfileMemory) -> [(index: Int, name: String, violations: [String])] {
        var results: [(index: Int, name: String, violations: [String])] = []
        for (index, item) in items.enumerated() {
            guard let name = item["name"] as? String else { continue }
            let violations = validateFood(name: name, against: memory)
            if !violations.isEmpty {
                results.append((index: index, name: name, violations: violations))
            }
        }
        return results
    }
    
    // MARK: - Free-text Scanner (Layer 2 for chat)
    
    /// Scan free-text response for forbidden food mentions
    func scanFreeText(_ text: String, against memory: UserProfileMemory) -> [String] {
        let normalized = normalizeText(text)
        var detectedFoods: [String] = []
        
        // Scan against avoidFoods
        for avoid in memory.avoidFoods {
            let normalizedAvoid = normalizeText(avoid)
            if normalized.contains(normalizedAvoid) {
                detectedFoods.append(avoid)
            }
        }
        
        // Scan against condition aliases
        for condition in memory.healthConditions {
            guard let conditionData = mapping?.conditions[condition.name] else { continue }
            for avoidItem in conditionData.avoid {
                let normalizedAvoid = normalizeText(avoidItem)
                if normalized.contains(normalizedAvoid) {
                    detectedFoods.append(avoidItem)
                }
            }
            for (_, aliases) in conditionData.aliases {
                for alias in aliases {
                    let normalizedAlias = normalizeText(alias)
                    if normalized.contains(normalizedAlias) {
                        detectedFoods.append(alias)
                    }
                }
            }
        }
        
        return Array(Set(detectedFoods))
    }
    
    // MARK: - Recommendations (HLTH-02)
    
    /// Get recommended foods for user's health conditions
    func getRecommendedFoods(for memory: UserProfileMemory) -> [String] {
        var recommended: [String] = []
        for condition in memory.healthConditions {
            if let conditionData = mapping?.conditions[condition.name] {
                recommended.append(contentsOf: conditionData.recommended)
            }
        }
        return Array(Set(recommended))
    }
    
    /// Get all avoid foods including aliases for user's conditions
    func getAllAvoidFoods(for memory: UserProfileMemory) -> [String] {
        var allAvoid = memory.avoidFoods
        for condition in memory.healthConditions {
            if let conditionData = mapping?.conditions[condition.name] {
                allAvoid.append(contentsOf: conditionData.avoid)
                for (_, aliases) in conditionData.aliases {
                    allAvoid.append(contentsOf: aliases)
                }
            }
        }
        return Array(Set(allAvoid))
    }
}

// MARK: - JSON Models

struct HealthFoodMapping: Codable {
    let version: Int
    let conditions: [String: ConditionMapping]
}

struct ConditionMapping: Codable {
    let recommended: [String]
    let avoid: [String]
    let aliases: [String: [String]]
    let risk_tags: [String]
}
