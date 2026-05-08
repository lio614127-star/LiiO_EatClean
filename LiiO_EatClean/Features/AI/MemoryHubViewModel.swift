import Foundation
import SwiftUI
import Observation

@Observable
class MemoryHubViewModel {
    let memoryRepository: AIMemoryRepositoryProtocol
    let userRepository: UserRepositoryProtocol
    
    var currentMemory: UserProfileMemory = UserProfileMemory()
    var userProfile: UserModel? = nil
    var showGuidedSetup: Bool = false
    
    init(memoryRepository: AIMemoryRepositoryProtocol = AIMemoryRepository.shared,
         userRepository: UserRepositoryProtocol = UserRepository()) {
        self.memoryRepository = memoryRepository
        self.userRepository = userRepository
    }
    
    @MainActor
    func loadData() async {
        do {
            self.currentMemory = try await memoryRepository.fetchMemory()
            self.userProfile = try await userRepository.fetchUser()
        } catch {
            print("❌ Failed to load memory hub data: \(error)")
        }
    }
    
    var hasMemoryData: Bool {
        return currentMemory.hasContent
    }
}
