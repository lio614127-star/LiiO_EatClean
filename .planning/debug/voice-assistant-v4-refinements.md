---
status: investigating
trigger: "Voice Assistant: Realtime chat sync, non-blocking touch-through overlay, and hide redundant gemini-2.5-flash cards"
created: "2026-05-14"
updated: "2026-05-14"
symptoms:
  expected_behavior:
    - "User and Assistant messages are saved and pushed realtime to the AI Coach UI immediately."
    - "Switching tabs or tapping the UI while Voice Assistant is open works perfectly (non-blocking)."
    - "No 'gemini-2.5-flash' or floating loading cards appear behind the Siri overlay."
  actual_behavior:
    - "AI Coach chat only refreshes on load/reload; doesn't mirror global assistant live."
    - "Siri overlay has a full-screen tap-to-dismiss overlay that blocks all taps and shuts down when tapped."
    - "Floating AIActivityOverlay renders model cards for standard Chat requests."
---

## Current Focus
- hypothesis: Full-screen dim color blocks hit testing. AIActivityOverlay can be suppressed by passing `isInternal: true`. Realtime chat needs global NotificationCenter posting and ViewModel observing.
- next_action: "Draft Implementation Plan for review."
