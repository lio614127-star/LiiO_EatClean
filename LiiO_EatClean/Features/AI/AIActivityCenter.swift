import Foundation
import SwiftUI
import Observation

enum AIActivityStatus: Equatable, Codable {
    case thinking
    case processing(String)
    case streaming(String)
    case completed
    case failed(String)
    case swapping(String) // For API key swaps
}

struct AIActivity: Identifiable, Equatable, Codable {
    let id: UUID
    let featureSource: String
    var modelName: String
    var provider: String
    var status: AIActivityStatus
    var progressText: String
    var keyName: String?
    var keyTier: String? // "FREE" or "PAID"
    var subTasks: [String] = [] // List of tasks in this batch
    var isInternal: Bool = false // If true, hide from global overlay
    let startedAt: Date
    
    var isFinished: Bool {
        switch status {
        case .completed, .failed: return true
        default: return false
        }
    }
}

@Observable
class AIActivityCenter {
    static let shared = AIActivityCenter()
    
    var activities: [AIActivity] = []
    
    private init() {}
    
    @MainActor
    func startTask(id: UUID = UUID(), feature: String, model: String, provider: String, initialStatus: String, keyName: String? = nil, keyTier: String? = nil, subTasks: [String] = [], isInternal: Bool = false) -> UUID {
        let activity = AIActivity(
            id: id,
            featureSource: feature,
            modelName: model,
            provider: provider,
            status: .thinking,
            progressText: initialStatus,
            keyName: keyName,
            keyTier: keyTier,
            subTasks: subTasks,
            isInternal: isInternal,
            startedAt: Date()
        )
        activities.append(activity)
        return id
    }
    
    @MainActor
    func updateTask(id: UUID, status: AIActivityStatus, model: String? = nil, provider: String? = nil, progressText: String? = nil) {
        if let index = activities.firstIndex(where: { $0.id == id }) {
            if let model = model { activities[index].modelName = model }
            if let provider = provider { activities[index].provider = provider }
            if let progressText = progressText { activities[index].progressText = progressText }
            activities[index].status = status
            
            // Auto-remove completed/failed tasks after a delay
            if activities[index].isFinished {
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    await MainActor.run {
                        self.removeTask(id: id)
                    }
                }
            }
        }
    }
    
    @MainActor
    func removeTask(id: UUID) {
        activities.removeAll { $0.id == id }
    }
}
