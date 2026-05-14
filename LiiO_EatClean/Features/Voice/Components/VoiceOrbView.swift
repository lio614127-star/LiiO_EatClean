import SwiftUI

struct VoiceOrbView: View {
    @Environment(GlobalVoiceAssistantManager.self) var voiceManager
    
    // Local layout tracking for lag-free dragging
    @State private var localY: CGFloat? = nil
    @GestureState private var dragTranslation = CGSize.zero
    
    var body: some View {
        let isDragging = dragTranslation != .zero
        
        GeometryReader { geometry in
            let basePosition = localY ?? voiceManager.orbYPosition
            let currentY = clampY(basePosition + dragTranslation.height, in: geometry.size.height)
            
            // Tactile visual pullout physics
            let pulloutOffset = dragTranslation.width > 0 ? 0 : dragTranslation.width
            
            ZStack {
                // 1. Ambient pulsing based on frequency
                OrbAmbientPulseView(voiceManager: voiceManager, isDragging: isDragging)
                
                // 2. Premium core & rotating loaders
                OrbCoreView(voiceManager: voiceManager, isDragging: isDragging)
                
                // 3. Dynamic status tooltip bubble (auto-fading)
                OrbMiniStatusBubble(voiceManager: voiceManager, isDragging: isDragging)
            }
            .frame(width: 56, height: 56)
            .contentShape(Circle())
            .allowsHitTesting(true)
            .gesture(
                DragGesture(minimumDistance: 4)
                    .updating($dragTranslation) { value, state, _ in
                        state = value.translation
                    }
                    .onEnded { value in
                        let finalY = clampY(basePosition + value.translation.height, in: geometry.size.height)
                        localY = finalY
                        voiceManager.orbYPosition = finalY
                        
                        // Expansion threshold: -60pt swipe left
                        if value.translation.width < -60 {
                            voiceManager.expandOverlay()
                        } else {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
            )
            .onTapGesture {
                voiceManager.expandOverlay()
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
            // APPLIED LAST: Positioning
            .position(x: geometry.size.width - 28 + pulloutOffset, y: currentY)
            // Only animate snaps (when ending gesture returns dragTranslation to zero)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: dragTranslation == .zero)
        }
        .ignoresSafeArea()
        .onAppear {
            // Core logging required by the USER
            print("[Perf] renderedOrbCount=1")
        }
    }
    
    private func clampY(_ y: CGFloat, in height: CGFloat) -> CGFloat {
        max(120, min(height - 120, y))
    }
}

// MARK: - Sub-Components

struct OrbAmbientPulseView: View {
    let voiceManager: GlobalVoiceAssistantManager
    let isDragging: Bool
    
    var body: some View {
        let state = voiceManager.state
        let audioLevel = voiceManager.audioLevel
        
        // Surgically disabled during dragging to save huge GPU overhead
        if isDragging {
            Circle()
                .fill(Color(hex: "00FFD1").opacity(0.3))
                .frame(width: 56, height: 56)
        } else {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "00FFD1").opacity(0.6), Color(hex: "00B2FF").opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blur(radius: 6)
                .scaleEffect(pulseScale(state: state, audioLevel: audioLevel))
                .opacity(pulseOpacity(state: state))
                .animation(.easeOut(duration: 0.15), value: audioLevel)
        }
    }
    
    private func pulseScale(state: VoiceAssistantState, audioLevel: Float) -> CGFloat {
        if state == .commandListening {
            let norm = CGFloat(max(0.0, min(1.0, (audioLevel + 50.0) / 50.0)))
            return 1.1 + (norm * 0.4) // Scale up to 1.5 max
        } else if state == .speakingAIResponse {
            return 1.2
        }
        return 1.0
    }
    
    private func pulseOpacity(state: VoiceAssistantState) -> Double {
        if state == .commandListening { return 0.8 }
        if state == .processingCommand { return 0.5 }
        if state == .error { return 0.3 }
        return 0.2
    }
}

struct OrbCoreView: View {
    let voiceManager: GlobalVoiceAssistantManager
    let isDragging: Bool
    
    var body: some View {
        let state = voiceManager.state
        
        ZStack {
            // Glassmorphic Inner Core
            Circle()
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.16), radius: 8, x: -3, y: 3)
                .overlay(
                    Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                )
            
            // Loading/Processing rings (Disabled during drag to guarantee 120fps smoothness)
            if state == .processingCommand && !isDragging {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "00FFD1"), Color(hex: "00B2FF")],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 2
                    )
                    .scaleEffect(1.2)
                    .phaseAnimator([0.8, 1.3]) { content, phase in
                        content
                            .scaleEffect(phase)
                            .opacity(phase == 1.3 ? 0 : 0.8)
                    } animation: { _ in
                        .easeInOut(duration: 1.2).repeatForever(autoreverses: false)
                    }
            }
            
            // State Icons
            Group {
                if state == .processingCommand {
                    ProgressView()
                        .tint(.primary)
                        .scaleEffect(0.8)
                } else if state == .speakingAIResponse {
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
                            content.scaleEffect(y: isDragging ? 1.0 : phase)
                        } animation: { _ in
                            .easeInOut(duration: 0.4).repeatForever(autoreverses: true)
                        }
                } else if state == .commandListening {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: "00FFD1"))
                } else if state == .error {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.red)
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
    }
}

struct OrbMiniStatusBubble: View {
    let voiceManager: GlobalVoiceAssistantManager
    let isDragging: Bool
    
    @State private var visibleText: String? = nil
    @State private var opacity: Double = 0.0
    
    var body: some View {
        let state = voiceManager.state
        let processingState = voiceManager.processingState
        
        Group {
            if let text = visibleText, !isDragging {
                Text(text)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.15), radius: 4)
                    .offset(x: -74) // Placed to the left of the orb
                    .opacity(opacity)
            }
        }
        .onChange(of: computedStatusText(state: state, processingState: processingState)) { oldValue, newValue in
            guard let newValue = newValue else {
                withAnimation(.easeOut(duration: 0.3)) {
                    opacity = 0.0
                }
                return
            }
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                visibleText = newValue
                opacity = 1.0
            }
            
            // Dismiss bubble automatically after 2.8 seconds
            Task {
                try? await Task.sleep(nanoseconds: 2_800_000_000)
                if computedStatusText(state: state, processingState: processingState) == newValue {
                    withAnimation(.easeOut(duration: 0.4)) {
                        opacity = 0.0
                    }
                }
            }
        }
    }
    
    private func computedStatusText(state: VoiceAssistantState, processingState: VoiceProcessingState) -> String? {
        switch state {
        case .commandListening:
            return "Đang nghe..."
        case .processingCommand:
            switch processingState {
            case .buildingContext: return "Chuẩn bị..."
            case .sendingToAI, .waitingForAI: return "Đang xử lý..."
            case .receivedResponse: return "Đã hiểu!"
            default: return "Đang xử lý..."
            }
        case .speakingAIResponse:
            return "Đang trả lời..."
        case .error:
            return "Lỗi xử lý!"
        default:
            return nil
        }
    }
}
