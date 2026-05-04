import Foundation

// MARK: - Health Condition Model
struct HealthCondition: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String              // e.g., "Gan nhiễm mỡ", "Tiểu đường"
    var avoidFoods: [String]      // e.g., ["Đồ chiên", "Rượu bia"]
    var dietaryNotes: String      // e.g., "Hạn chế chất béo, tăng rau xanh"
    
    init(id: UUID = UUID(), name: String, avoidFoods: [String] = [], dietaryNotes: String = "") {
        self.id = id
        self.name = name
        self.avoidFoods = avoidFoods
        self.dietaryNotes = dietaryNotes
    }
}

// MARK: - Memory Update (standardized format from Learning System)
struct MemoryUpdate: Codable {
    enum UpdateType: String, Codable {
        case addCondition = "add_condition"
        case addLike = "add_like"
        case addDislike = "add_dislike"
        case addNote = "add_note"
    }
    let type: UpdateType
    let value: String
    var avoid: [String]? = nil
    var dietaryNotes: String? = nil
}

// MARK: - User Profile Memory (AI-friendly, persistent)
struct UserProfileMemory: Codable {
    var healthConditions: [HealthCondition] = []
    var likes: [String] = []           // Foods user enjoys
    var dislikes: [String] = []        // Foods user avoids (personal preference)
    var dietaryNotes: [String] = []    // General dietary notes
    
    /// Flatten all avoidFoods from all health conditions for quick lookup
    var allAvoidFoods: [String] {
        healthConditions.flatMap { $0.avoidFoods }
    }
    
    /// Check if a food should be avoided (health or preference)
    func shouldAvoid(_ foodName: String) -> Bool {
        let lower = foodName.lowercased()
        return allAvoidFoods.contains(where: { $0.lowercased().contains(lower) || lower.contains($0.lowercased()) }) ||
               dislikes.contains(where: { $0.lowercased().contains(lower) || lower.contains($0.lowercased()) })
    }
    
    /// Check if memory has any meaningful content
    var hasContent: Bool {
        !healthConditions.isEmpty || !likes.isEmpty || !dislikes.isEmpty || !dietaryNotes.isEmpty
    }
}
