import Foundation

enum ChatDictationState: Equatable {
    case idle
    case preparing
    case listening
    case transcribing
    case finalizing
    case completed
    case failed(String)
    
    var isActive: Bool {
        switch self {
        case .preparing, .listening, .transcribing, .finalizing:
            return true
        default:
            return false
        }
    }
}
