import SwiftUI

struct VoiceRecordingSheet: View {
    let speechService: SpeechRecognitionService
    let onDismiss: () -> Void
    let onConfirm: (String) -> Void
    
    @State private var micScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.5
    
    var body: some View {
        VStack(spacing: 20) {
            // Drag handle
            Capsule()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
            
            // Live transcript display
            Text(speechService.transcript.isEmpty ? "Đang nghe..." : speechService.transcript)
                .font(.body)
                .foregroundColor(speechService.transcript.isEmpty ? .secondary : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .lineLimit(3)
                .animation(.easeOut(duration: 0.2), value: speechService.transcript)
            
            // Waveform visualization
            WaveformView(audioLevel: speechService.audioLevel)
                .frame(height: 40)
                .padding(.horizontal, 20)
            
            // Mic button with glow
            ZStack {
                // Glow ring
                Circle()
                    .fill(Color.green.opacity(glowOpacity * Double(speechService.audioLevel + 0.3)))
                    .frame(width: 80, height: 80)
                    .blur(radius: 12)
                
                // Mic button
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .soft)
                    generator.impactOccurred()
                    onDismiss()
                }) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(
                            Circle().fill(Color.red)
                        )
                        .scaleEffect(micScale)
                }
            }
            .padding(.bottom, 16)
            
            // Error display
            if let error = speechService.error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                micScale = 1.1
                glowOpacity = 0.8
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height > 50 {
                        // Swipe down to cancel
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.warning)
                        onDismiss()
                    }
                }
        )
    }
}
