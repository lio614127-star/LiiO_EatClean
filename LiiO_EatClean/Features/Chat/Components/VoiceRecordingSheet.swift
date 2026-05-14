import SwiftUI

struct VoiceRecordingSheet: View {
    let dictationState: ChatDictationState
    let transcript: String
    let audioLevel: Float
    let onDismiss: () -> Void
    
    @State private var micScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.5
    
    private var statusText: String {
        switch dictationState {
        case .preparing, .listening:
            return "Đang nghe..."
        case .transcribing:
            return transcript.isEmpty ? "Đang nghe..." : transcript
        case .finalizing:
            return "Đang gửi..."
        case .completed:
            return "Hoàn tất!"
        case .failed(let message):
            return message
        case .idle:
            return ""
        }
    }
    
    private var textColor: Color {
        switch dictationState {
        case .failed:
            return .red
        case .preparing, .listening:
            return .secondary
        case .transcribing:
            return transcript.isEmpty ? .secondary : .primary
        default:
            return .primary
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Drag handle
            Capsule()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
            
            // Live transcript/status display
            Text(statusText)
                .font(.body.bold())
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .lineLimit(3)
                .animation(.easeOut(duration: 0.25), value: statusText)
            
            // Waveform visualization (Only show active when listening/transcribing)
            Group {
                if case .failed = dictationState {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 24))
                } else if dictationState == .finalizing {
                    ProgressView()
                        .tint(.green)
                } else {
                    WaveformView(audioLevel: audioLevel)
                }
            }
            .frame(height: 40)
            .padding(.horizontal, 20)
            
            // Mic button with glow
            ZStack {
                // Glow ring
                Circle()
                    .fill(Color.green.opacity(glowOpacity * Double(audioLevel + 0.3)))
                    .frame(width: 80, height: 80)
                    .blur(radius: 12)
                
                // Mic button (Tap to manual finalize / stop)
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .soft)
                    generator.impactOccurred()
                    onDismiss()
                }) {
                    Image(systemName: dictationState == .finalizing ? "checkmark" : "stop.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(
                            Circle().fill(dictationState == .finalizing ? Color.green : Color.red)
                        )
                        .scaleEffect(micScale)
                }
            }
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 230)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                micScale = 1.08
                glowOpacity = 0.7
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height > 50 {
                        // Swipe down to cancel manual
                        onDismiss()
                    }
                }
        )
    }
}
