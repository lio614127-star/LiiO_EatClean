import Foundation

struct ChatSessionModel: Identifiable, Codable {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var lastMessagePreview: String?
    var isActive: Bool
    var isArchived: Bool
    var isPinned: Bool
    var messageCount: Int32
    var contextSummary: String?
    var summaryUpdatedAt: Date?
    var source: String // aiCoach / voiceAssistant
    var metadataJSON: String?
    
    init(id: UUID = UUID(),
         title: String = "Hội thoại mới",
         createdAt: Date = Date(),
         updatedAt: Date = Date(),
         lastMessagePreview: String? = nil,
         isActive: Bool = true,
         isArchived: Bool = false,
         isPinned: Bool = false,
         messageCount: Int32 = 0,
         contextSummary: String? = nil,
         summaryUpdatedAt: Date? = nil,
         source: String = "aiCoach",
         metadataJSON: String? = nil) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastMessagePreview = lastMessagePreview
        self.isActive = isActive
        self.isArchived = isArchived
        self.isPinned = isPinned
        self.messageCount = messageCount
        self.contextSummary = contextSummary
        self.summaryUpdatedAt = summaryUpdatedAt
        self.source = source
        self.metadataJSON = metadataJSON
    }
}
