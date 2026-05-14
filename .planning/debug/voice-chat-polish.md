---
status: investigating
trigger: |
  User reported 5 issues during voice-chat polish phase:
  1. Food suggestions render for non-food intents.
  2. Ghost voice draft bubbles show truncated text like "Cài ...".
  3. Duplicated/debug popup background card is visible behind voice overlay.
  4. Minimized Voice Orb lacks interactivity, vanishes on speak, and has poor gestures.
  5. Auto-scrolling is missing in realtime voice chat session.
created: "2026-05-14T22:10:00.000Z"
updated: "2026-05-14T22:10:00.000Z"
---

# Debug Session: voice-chat-polish

## Current Focus
hypothesis: |
  Multiple isolated layout/state issues:
  - Food Suggestions: Missing intent filtering logic in ChatView / ViewModel renderer.
  - Ghost Bubbles: `ChatRealtimeStore` draft messages are not properly cleared upon finalization.
  - Debug Card: Legacy debug container still active inside `FloatingVoiceOverlay` or `ContentView`.
  - Minimized Orb: Hit-testing constraints on fullscreen overlay and inactive interaction gestures in `activeMinimized` mode.
  - Auto-Scroll: Missing `ScrollViewReader` updates triggered on realtime draft changes in `ChatView`.
next_action: "Audit all 5 target subsystems to formulate detailed fixes."

## Symptoms
- Expected:
  1. Food cards only appear for food/planning intents.
  2. No mic/ghost bubbles when chat finishes.
  3. Debug card hidden.
  4. Orb draggable, tap-expand, doesn't vanish on speak.
  5. Scroll automatically slides to bottom during live dictation and AI stream.
- Actual: Detailed in trigger report above.

## Evidence Collected
[pending]
