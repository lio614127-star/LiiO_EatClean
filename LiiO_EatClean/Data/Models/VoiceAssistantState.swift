import Foundation

enum VoiceAssistantState: String {
    case disabled           // Setting off hoặc thiếu permission
    case idle               // Setting on, chưa start
    case voiceGateListening // Monitor audio level nhẹ (no SFSpeech)
    case wakeChecking       // Audio vượt ngưỡng, SFSpeech 2-3s
    case wakeDetected       // Wake phrase khớp, overlay hiện
    case commandListening   // Nghe câu hỏi/lệnh chính
    case processing         // Gửi AI pipeline
    case speaking           // TTS đang đọc response
    case error              // Lỗi permission/speech/audio
}
