import SwiftUI

struct VoiceOrbView: View {
    @Environment(GlobalVoiceAssistantManager.self) var voiceManager
    @GestureState private var dragOffset = CGFloat.zero
    
    var body: some View {
        GeometryReader { geometry in
            let currentY = max(120, min(geometry.size.height - 120, voiceManager.orbYPosition + dragOffset))
            
            ZStack {
                // Outer Ambient Breathing Glow
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "00FFD1").opacity(0.6), Color(hex: "00B2FF").opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blur(radius: 6)
                    .scaleEffect(1.1)
                    .opacity(voiceManager.state == .commandListening ? 0.8 : 0.3)
                
                // Processing Ring (Hidden unless loading)
                if voiceManager.state == .processingCommand {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "00FFD1"), Color(hex: "00B2FF")],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 2
                        )
                        .scaleEffect(1.3)
                        .opacity(0.6)
                        .phaseAnimator([0.8, 1.4]) { content, phase in
                            content
                                .scaleEffect(phase)
                                .opacity(phase == 1.4 ? 0 : 0.7)
                        } animation: { phase in
                            .easeInOut(duration: 1.2).repeatForever(autoreverses: false)
                        }
                }
                
                // Glassmorphic Inner Core
                Circle()
                    .fill(.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(0.16), radius: 8, x: -3, y: 3)
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                    )
                
                // Adaptive Inner Icon
                Group {
                    if voiceManager.state == .processingCommand {
                        ProgressView()
                            .tint(.primary)
                            .scaleEffect(0.8)
                    } else if voiceManager.state == .speakingAIResponse || voiceManager.state == .speaking {
                        Image(systemName: "waveform")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "00FFD1"), Color(hex: "00B2FF")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .phaseAnimator([1.0, 1.3]) { content, phase in
                                content.scaleEffect(y: phase)
                            } animation: { _ in
                                .easeInOut(duration: 0.4).repeatForever(autoreverses: true)
                            }
                    } else if voiceManager.state == .commandListening {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "00FFD1"), Color(hex: "00B2FF")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
            }
            .frame(width: 56, height: 56) // Expanded visible interaction zone
            .contentShape(Circle())
            .allowsHitTesting(true) // Explicitly accept interactions ONLY on the orb itself
            // 1. GESTURES BOUND DIRECTLY TO SPHERE BOUNDS BEFORE .POSITION EXPANDS CONTAINER
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation.height
                    }
                    .onEnded { value in
                        let rawY = voiceManager.orbYPosition + value.translation.height
                        voiceManager.orbYPosition = max(120, min(geometry.size.height - 120, rawY))
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
            )
            .onTapGesture {
                voiceManager.expandOverlay()
            }
            .onLongPressGesture(minimumDuration: 0.5) {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
            .contextMenu {
                Button {
                    voiceManager.expandOverlay()
                } label: {
                    Label("Mở Trợ Lý", systemImage: "arrow.up.backward.and.arrow.down.forward")
                }
                
                Button {
                    voiceManager.forceClose()
                } label: {
                    Label("Tắt Trợ Lý", systemImage: "xmark.circle")
                }
                
                Divider()
                
                Button {
                    voiceManager.forceClose()
                    NotificationCenter.default.post(name: NSNotification.Name("AskAICoachAboutMeal"), object: nil)
                } label: {
                    Label("Mở AI Coach Chat", systemImage: "message.badge.filled.fill")
                }
            }
            .animation(.interactiveSpring(), value: dragOffset)
            // 2. POSITIONING APPLIED ABSOLUTELY LAST
            .position(x: geometry.size.width - 28, y: currentY)
        }
        .allowsHitTesting(false) // Prevent whole-screen hit-testing interception
        .ignoresSafeArea()
    }
}
