import SwiftUI

struct SiriTranscriptBoxView: View {
    let text: String
    let liveTranscript: String
    let phase: SiriOverlayPhase
    
    var body: some View {
        VStack(spacing: 8) {
            switch phase {
            case .wakePrompt:
                Text(text)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
                
            case .listening:
                if liveTranscript.isEmpty {
                    Text("Bạn nói đi...")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                } else {
                    Text(liveTranscript)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                }
                
            case .processing:
                Text("Đang xử lý...")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
                
            case .speaking:
                Text(text)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
                    
            default:
                if !text.isEmpty {
                    Text(text)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(maxWidth: 320) // Limit width to stay readable card-style
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 10, y: 5)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: text)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: liveTranscript)
    }
}
