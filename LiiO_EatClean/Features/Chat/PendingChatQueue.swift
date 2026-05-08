import Foundation
import CoreData

struct PendingMessage: Identifiable, Equatable {
    let id: UUID
    let text: String
    let createdAt: Date
    let conversationID: UUID
    var status: PendingStatus
    
    enum PendingStatus: String {
        case pending = "pending"
        case sending = "sending"
        case failed = "failed"
    }
}

@Observable
class PendingChatQueue {
    static let shared = PendingChatQueue()
    
    var pendingMessages: [PendingMessage] = []
    
    private let context: NSManagedObjectContext
    
    private init() {
        self.context = PersistenceController.shared.container.viewContext
        loadPendingMessages()
        observeConnectivity()
    }
    
    // MARK: - Persistence
    
    private func loadPendingMessages() {
        let request: NSFetchRequest<PendingChatMessage> = PendingChatMessage.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PendingChatMessage.createdAt, ascending: true)]
        
        if let entities = try? context.fetch(request) {
            pendingMessages = entities.map { entity in
                PendingMessage(
                    id: entity.id ?? UUID(),
                    text: entity.text ?? "",
                    createdAt: entity.createdAt ?? Date(),
                    conversationID: entity.conversationID ?? UUID(),
                    status: PendingMessage.PendingStatus(rawValue: entity.status ?? "pending") ?? .pending
                )
            }
        }
    }
    
    // MARK: - Queue Management
    
    func enqueue(text: String, conversationID: UUID) {
        let message = PendingMessage(
            id: UUID(),
            text: text,
            createdAt: Date(),
            conversationID: conversationID,
            status: .pending
        )
        pendingMessages.append(message)
        
        // Persist to CoreData
        context.perform {
            let entity = PendingChatMessage(context: self.context)
            entity.id = message.id
            entity.text = message.text
            entity.createdAt = message.createdAt
            entity.conversationID = message.conversationID
            entity.status = "pending"
            try? self.context.save()
        }
    }
    
    func markSending(id: UUID) {
        if let index = pendingMessages.firstIndex(where: { $0.id == id }) {
            pendingMessages[index].status = .sending
            updateEntity(id: id, status: "sending")
        }
    }
    
    func markFailed(id: UUID) {
        if let index = pendingMessages.firstIndex(where: { $0.id == id }) {
            pendingMessages[index].status = .failed
            updateEntity(id: id, status: "failed")
        }
    }
    
    func remove(id: UUID) {
        pendingMessages.removeAll { $0.id == id }
        deleteEntity(id: id)
    }
    
    // MARK: - Auto-Retry on Reconnect
    
    private func observeConnectivity() {
        Task { @MainActor in
            var wasOffline = !NetworkMonitor.shared.isConnected
            while true {
                try? await Task.sleep(for: .seconds(2))
                let isNowOnline = NetworkMonitor.shared.isConnected
                if wasOffline && isNowOnline {
                    await retryPending()
                }
                wasOffline = !isNowOnline
            }
        }
    }
    
    func retryPending() async {
        let pending = pendingMessages.filter { $0.status == .pending || $0.status == .failed }
        for message in pending {
            markSending(id: message.id)
            NotificationCenter.default.post(
                name: .pendingChatReadyToSend,
                object: nil,
                userInfo: ["message": message]
            )
        }
    }
    
    // MARK: - CoreData Helpers
    
    private func updateEntity(id: UUID, status: String) {
        context.perform {
            let request: NSFetchRequest<PendingChatMessage> = PendingChatMessage.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            if let entity = try? self.context.fetch(request).first {
                entity.status = status
                try? self.context.save()
            }
        }
    }
    
    private func deleteEntity(id: UUID) {
        context.perform {
            let request: NSFetchRequest<PendingChatMessage> = PendingChatMessage.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            if let entity = try? self.context.fetch(request).first {
                self.context.delete(entity)
                try? self.context.save()
            }
        }
    }
}

extension Notification.Name {
    static let pendingChatReadyToSend = Notification.Name("pendingChatReadyToSend")
}
