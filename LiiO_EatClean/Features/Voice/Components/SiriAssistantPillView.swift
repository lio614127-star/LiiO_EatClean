import SwiftUI

struct SiriAssistantPillView: View {
    let name: String
    let isVisible: Bool
    let phase: SiriOverlayPhase
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "00FFD1"), Color(hex: "00B2FF")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text(name)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 6, y: 3)
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.9)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isVisible)
    }
}
