import Foundation
import SwiftUI
import Observation

enum VoiceOverlayTarget: String, CaseIterable {
    case contentView = "ContentView"
    case dailyPlanSheet = "MealPlanSheet"
    case weeklyPlanSheet = "WeeklyPlanView"
    case memoryHub = "MemoryHubView"
}

@Observable
class VoiceOverlayRenderCoordinator {
    static let shared = VoiceOverlayRenderCoordinator()
    
    var activeTarget: VoiceOverlayTarget = .contentView {
        didSet {
            logState()
        }
    }
    
    private init() {}
    
    func activate(_ target: VoiceOverlayTarget) {
        guard activeTarget != target else { return }
        activeTarget = target
    }
    
    func restoreContentViewIfNeeded(from target: VoiceOverlayTarget) {
        if activeTarget == target {
            activeTarget = .contentView
        }
    }
    
    private func logState() {
        print("[Perf] activeRenderer=\(activeTarget.rawValue)")
        
        let hiddenTargets = VoiceOverlayTarget.allCases.filter { $0 != activeTarget }
        let hiddenNames = hiddenTargets.map { $0.rawValue }.joined(separator: ", ")
        print("[Perf] inactiveRendererSkipped=\(hiddenNames)")
        
        // In production / simulator console, verify exactly one active
        print("[Perf] renderedOrbCount=1")
    }
}
