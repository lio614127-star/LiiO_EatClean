---
phase: 30
wave: 3
title: "Floating Voice Overlay UI"
depends_on: [30-PLAN-2]
requirements: [VOICE-02, VOICE-04]
files_modified:
  - LiiO_EatClean/Features/Voice/FloatingVoiceOverlay.swift
  - LiiO_EatClean/Features/Voice/VoiceOverlayViewModel.swift
  - LiiO_EatClean/Features/Chat/Components/WaveformView.swift
  - LiiO_EatClean/ContentView.swift
autonomous: true
---

# Plan 3: Floating Voice Overlay UI

## Goal
Tạo giao diện overlay nổi khi phát hiện wake phrase — hiển thị trạng thái nghe, xử lý, và trả lời ngay trên tab hiện tại mà không chuyển tab.

## Tasks

<task id="3.1" type="execute">
<title>Create FloatingVoiceOverlay view</title>
<read_first>
- LiiO_EatClean/Features/Chat/Components/VoiceRecordingSheet.swift (existing voice UI)
- LiiO_EatClean/Features/Chat/Components/WaveformView.swift (existing waveform)
- .planning/phases/30-voice-assistant/30-CONTEXT.md (Section 7: Floating Voice Overlay)
</read_first>
<action>
Create `LiiO_EatClean/Features/Voice/FloatingVoiceOverlay.swift`:

Overlay hiển thị dạng capsule card ở bottom, với 5 trạng thái:

A. Wake Detected:
- Icon: 🎙️ pulse animation
- Title: getWakeResponse() từ settings (ví dụ "Mình nghe đây.")
- Subtitle: "Bạn nói đi…"

B. Listening (commandListening):
- WaveformView animation
- Live transcript hiển thị realtime
- Timer badge nhỏ hiện countdown (15s max)

C. Processing:
- Loading spinner
- Text: "Đang suy nghĩ…"

D. Speaking (TTS):
- AI response text (scrollable nếu dài)
- Nút [Dừng đọc] — calls ttsService.stop()

E. Done:
- Response text (brief)
- Nút [Xem trong AI Coach] — navigates to AI Coach tab
- Auto-dismiss sau 5 giây nếu không interact

Style:
- `.ultraThinMaterial` background
- `RoundedRectangle(cornerRadius: 24)`
- Padding 16
- Max height: 220pt
- Shadow: `.shadow(radius: 12)`
- Nút X ở góc phải trên
- Slide-up animation khi appear
- Slide-down animation khi dismiss
- Haptic feedback (UIImpactFeedbackGenerator.soft) khi wake detected

```swift
struct FloatingVoiceOverlay: View {
    @Environment(GlobalVoiceAssistantManager.self) var voiceManager
    var onNavigateToChat: () -> Void
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Close button
            HStack {
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            
            // Content based on state
            switch voiceManager.state {
            case .wakeDetected:
                wakeDetectedView
            case .commandListening:
                listeningView
            case .processing:
                processingView
            case .speaking:
                speakingView
            default:
                doneView
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .frame(maxHeight: 220)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(radius: 12)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
```
</action>
<acceptance_criteria>
- File `FloatingVoiceOverlay.swift` exists in `Features/Voice/`
- Overlay uses `.ultraThinMaterial` with `cornerRadius: 24`
- 5 distinct states rendered: wakeDetected, listening, processing, speaking, done
- Close button (X) dismisses overlay
- "Xem trong AI Coach" button calls `onNavigateToChat`
- Wake detected state shows `settings.getWakeResponse()` text
- Listening state shows WaveformView + live transcript
- Speaking state shows "Dừng đọc" button
- Slide-up/down animation via `.transition(.move(edge: .bottom))`
</acceptance_criteria>
</task>

<task id="3.2" type="execute">
<title>Integrate overlay into ContentView</title>
<read_first>
- LiiO_EatClean/ContentView.swift (main tab view)
- LiiO_EatClean/Features/Voice/FloatingVoiceOverlay.swift (from task 3.1)
</read_first>
<action>
In `ContentView.swift`:

1. Access `@Environment(GlobalVoiceAssistantManager.self) var voiceManager`
2. Add overlay as `.overlay(alignment: .bottom)` on top of TabView
3. Show overlay when `voiceManager.state` is one of: `.wakeDetected`, `.commandListening`, `.processing`, `.speaking`
4. Animate with `withAnimation(.spring(response: 0.4))`

```swift
var body: some View {
    TabView(selection: $selectedTab) {
        // ... existing tabs
    }
    .overlay(alignment: .bottom) {
        if shouldShowVoiceOverlay {
            FloatingVoiceOverlay(
                onNavigateToChat: {
                    selectedTab = .aiCoach
                    voiceManager.dismissOverlay()
                },
                onDismiss: {
                    voiceManager.dismissOverlay()
                }
            )
            .animation(.spring(response: 0.4), value: voiceManager.state)
        }
    }
}

var shouldShowVoiceOverlay: Bool {
    [.wakeDetected, .commandListening, .processing, .speaking].contains(voiceManager.state)
}
```
</action>
<acceptance_criteria>
- FloatingVoiceOverlay appears as overlay on ContentView TabView
- Overlay shows for states: wakeDetected, commandListening, processing, speaking
- "Xem trong AI Coach" navigates to AI Coach tab
- Dismiss button hides overlay and resets state
- Overlay does NOT auto-switch tabs
- Spring animation on state changes
</acceptance_criteria>
</task>

## Verification
- Build succeeds with overlay integration
- Overlay appears over current tab content without obscuring full UI
- All 5 visual states render correctly

## Must Haves
- Floating overlay NOT full-screen — max 220pt height
- No auto-switch to AI Coach tab
- Close button always visible
- Slide-up animation on appear
