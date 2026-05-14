import SwiftUI

struct SiriReactiveBorderView: View {
    let voiceManager: GlobalVoiceAssistantManager
    let isActive: Bool
    
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        // Log high frequency subscriber correctly for perf metrics
        let audioLevel = voiceManager.audioLevel
        let intensity = min(max(CGFloat(audioLevel) * 8.0, 0.2), 1.0)
        let calculatedOpacity = isActive ? 0.35 + intensity * 0.45 : 0.25
        let lineWidth = 2.0 + intensity * 4.0
        let blurRadius = 8.0 + intensity * 12.0
        
        ZStack {
            if isActive {
                // Main Glowing Boundary
                RoundedRectangle(cornerRadius: 46)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "00FFD1"), // mint
                                Color(hex: "00B2FF"), // cyan
                                Color(hex: "7000FF"), // purple/blue
                                Color(hex: "FF00C7"), // pink
                                Color(hex: "00FFD1")  // back to mint
                            ]),
                            center: .center,
                            angle: .degrees(rotationAngle)
                        ),
                        lineWidth: lineWidth
                    )
                    .opacity(Double(calculatedOpacity))
                    .blur(radius: blurRadius)
                    .blendMode(.screen)
                    .padding(2)
                    .ignoresSafeArea()
                    .onAppear {
                        withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                            rotationAngle = 360
                        }
                    }
                
                // High Frequency Definition Edge
                RoundedRectangle(cornerRadius: 46)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "00FFD1"),
                                Color(hex: "00B2FF"),
                                Color(hex: "7000FF"),
                                Color(hex: "FF00C7"),
                                Color(hex: "00FFD1")
                            ]),
                            center: .center,
                            angle: .degrees(rotationAngle)
                        ),
                        lineWidth: 1.2
                    )
                    .opacity(Double(calculatedOpacity * 0.8))
                    .blur(radius: 1.5)
                    .blendMode(.plusLighter)
                    .padding(2)
                    .ignoresSafeArea()
            }
        }
        .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.72), value: audioLevel)
        .allowsHitTesting(false)
    }
}
