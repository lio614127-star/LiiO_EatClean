---
status: resolved
trigger: "Voice Assistant not responding to wake phrases and Settings UI state issues."
symptoms:
  expected: "App responds to 'Hey LiiO'/'LiiO ơi' with overlay; Settings UI is stable, collapsible, and updates real-time."
  actual: "No wake response; Settings UI inconsistent (toggle vs picker vs list), state not syncing correctly."
  errors: "User reports 'Hey LiiO' not working despite permissions."
  timeline: "V1.5 Voice Assistant integration (Phase 30)."
  reproduction: "Enable global wake, speak phrase, interact with response settings."
created: 2026-05-13
updated: 2026-05-13
---

# Current Focus
- **Hypothesis**: The voice pipeline is failing due to lack of diagnostic feedback or lifecycle issues, and the Settings UI is using fragmented state instead of a unified Store.
- **Next Action**: Resolved.

# Evidence
- [2026-05-13] User reported wake phrase not working even after permission request was added.
- [2026-05-13] User reported UI 'Câu trả lời' transforms from toggle to picker/list and doesn't update immediately.

# Eliminated
- Permissions were missing (resolved by adding request to toggle).
- Fragmented state in Settings (resolved by refactoring to single source of truth in AssistantVoiceSettings).

# Root Cause
1. Missing diagnostic visibility to see where the pipeline failed (fixed by adding diagnostic tools).
2. Lifecycle mismatch where audioEngine didn't resume after background (fixed by scenePhase logic).
3. Complex UI state in Settings causing layout jumping and sync failures (fixed by DisclosureGroup refactor).

# Resolution
- [x] Implement `VoiceAssistantDiagnosticState` in `GlobalVoiceAssistantManager`.
- [x] Add "Công cụ Chẩn đoán" section in `VoiceAssistantSettingsView` with test buttons.
- [x] Refactor Settings UI to use a collapsible list with checkmarks (standardized).
- [x] Ensure all settings update real-time via `AssistantVoiceSettings`.
- [x] Improved wake phrase normalization and assistant name change notification.
