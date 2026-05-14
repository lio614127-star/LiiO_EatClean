import Foundation

enum VoiceProcessingState: Equatable {
    case idle
    case buildingContext
    case sendingToAI
    case waitingForAI
    case receivedResponse
    case speaking
    case failed(String)
    
    var isProcessing: Bool {
        switch self {
        case .buildingContext, .sendingToAI, .waitingForAI:
            return true
        default:
            return false
        }
    }
}
