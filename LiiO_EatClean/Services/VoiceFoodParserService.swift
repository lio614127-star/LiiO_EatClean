import Foundation

class VoiceFoodParserService {
    private let aiService = AIService.shared
    private let foodRepository: FoodRepositoryProtocol
    
    // Cache to avoid re-parsing same phrases
    private static var parseCache: [String: [AISuggestedFood]] = [:]
    
    init(foodRepository: FoodRepositoryProtocol = FoodRepository()) {
        self.foodRepository = foodRepository
    }
    
    func parseTranscript(_ text: String) async throws -> [AISuggestedFood] {
        let normalizedText = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedText.isEmpty else { return [] }
        
        // 1. Check cache
        if let cached = Self.parseCache[normalizedText] {
            return cached
        }
        
        // 2. Try local DB match first (simple heuristic: if transcript is short and closely matches a food)
        // For simplicity, we search the local DB with the full text. If a single strong match is found, we might use it.
        // But natural language like "tôi ăn 1 bát phở bò" might not match directly.
        // We will try AI first for reliability with natural language, but use a very short prompt.
        // Alternatively, we can use regex to strip "tôi ăn", "cho tôi" etc.
        
        let localFoods = try? await foodRepository.searchLocalFoods(query: normalizedText)
        if let exactMatch = localFoods?.first(where: { $0.name.lowercased() == normalizedText }) {
            // Found exact match locally (e.g. user just said "Phở bò")
            let suggestion = AISuggestedFood(
                name: exactMatch.name,
                calories: exactMatch.calories,
                protein: exactMatch.protein,
                carbs: exactMatch.carbs,
                fat: exactMatch.fat,
                servingSize: 1.0
            )
            Self.parseCache[normalizedText] = [suggestion]
            return [suggestion]
        }
        
        // 3. Fallback to AI parsing
        let prompt = """
        Parse câu sau thành JSON array chứa các món ăn:
        [{"name":"Tên","calories":350,"protein":20,"carbs":40,"fat":10,"servingSize":1.0}]
        Lưu ý: servingSize là số lượng phần ăn (vd: "2 bát" -> servingSize: 2.0).
        Chỉ trả về JSON, không giải thích.
        Câu: '\(text)'
        """
        
        let responseText = try await aiService.generateText(prompt: prompt, requestType: .voiceParsing, feature: "Phân tích giọng nói")
        
        // Parse the JSON array from responseText
        let cleaned = extractJSON(from: responseText)
        guard let data = cleaned.data(using: .utf8) else {
            throw NSError(domain: "VoiceFoodParser", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON data from AI"])
        }
        
        let parsedFoods = try JSONDecoder().decode([AISuggestedFood].self, from: data)
        
        // Save to cache
        Self.parseCache[normalizedText] = parsedFoods
        
        return parsedFoods
    }
    
    private func extractJSON(from text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let firstBracket = cleaned.firstIndex(of: "["),
           let lastBracket = cleaned.lastIndex(of: "]") {
            cleaned = String(cleaned[firstBracket...lastBracket])
        }
        return cleaned
    }
}
