import SwiftUI

struct FloatingVoiceOverlay: View {
    @Environment(GlobalVoiceAssistantManager.self) var voiceManager
    var onNavigateToChat: () -> Void
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with Close button
            HStack {
                if voiceManager.state == .processing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "sparkles")
                        .foregroundColor(.green)
                }
                
                Text(titleForState)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            
            // Content
            VStack(spacing: 8) {
                switch voiceManager.state {
                case .wakeDetected:
                    wakeDetectedView
                case .commandListening:
                    listeningView
                case .processing:
                    processingView
                case .speaking:
                    speakingView
                case .error:
                    errorView
                default:
                    doneView
                }
            }
            .frame(maxWidth: .infinity)
            
            // Footer actions for Speaking/Done states
            if voiceManager.state == .speaking || voiceManager.state == .idle || voiceManager.state == .wakeChecking {
                 // No extra footer needed yet or handled inside views
            } else if voiceManager.state == .processing {
                 // Processing is enough
            } else {
                // Done state or others
                HStack {
                    Button(action: onNavigateToChat) {
                        Label("Xem trong AI Coach", systemName: "message.fill")
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .foregroundColor(.green)
                    
                    Spacer()
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onAppear {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }
    
    private var titleForState: String {
        switch voiceManager.state {
        case .wakeDetected: return "Sẵn sàng"
        case .commandListening: return "Đang nghe"
        case .processing: return "Đang xử lý"
        case .speaking: return voiceManager.settings.assistantName
        case .error: return "Lỗi"
        default: return voiceManager.settings.assistantName
        }
    }
    
    // MARK: - Subviews
    
    private var wakeDetectedView: some View {
        VStack(spacing: 4) {
            Text(voiceManager.settings.getWakeResponse())
                .font(.body)
                .multilineTextAlignment(.center)
            Text("Bạn nói đi...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var listeningView: some View {
        VStack(spacing: 12) {
            WaveformView(audioLevel: voiceManager.audioLevel)
                .frame(height: 30)
            
            if !voiceManager.currentTranscript.isEmpty {
                Text(voiceManager.currentTranscript)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            } else {
                Text("Đang lắng nghe...")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var processingView: some View {
        Text("Đang suy nghĩ...")
            .font(.body)
            .foregroundColor(.secondary)
            .padding(.vertical, 8)
    }
    
    private var speakingView: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView {
                Text(voiceManager.lastResponse)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            .frame(maxHeight: 100)
            
            Button(action: {
                // Should stop TTS and go back to idle/listening
                voiceManager.dismissOverlay()
            }) {
                Label("Dừng đọc", systemName: "stop.fill")
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .clipShape(Capsule())
            }
        }
    }
    
    private var errorView: some View {
        Text(voiceManager.errorMessage ?? "Đã có lỗi xảy ra")
            .font(.body)
            .foregroundColor(.red)
            .multilineTextAlignment(.center)
    }
    
    private var doneView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(voiceManager.lastResponse)
                .font(.body)
                .lineLimit(3)
        }
    }
}
