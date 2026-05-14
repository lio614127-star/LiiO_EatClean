import Foundation

enum VoiceAssistantState: String {
    case disabled           // Setting off hoặc thiếu permission
    case idle               // Setting on, chưa start
    case voiceGateListening // Monitor audio level nhẹ (no SFSpeech)
    case wakeChecking       // Audio vượt ngưỡng, SFSpeech 2-3s
    case wakeDetected       // Wake phrase khớp, overlay hiện
    case speakingWakeResponse // Đang nói "Mình nghe đây"
    case commandListening   // Nghe câu hỏi/lệnh chính
    case processingCommand  // Gửi AI pipeline
    case speakingAIResponse // TTS đang đọc câu trả lời của AI
    case chatDictation      // Thu âm thủ công trong tab Chat
    case error              // Lỗi permission/speech/audio
    
    // Compatibility aliases if needed
    static let processing = VoiceAssistantState.processingCommand
    static let speaking = VoiceAssistantState.speakingAIResponse
}
