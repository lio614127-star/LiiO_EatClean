---
phase: 30
wave: 2
title: "GlobalVoiceAssistantManager — State Machine & Audio Gate"
depends_on: [30-PLAN-1]
requirements: [VOICE-01, VOICE-02, VOICE-04]
files_modified:
  - LiiO_EatClean/Services/GlobalVoiceAssistantManager.swift
  - LiiO_EatClean/Services/SpeechRecognitionService.swift
  - LiiO_EatClean/LiiO_EatCleanApp.swift
autonomous: true
---

# Plan 2: GlobalVoiceAssistantManager — State Machine & Audio Gate

## Goal
Tạo trình quản lý Voice Assistant cấp ứng dụng với state machine, audio level gate, và tích hợp wake phrase detection. Đây là trái tim của hệ thống voice.

## Tasks

<task id="2.1" type="execute">
<title>Create GlobalVoiceAssistantManager</title>
<read_first>
- LiiO_EatClean/Services/SpeechRecognitionService.swift (existing STT service)
- LiiO_EatClean/Services/WakePhraseDetector.swift (from Plan 1)
- LiiO_EatClean/Services/TextToSpeechService.swift (from Plan 1)
- LiiO_EatClean/Data/Models/VoiceAssistantState.swift (from Plan 1)
- LiiO_EatClean/Data/Models/AssistantVoiceSettings.swift (from Plan 1)
- .planning/phases/30-voice-assistant/30-CONTEXT.md (Sections 3, 4, 5, 9)
</read_first>
<action>
Create `LiiO_EatClean/Services/GlobalVoiceAssistantManager.swift`:

Core architecture:
1. Singleton pattern, inject as @Environment at app root
2. Single AVAudioEngine instance — NO parallel engines
3. State machine transitions following VoiceAssistantState enum

Key properties:
```swift
@Observable
class GlobalVoiceAssistantManager {
    var state: VoiceAssistantState = .disabled
    var currentTranscript: String = ""
    var lastResponse: String = ""
    var lastSuggestedFoods: [AISuggestedFood]?
    var errorMessage: String?
    
    private let settings: AssistantVoiceSettings
    private let wakePhraseDetector: WakePhraseDetector
    private let speechService: SpeechRecognitionService
    private let ttsService: TextToSpeechService
    private let chatRepository: ChatRepositoryProtocol
    private let aiService: AIService
    private let contextBuilder: ContextBuilder
    
    private var audioEngine: AVAudioEngine?
    private var audioLevelTimer: Timer?
    private let audioLevelThreshold: Float = 0.05 // RMS threshold
    private let audioLevelDuration: TimeInterval = 0.3 // 300ms sustained
    private var audioAboveThresholdStart: Date?
    
    // Anti-self-listen
    private let ttsCooldown: TimeInterval = 1.5
    private let wakeDoubleTriggerCooldown: TimeInterval = 2.0
    private var lastWakeTime: Date?
}
```

Key methods:
- `startListening()` — Bắt đầu audio level monitoring (state → voiceGateListening)
- `stopListening()` — Dừng hoàn toàn (state → idle hoặc disabled)
- `handleAudioLevelUpdate(_ level: Float)` — Check threshold, trigger wake checking
- `startWakeChecking()` — Start short SFSpeech 2-3s (state → wakeChecking)
- `handleWakeCheckResult(_ transcript: String)` — Check wake phrase match
- `onWakeDetected()` — Haptic + overlay + chuyển sang commandListening
- `startCommandListening()` — Full SFSpeech cho user command
- `handleCommandResult(_ transcript: String)` — Gửi vào AI pipeline
- `processVoiceCommand(_ text: String)` — AI pipeline integration
- `speakResponse(_ text: String)` — TTS if enabled
- `handleAppBackground()` — Stop everything
- `handleAppForeground()` — Resume if settings enabled

Audio Level Monitoring (voiceGateListening):
- Use AVAudioEngine's input node tap
- Read RMS level every 100ms
- If RMS > audioLevelThreshold for > 300ms continuously → startWakeChecking()
- Lightweight — no SFSpeech running

Wake Checking (wakeChecking):
- Start SFSpeechRecognizer with timeout of 3 seconds
- Get partial transcript
- Call wakePhraseDetector.containsWakePhrase(transcript)
- If match → onWakeDetected()
- If no match or timeout → back to voiceGateListening

Command Listening (commandListening):
- Use existing SpeechRecognitionService
- Auto-stop on silence 1.0s (configurable)
- Max duration 15s
- On complete → handleCommandResult()

Anti-Self-Listen:
- When TTS starts → pause audio level monitoring
- When TTS ends → wait ttsCooldown (1.5s) → resume
- After wake detected → wakeDoubleTriggerCooldown (2.0s) before next wake check

App Lifecycle:
- Listen for UIApplication.didEnterBackgroundNotification → stopListening()
- Listen for UIApplication.willEnterForegroundNotification → resume if settings.globalWakeEnabled
</action>
<acceptance_criteria>
- File `GlobalVoiceAssistantManager.swift` exists in `Services/`
- Class is `@Observable` with `state` property of type `VoiceAssistantState`
- Only 1 AVAudioEngine instance — no parallel engines
- `startListening()` transitions state to `.voiceGateListening`
- Audio level threshold check uses RMS with 300ms sustained requirement
- Wake checking uses SFSpeech with 3-second timeout
- Anti-self-listen: pauses monitoring during TTS + cooldown
- App lifecycle handlers stop/resume listening
- `handleCommandResult` sends transcript to AI pipeline
</acceptance_criteria>
</task>

<task id="2.2" type="execute">
<title>Extend SpeechRecognitionService for short sessions</title>
<read_first>
- LiiO_EatClean/Services/SpeechRecognitionService.swift
</read_first>
<action>
Add method to `SpeechRecognitionService`:

```swift
/// Start a short recognition session for wake phrase detection
/// Automatically stops after maxDuration seconds
func startShortSession(maxDuration: TimeInterval = 3.0, onResult: @escaping (String) -> Void) {
    startListening()
    
    DispatchQueue.main.asyncAfter(deadline: .now() + maxDuration) { [weak self] in
        guard let self, self.isListening else { return }
        let transcript = self.transcript
        self.stopListening()
        onResult(transcript)
    }
}
```

Also add a `silenceTimeout` configurable property (default 1.0s) for use in command listening mode.
Ensure `stopListening()` properly cleans up audio session to avoid conflicts with GlobalVoiceAssistantManager's audio engine.
</action>
<acceptance_criteria>
- `SpeechRecognitionService` has `startShortSession(maxDuration:onResult:)` method
- Short session auto-stops after maxDuration
- `silenceTimeout` property exists and defaults to 1.0
- `stopListening()` releases audio tap and engine resources cleanly
</acceptance_criteria>
</task>

<task id="2.3" type="execute">
<title>Inject GlobalVoiceAssistantManager at app root</title>
<read_first>
- LiiO_EatClean/LiiO_EatCleanApp.swift
</read_first>
<action>
In `LiiO_EatCleanApp.swift`:

1. Create instance of `GlobalVoiceAssistantManager` as `@State`
2. Inject into environment: `.environment(voiceManager)`
3. Observe app lifecycle to call `handleAppBackground()` / `handleAppForeground()`
4. Start listening on app launch if `settings.globalWakeEnabled == true`

```swift
@main
struct LiiO_EatCleanApp: App {
    @State private var voiceManager = GlobalVoiceAssistantManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(voiceManager)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    voiceManager.handleAppBackground()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    voiceManager.handleAppForeground()
                }
        }
    }
}
```
</action>
<acceptance_criteria>
- `GlobalVoiceAssistantManager` injected via `.environment()` in `LiiO_EatCleanApp`
- Background notification triggers `handleAppBackground()`
- Foreground notification triggers `handleAppForeground()`
- No duplicate manager instances
</acceptance_criteria>
</task>

## Verification
- Build project — no errors from new service integration
- GlobalVoiceAssistantManager can transition through all states
- Audio engine does not conflict with existing SpeechRecognitionService

## Must Haves
- Single AVAudioEngine — no parallel engines ever
- State machine follows exact 9-state enum from CONTEXT.md
- Anti-self-listen with cooldown after TTS
- App lifecycle management (stop on background, resume on foreground)
