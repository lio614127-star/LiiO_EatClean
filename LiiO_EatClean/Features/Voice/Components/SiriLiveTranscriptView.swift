import SwiftUI

struct SiriLiveTranscriptView: View {
    let text: String
    let liveTranscript: String
    let phase: SiriOverlayPhase
    
    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 8) {
                if !text.isEmpty {
                    Text(text)
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .transition(.blurReplace.combined(with: .opacity))
                }
                
                if !liveTranscript.isEmpty {
                    Text(liveTranscript)
                        .font(.system(size: 18, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .transition(.opacity)
                } else if phase == .listening {
                    Text("Bạn nói đi...")
                        .font(.system(size: 18, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.6))
                        .transition(.opacity)
                } else if phase == .processing {
                    Text("Đang xử lý...")
                        .font(.system(size: 18, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.8))
                        .transition(.opacity)
                }
            }
            .padding(.top, 110) // Below the Pill
            .padding(.horizontal, 24)
            .animation(.easeInOut(duration: 0.3), value: text)
            .animation(.easeInOut(duration: 0.2), value: liveTranscript)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .ignoresSafeArea()
    }
}
