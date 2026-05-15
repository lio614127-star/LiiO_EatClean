import Foundation
import SwiftUI

enum AppTab: Int, Codable {
    case home = 0
    case meals = 1
    case progress = 2
    case profile = 3
    case chat = 4
}

enum AppAction {
    case switchTab(AppTab)
    case addWeight(Double, Date)
    case setProgressRange(TimeRange)
    case openProgressMetric(ProgressTab)
}

@MainActor
class AppActionRouter {
    static let shared = AppActionRouter()
    private let userRepository: UserRepositoryProtocol
    
    init(userRepository: UserRepositoryProtocol = UserRepository()) {
        self.userRepository = userRepository
    }
    
    func execute(_ action: AppAction) async throws {
        print("[AppAction 1] executing action=\(action)")
        switch action {
        case .switchTab(let tab):
            // Post Notification to trigger tab switch in ContentView
            NotificationCenter.default.post(name: .appSwitchTab, object: tab.rawValue)
            
        case .addWeight(let value, let date):
            let entry = WeightEntryModel(id: UUID(), date: date, weight: value)
            try await userRepository.saveWeightEntry(entry)
            // Let progress views know data has mutated
            NotificationCenter.default.post(name: .appWeightDidChange, object: nil)
            
        case .setProgressRange(let range):
            NotificationCenter.default.post(name: .appSetProgressRange, object: range.rawValue)
            
        case .openProgressMetric(let metric):
            NotificationCenter.default.post(name: .appSetProgressMetric, object: metric.rawValue)
        }
        print("[AppAction 2] completed action=\(action)")
    }
}

extension Notification.Name {
    static let appSwitchTab = Notification.Name("AppActionRouter.appSwitchTab")
    static let appWeightDidChange = Notification.Name("AppActionRouter.appWeightDidChange")
    static let appSetProgressRange = Notification.Name("AppActionRouter.appSetProgressRange")
    static let appSetProgressMetric = Notification.Name("AppActionRouter.appSetProgressMetric")
}
