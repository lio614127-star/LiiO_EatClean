import SwiftUI

struct SiriStyleVoiceOverlayV4: View {
    let target: VoiceOverlayTarget
    
    @State private var coordinator = VoiceOverlayRenderCoordinator.shared
    
    static var renderCounter = 0
    
    var body: some View {
        let _ = Self.logRender()
        
        if coordinator.activeTarget == target {
            ActiveSiriOverlayContent(target: target)
        } else {
            EmptyView()
        }
    }
    
    private static func logRender() {
        renderCounter += 1
        if renderCounter % 100 == 0 {
            print("[Perf] activeOverlayBodyRendered count=\(renderCounter)")
        }
    }
}

/// Isolated structure containing the actual UI layers.
/// This ensures high-frequency properties (@Environment GlobalVoiceAssistantManager)
/// are ONLY read and subviews are ONLY instantiated if the target IS ACTIVE.
fileprivate struct ActiveSiriOverlayContent: View {
    let target: VoiceOverlayTarget
    @Environment(GlobalVoiceAssistantManager.self) var voiceManager
    
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    
    var body: some View {
        ZStack {
            // Render appropriate views depending on continuous window mode
            if voiceManager.presentationMode == .minimized {
                VoiceOrbView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else if voiceManager.presentationMode == .expanded {
                
                // 1. Wave & Glow Ambient Layers (Allows touch traversal)
                Group {
                    SiriActivationWaveView(phase: voiceManager.siriOverlayPhase)
                    
                    SiriReactiveBorderView(
                        voiceManager: voiceManager,
                        isActive: voiceManager.siriOverlayPhase != .hidden && voiceManager.siriOverlayPhase != .activatingWave && voiceManager.siriOverlayPhase != .closing
                    )
                }
                .allowsHitTesting(false)
                
                // 2. Floating HUD Console Layer
                VStack(spacing: 0) {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            // Left cushion (keeps pill centered when controls are visible)
                            Spacer()
                                .frame(width: voiceManager.isAssistantPillVisible ? 68 : 0)
                            
                            Spacer()
                            
                            // Main Pill
                            SiriAssistantPillView(
                                name: voiceManager.settings.assistantName,
                                isVisible: voiceManager.isAssistantPillVisible,
                                phase: voiceManager.siriOverlayPhase
                            )
                            
                            Spacer()
                            
                            // Quick Actions Menu (Minimize / Close)
                            if voiceManager.isAssistantPillVisible {
                                HStack(spacing: 8) {
                                    // Minimize Widget Button
                                    Button(action: {
                                        voiceManager.minimizeOverlay()
                                    }) {
                                        Image(systemName: "arrow.down.right.and.arrow.up.left")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(.secondary)
                                            .frame(width: 28, height: 28)
                                            .background(.ultraThinMaterial)
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle().stroke(Color.primary.opacity(0.12), lineWidth: 0.5)
                                            )
                                    }
                                    
                                    // Terminate Session Button
                                    Button(action: {
                                        voiceManager.forceClose()
                                    }) {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(.secondary)
                                            .frame(width: 28, height: 28)
                                            .background(.ultraThinMaterial)
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle().stroke(Color.primary.opacity(0.12), lineWidth: 0.5)
                                            )
                                    }
                                }
                                .transition(.opacity.combined(with: .scale(scale: 0.8)))
                            } else {
                                Spacer()
                                    .frame(width: 0)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        if voiceManager.isTranscriptVisible {
                            SiriTranscriptBoxView(
                                text: voiceManager.overlayText,
                                liveTranscript: voiceManager.currentTranscript,
                                phase: voiceManager.siriOverlayPhase
                            )
                            .padding(.horizontal, 24)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.96)),
                                removal: .opacity.combined(with: .scale(scale: 0.98))
                            ))
                        }
                    }
                    .offset(x: dragOffset.width, y: 0)
                    .opacity(isDragging ? max(0.4, 1.0 - Double(abs(dragOffset.width) / 300.0)) : 1.0)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                // Restrict dragging to rightwards only
                                if gesture.translation.width > 0 {
                                    dragOffset = gesture.translation
                                    isDragging = true
                                }
                            }
                            .onEnded { gesture in
                                let velocity = gesture.predictedEndTranslation.width - gesture.translation.width
                                if gesture.translation.width > 120 || velocity > 250 {
                                    // Confirm minimization triggered by drag
                                    voiceManager.minimizeOverlay()
                                }
                                
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                    dragOffset = .zero
                                    isDragging = false
                                }
                            }
                    )
                    
                    Spacer() // Floating spacer remains untouched and transparently touch-traversable
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60) // Balanced perfectly under Dynamic Island / Notch
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: voiceManager.siriOverlayPhase)
        .animation(.spring(response: 0.45, dampingFraction: 0.72), value: voiceManager.presentationMode)
        .onAppear {
            print("[VoiceOverlay] Mounted ActiveSiriOverlayContent target=\(target.rawValue)")
        }
        .onDisappear {
            print("[VoiceOverlay] Unmounted ActiveSiriOverlayContent target=\(target.rawValue)")
        }
    }
}
