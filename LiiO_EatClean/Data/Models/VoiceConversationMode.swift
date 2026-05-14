import Foundation

enum VoiceConversationMode: String, Codable {
    case inactive           // Assistant not activated. Standard wake listening active.
    case activating         // Just matched wake phrase, displaying activation animation.
    case activeExpanded     // Overlay displayed at full size on top.
    case activeMinimized    // Collapsed to the Sidebar Orb floating widget.
    case listening          // Actively listening to user speech input.
    case processing         // Remote AI orchestration execution in progress.
    case speaking          // TTS speaking the AI feedback output.
    case paused            // Conversation suspended briefly.
}
