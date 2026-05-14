import SwiftUI

struct SiriStyleVoiceOverlayV3: View {
    @Environment(GlobalVoiceAssistantManager.self) var voiceManager
    
    var body: some View {
        ZStack {
            if voiceManager.siriOverlayPhase != .hidden {
                // Background Dim (Subtle)
                Color.black.opacity(voiceManager.siriOverlayPhase == .closing ? 0 : 0.2)
                    .ignoresSafeArea()
                    .onTapGesture {
                        voiceManager.dismissOverlay()
                    }
                
                // 1. Activation Wave Layer (The initial sweep)
                SiriActivationWaveView(phase: voiceManager.siriOverlayPhase)
                
                // 2. Persistent Reactive Border & Ambient Wave
                SiriReactiveBorderView(
                    audioLevel: voiceManager.audioLevel,
                    isActive: voiceManager.siriOverlayPhase != .hidden && voiceManager.siriOverlayPhase != .activatingWave && voiceManager.siriOverlayPhase != .closing
                )
                
                
                // 3. Top Assistant HUD (Stacking Pill & Transcript Box)
                VStack(spacing: 12) {
                    // Align properly beneath Dynamic Island
                    SiriAssistantPillView(
                        name: voiceManager.settings.assistantName,
                        isVisible: voiceManager.isAssistantPillVisible,
                        phase: voiceManager.siriOverlayPhase
                    )
                    .padding(.top, 8)
                    
                    if voiceManager.isTranscriptVisible {
                        SiriTranscriptBoxView(
                            text: voiceManager.overlayText,
                            liveTranscript: voiceManager.currentTranscript,
                            phase: voiceManager.siriOverlayPhase
                        )
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)),
                            removal: .opacity
                        ))
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60) // Offset from screen edge to sit perfectly below notch
            }
        }
        .animation(.easeInOut(duration: 0.3), value: voiceManager.siriOverlayPhase)
        .animation(.easeInOut(duration: 0.3), value: voiceManager.state)
        .onAppear {
            print("[Overlay] V3 mounted")
        }
        .onChange(of: voiceManager.isActivationWaveVisible) { _, visible in
            print("[Overlay] wave visible \(visible)")
        }
        .onChange(of: voiceManager.isAssistantPillVisible) { _, visible in
            print("[Overlay] pill visible \(visible)")
        }
        .onChange(of: voiceManager.isTranscriptVisible) { _, visible in
            print("[Overlay] transcript box visible \(visible)")
        }
        .onChange(of: voiceManager.siriOverlayPhase) { _, phase in
            print("[Overlay] phase \(phase.rawValue)")
        }
        .onChange(of: voiceManager.overlayText) { _, text in
            print("[Overlay] text updated = '\(text.prefix(30))...'")
        }
    }
}
