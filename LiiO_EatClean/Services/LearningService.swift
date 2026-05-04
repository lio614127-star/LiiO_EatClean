import Foundation

class LearningService {
    static let shared = LearningService()
    
    private let memoryManager: MemoryManagerProtocol
    private let aiService = AIService.shared
    
    init(memoryManager: MemoryManagerProtocol = MemoryManager.shared) {
        self.memoryManager = memoryManager
    }
    
    // MARK: - Level 1: Client-side keyword scan
    
    struct ExtractionResult {
        let updates: [MemoryUpdate]
        let confidence: ExtractionConfidence
    }
    
    enum ExtractionConfidence {
        case high    // Level 1: keyword match, no AI needed
        case needsAI // Level 2: complex sentence, needs AI extraction
        case none    // No actionable info detected
    }
    
    func analyzeMessage(_ message: String) -> ExtractionConfidence {
        let lower = message.lowercased()
        
        let likePatterns = ["thích ăn", "thích món", "tôi thích", "mình thích", "khoái khẩu"]
        let dislikePatterns = ["ghét", "không thích", "không ăn được", "dị ứng", "không ưa"]
        let conditionPatterns = ["bị bệnh", "mắc bệnh", "bị gan", "bị tiểu đường", 
                                  "huyết áp", "cholesterol", "bác sĩ bảo", "bác sĩ dặn"]
        
        if conditionPatterns.contains(where: { lower.contains($0) }) {
            return .needsAI  // Complex health info -> let AI extract
        }
        
        if likePatterns.contains(where: { lower.contains($0) }) ||
           dislikePatterns.contains(where: { lower.contains($0) }) {
            return .needsAI // Still need AI to accurately extract the actual food name out of the sentence
        }
        
        return .none
    }
    
    // MARK: - Level 2: AI Extraction
    
    func extractWithAI(_ message: String) async throws -> [MemoryUpdate] {
        let systemPrompt = """
        Bạn là hệ thống trích xuất dữ liệu trí nhớ. Nhiệm vụ của bạn là đọc tin nhắn của người dùng và trích xuất các thông tin sức khỏe LÂU DÀI.
        CHỈ trích xuất: sở thích (thích/ghét) và bệnh lý/kiêng cữ. 
        KHÔNG trích xuất: thông tin ăn uống ngắn hạn (ví dụ: "hôm nay tôi ăn phở").
        
        Nếu có thông tin, trả về JSON chuẩn theo cấu trúc sau. Nếu không có, trả về mảng rỗng [].
        
        [
          {
            "type": "add_like" | "add_dislike" | "add_condition" | "add_note",
            "value": "Tên món ăn (nếu là sở thích) HOẶC Tên bệnh lý (nếu là condition)",
            "avoid": ["Món cần kiêng 1", "Món cần kiêng 2"], // Chỉ dùng khi type là add_condition
            "dietaryNotes": "Ghi chú kiêng cữ" // Chỉ dùng khi type là add_condition
          }
        ]
        """
        
        let prompt = systemPrompt + "\nTin nhắn: \"\(message)\""
        let responseText = try await aiService.generateText(prompt: prompt)
        
        // Parse the text block to get the JSON
        if let jsonString = responseText.extractJSON(),
           let data = jsonString.data(using: .utf8) {
            do {
                let updates = try JSONDecoder().decode([MemoryUpdate].self, from: data)
                return updates
            } catch {
                print("Failed to decode memory updates: \(error)")
                return []
            }
        }
        
        return []
    }
    
    // MARK: - Combined Pipeline
    
    func processMessage(_ message: String) async -> [MemoryUpdate] {
        let confidence = analyzeMessage(message)
        
        switch confidence {
        case .high, .needsAI:
            do {
                return try await extractWithAI(message)
            } catch {
                print("Learning extraction failed: \(error)")
                return []
            }
        case .none:
            return []
        }
    }
}

// Extension to extract JSON from markdown blocks
extension String {
    func extractJSON() -> String? {
        // Try finding ```json ... ```
        if let startRange = self.range(of: "```json"),
           let endRange = self.range(of: "```", range: startRange.upperBound..<self.endIndex) {
            return String(self[startRange.upperBound..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Try finding ``` ... ```
        if let startRange = self.range(of: "```\n"),
           let endRange = self.range(of: "```", range: startRange.upperBound..<self.endIndex) {
            return String(self[startRange.upperBound..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Just try parsing the raw text if it looks like an array or object
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        if (trimmed.hasPrefix("[") && trimmed.hasSuffix("]")) || (trimmed.hasPrefix("{") && trimmed.hasSuffix("}")) {
            return trimmed
        }
        
        return nil
    }
}
