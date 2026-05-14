import SwiftUI

struct SiriActivationWaveView: View {
    let phase: SiriOverlayPhase
    @State private var waveOffset: CGFloat = 1.0
    @State private var opacity: Double = 0
    @State private var energyScale: CGFloat = 0.8
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Layer 1: Base Glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "00FFD1").opacity(0.4),
                                Color(hex: "00B2FF").opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: geo.size.width * 0.8
                        )
                    )
                    .frame(width: geo.size.width * 1.5, height: geo.size.width * 1.5)
                    .offset(y: waveOffset * geo.size.height + 100)
                    .blur(radius: 60)
                
                // Layer 2: Core Wave
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "00FFD1"),
                                Color(hex: "00B2FF"),
                                Color(hex: "7000FF"),
                                Color(hex: "FF00C7")
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * 1.2, height: 120)
                    .blur(radius: 30)
                    .offset(y: waveOffset * geo.size.height)
                    .scaleEffect(x: energyScale, y: 1.0)
                
                // Layer 3: Particle/Energy Glow (Additive)
                Ellipse()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: geo.size.width * 0.8, height: 40)
                    .blur(radius: 20)
                    .offset(y: waveOffset * geo.size.height - 10)
                    .blendMode(.plusLighter)
            }
            .opacity(opacity)
            .ignoresSafeArea()
            .onAppear {
                if phase == .activatingWave {
                    triggerAnimation()
                }
            }
            .onChange(of: phase) { old, new in
                if new == .activatingWave {
                    triggerAnimation()
                }
            }
        }
        .allowsHitTesting(false)
    }
    
    private func triggerAnimation() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        waveOffset = 1.0
        opacity = 1.0
        energyScale = 0.5
        
        withAnimation(.spring(response: 0.38, dampingFraction: 0.68)) {
            waveOffset = -0.2
            energyScale = 1.2
        }
        
        withAnimation(.easeIn(duration: 0.24).delay(0.32)) {
            opacity = 0
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
