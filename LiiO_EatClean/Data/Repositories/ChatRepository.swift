import Foundation
import CoreData

protocol ChatRepositoryProtocol {
    func fetchLatestActiveSession() async throws -> ChatSessionModel?
    func fetchAllSessions(includeArchived: Bool) async throws -> [ChatSessionModel]
    func createSession(title: String, source: String) async throws -> ChatSessionModel
    func fetchMessages(sessionId: UUID, limit: Int?) async throws -> [ChatMessageModel]
    func saveMessage(_ message: ChatMessageModel, sessionId: UUID) async throws
    func updateSessionMetadata(sessionId: UUID, lastMessage: String) async throws
    func deleteSession(sessionId: UUID) async throws
}

extension ChatRepositoryProtocol {
    func fetchMessages(sessionId: UUID) async throws -> [ChatMessageModel] {
        return try await fetchMessages(sessionId: sessionId, limit: nil)
    }
}

class ChatRepository: ChatRepositoryProtocol {
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }
    
    func fetchLatestActiveSession() async throws -> ChatSessionModel? {
        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "ChatSessionEntity")
            request.predicate = NSPredicate(format: "isActive == YES AND isArchived == NO")
            request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
            request.fetchLimit = 1
            
            let results = try self.context.fetch(request)
            guard let entity = results.first else { return nil }
            return self.mapSession(entity)
        }
    }
    
    func fetchAllSessions(includeArchived: Bool) async throws -> [ChatSessionModel] {
        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "ChatSessionEntity")
            if !includeArchived {
                request.predicate = NSPredicate(format: "isArchived == NO")
            }
            request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
            
            let results = try self.context.fetch(request)
            return results.map { self.mapSession($0) }
        }
    }
    
    func createSession(title: String, source: String) async throws -> ChatSessionModel {
        return try await context.perform {
            let entity = NSEntityDescription.insertNewObject(forEntityName: "ChatSessionEntity", into: self.context)
            let id = UUID()
            let now = Date()
            
            entity.setValue(id, forKey: "id")
            entity.setValue(title, forKey: "title")
            entity.setValue(now, forKey: "createdAt")
            entity.setValue(now, forKey: "updatedAt")
            entity.setValue(true, forKey: "isActive")
            entity.setValue(false, forKey: "isArchived")
            entity.setValue(source, forKey: "source")
            entity.setValue(0, forKey: "messageCount")
            
            try self.context.save()
            return self.mapSession(entity)
        }
    }
    
    func fetchMessages(sessionId: UUID, limit: Int? = nil) async throws -> [ChatMessageModel] {
        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "ChatMessageEntity")
            request.predicate = NSPredicate(format: "sessionId == %@", sessionId as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
            if let limit = limit {
                request.fetchLimit = limit
            }
            
            let results = try self.context.fetch(request)
            return results.map { self.mapMessage($0) }
        }
    }
    
    func saveMessage(_ message: ChatMessageModel, sessionId: UUID) async throws {
        try await context.perform {
            // 1. Save Message
            let entity = NSEntityDescription.insertNewObject(forEntityName: "ChatMessageEntity", into: self.context)
            entity.setValue(message.id, forKey: "id")
            entity.setValue(sessionId, forKey: "sessionId")
            entity.setValue(message.role.rawValue, forKey: "role")
            entity.setValue(message.text, forKey: "content")
            entity.setValue(message.createdAt, forKey: "createdAt")
            entity.setValue(message.inputMode, forKey: "inputMode")
            entity.setValue(message.outputMode, forKey: "outputMode")
            entity.setValue(message.isError, forKey: "isError")
            
            // Encode suggested foods
            if let foods = message.suggestedFoods, let data = try? JSONEncoder().encode(foods) {
                entity.setValue(String(data: data, encoding: .utf8), forKey: "suggestedFoodsJSON")
            }
            
            // Encode model info
            if let info = message.modelInfo, let data = try? JSONEncoder().encode(info) {
                entity.setValue(String(data: data, encoding: .utf8), forKey: "metadataJSON")
            }
            
            // 2. Update Session
            let sessionRequest = NSFetchRequest<NSManagedObject>(entityName: "ChatSessionEntity")
            sessionRequest.predicate = NSPredicate(format: "id == %@", sessionId as CVarArg)
            if let sessionEntity = try self.context.fetch(sessionRequest).first {
                sessionEntity.setValue(Date(), forKey: "updatedAt")
                sessionEntity.setValue(message.text.prefix(100).description, forKey: "lastMessagePreview")
                let currentCount = sessionEntity.value(forKey: "messageCount") as? Int32 ?? 0
                sessionEntity.setValue(currentCount + 1, forKey: "messageCount")
                
                // Link relationship if possible (automatic if defined in model, but we use sessionId as field too)
                entity.setValue(sessionEntity, forKey: "session")
            }
            
            try self.context.save()
        }
    }
    
    func updateSessionMetadata(sessionId: UUID, lastMessage: String) async throws {
        try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "ChatSessionEntity")
            request.predicate = NSPredicate(format: "id == %@", sessionId as CVarArg)
            
            if let entity = try self.context.fetch(request).first {
                entity.setValue(Date(), forKey: "updatedAt")
                entity.setValue(lastMessage.prefix(100).description, forKey: "lastMessagePreview")
                try self.context.save()
            }
        }
    }
    
    func deleteSession(sessionId: UUID) async throws {
        try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "ChatSessionEntity")
            request.predicate = NSPredicate(format: "id == %@", sessionId as CVarArg)
            
            if let entity = try self.context.fetch(request).first {
                self.context.delete(entity)
                try self.context.save()
            }
        }
    }
    
    // MARK: - Mappers
    
    private func mapSession(_ entity: NSManagedObject) -> ChatSessionModel {
        return ChatSessionModel(
            id: entity.value(forKey: "id") as? UUID ?? UUID(),
            title: entity.value(forKey: "title") as? String ?? "Hội thoại",
            createdAt: entity.value(forKey: "createdAt") as? Date ?? Date(),
            updatedAt: entity.value(forKey: "updatedAt") as? Date ?? Date(),
            lastMessagePreview: entity.value(forKey: "lastMessagePreview") as? String,
            isActive: entity.value(forKey: "isActive") as? Bool ?? true,
            isArchived: entity.value(forKey: "isArchived") as? Bool ?? false,
            isPinned: entity.value(forKey: "isPinned") as? Bool ?? false,
            messageCount: entity.value(forKey: "messageCount") as? Int32 ?? 0,
            contextSummary: entity.value(forKey: "contextSummary") as? String,
            summaryUpdatedAt: entity.value(forKey: "summaryUpdatedAt") as? Date,
            source: entity.value(forKey: "source") as? String ?? "aiCoach",
            metadataJSON: entity.value(forKey: "metadataJSON") as? String
        )
    }
    
    private func mapMessage(_ entity: NSManagedObject) -> ChatMessageModel {
        let roleString = entity.value(forKey: "role") as? String ?? "user"
        let role = ChatRole(rawValue: roleString) ?? .user
        
        var suggestedFoods: [AISuggestedFood]? = nil
        if let json = entity.value(forKey: "suggestedFoodsJSON") as? String,
           let data = json.data(using: .utf8) {
            suggestedFoods = try? JSONDecoder().decode([AISuggestedFood].self, from: data)
        }
        
        var modelInfo: AIModelInfo? = nil
        if let json = entity.value(forKey: "metadataJSON") as? String,
           let data = json.data(using: .utf8) {
            modelInfo = try? JSONDecoder().decode(AIModelInfo.self, from: data)
        }
        
        return ChatMessageModel(
            id: entity.value(forKey: "id") as? UUID ?? UUID(),
            sessionId: entity.value(forKey: "sessionId") as? UUID,
            role: role,
            text: entity.value(forKey: "content") as? String ?? "",
            createdAt: entity.value(forKey: "createdAt") as? Date ?? Date(),
            updatedAt: entity.value(forKey: "updatedAt") as? Date,
            inputMode: entity.value(forKey: "inputMode") as? String ?? "text",
            outputMode: entity.value(forKey: "outputMode") as? String,
            suggestedFoods: suggestedFoods,
            modelInfo: modelInfo,
            isError: entity.value(forKey: "isError") as? Bool ?? false
        )
    }
}
