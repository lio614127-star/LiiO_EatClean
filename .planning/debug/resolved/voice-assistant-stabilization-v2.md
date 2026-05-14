---
status: investigating
trigger: "Voice Assistant stabilization: Settings sync, Test Overlay visibility, and Speech session lifecycle failures."
symptoms:
  expected: "1. Settings checkmarks update real-time. 2. Test Overlay appears instantly. 3. Test Speech session stays active for recording. 4. Wake phrase triggers overlay."
  actual: "1. Settings require reopen to save. 2. Test Overlay fails. 3. Test Speech closes after 1s. 4. Wake detection fails."
  errors: "No explicit error logs yet, but UI is unresponsive."
  timeline: "V1.5 Voice Assistant Refactor (Phase 30)."
  reproduction: "Interact with Settings list, press Test buttons in Voice Diagnostics."
created: 2026-05-13
updated: 2026-05-13
---

# Current Focus
- **Hypothesis**: 1. `WakeResponseOption` uses unstable UUIDs. 2. `GlobalVoiceAssistantManager` is not a singleton or improperly injected. 3. Speech session is being deallocated prematurely.
- **Next Action**: Verify Test Speech session stability and Wake phrase matching.

# Evidence
- [2026-05-13] User reported list checkmarks don't appear. (RESOLVED: Stable IDs + @Observable sync)
- [2026-05-13] User reported Test Overlay doesn't show up. (RESOLVED: showTestOverlay + root state)
- [2026-05-13] User reported Test Speech shuts down after 1s. (RESOLVED: silenceTimeout + strong session)

# Eliminated
- Root Overlay Injection: Verified `LiiO_EatCleanApp` and `ContentView` use the same `voiceManager` instance.
- Settings Sync: Switched to manual `access/withMutation` for all `@AppStorage` properties.

# Root Cause
1. `WakeResponseOption` was recreating UUIDs on each access, breaking checkmark comparisons.
2. `SpeechRecognitionService` used a 1.0s silence timeout which killed the session before user could speak during tests.
3. `showTestOverlay` was missing an explicit state trigger for the root view.

# Resolution
- [x] Fix `WakeResponseOption` to use stable IDs.
- [x] Verify `GlobalVoiceAssistantManager` singleton injection.
- [x] Stabilize `SpeechRecognitionService` lifecycle (increased timeouts).
- [x] Refactor `VoiceAssistantSettingsView` to observe the single source of truth.
- [x] Added `startSpeechTest`, `startWakeTest`, `showTestOverlay` methods.
- [x] Improved `WakePhraseDetector` normalization for Vietnamese.
