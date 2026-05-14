---
status: resolved
trigger: "Voice waveform flat/dead when tapping Chat micro"
created: 2026-05-14T17:17:00Z
updated: 2026-05-14T17:18:00Z
---

# Debug Session: `voice-mic-contention-fix`

## Symptoms
- **Issue:** When clicking the green microphone button in the "AI Coach" Chat Tab, the recording overlay ("Đang nghe...") appears, and the iOS status bar shows the microphone active indicator, but the audio wave remains totally flat (`..........`), and speaking does not trigger any transcription.
- **Screenshots:** User provided an image showing the flat green dot waveform indicator inside the recording sheet.

## Diagnosis
- **Root Cause:** *Microphone Engine Contention*. The system-wide `GlobalVoiceAssistantManager` (added in Phase 30) runs an active `AVAudioEngine` in the background to continuously listen for the "Hey LiiO" wake phrase.
- When the local `VoiceRecordingSheet` is displayed, it initializes a *second* `AVAudioEngine` via `SpeechRecognitionService`.
- iOS does not allow concurrent audio unit taps on the same hardware input bus (`onBus: 0`). The second tap receives either zero buffers or fails silently because the background assistant refuses to yield the hardware resource.

## Resolution
- **Fix Applied:** Synchronized lifecycle hand-off between background wake detection and local voice interactions.
- **Changes in [ChatView.swift](file:///Users/liio/TooL_LiiO/LiiO_EatClean/LiiO_EatClean/Features/Chat/ChatView.swift):**
  - Injected `GlobalVoiceAssistantManager` from Environment.
  - Leveraged `.onChange(of: showVoiceSheet)` to:
    1. Command `voiceManager.stopListening()` immediately upon sheet presentation (fully releasing the global engine & tap).
    2. Added a `0.2s` safety gap to let hardware completely tear down before initiating local `speechService.startListening()`.
    3. Automatically resumed global wake detection with `voiceManager.startListening()` upon dismissal.
- **Changes in [VoiceInputView.swift](file:///Users/liio/TooL_LiiO/LiiO_EatClean/LiiO_EatClean/Features/Meals/Components/VoiceInputView.swift) (Preemptive Fix):**
  - Applied the exact same lifecycle pause/resume strategy to the "Log by Voice" input sheet to prevent contention there.
- **Commit:** `529761b`

## Verification
- Rebuild the target. Tapping local mics should cleanly yield the global tap, causing waveforms to immediately jump and transcription to start rendering properly.
