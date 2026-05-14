---
status: resolved
trigger: "Voice Assistant persistent features: Orb gesture overlaps, follow-up capture ignores speech, chat lacks realtime mirror."
symptoms:
  expected_behavior: "Only Orb circle draggable, non-blocking overlays, assistant listens to second question without wake phrase, chat updates realtime bubble."
  actual_behavior: "Orb intercepts scroll gesture, follow-up startCommandListening returns early, chat requires tab swapping/re-initialization to update."
---

# Summary of Actions Taken
- **Hypothesis Validation**: Verified. SwiftUI `.position` was capturing full-screen touch bounds, `startCommandListening` did early exit on `.speaking` state, and `ChatViewModel` lacked integration hooks to active in-flight speech streams.

## Wave 1 & 2 Resolutions (Live Mirror Architectures)
- **ChatMessageModel**: Appended `status: ChatMessageStatus?` and `clientId: String?` fields.
- **ChatRealtimeStore**: Created app-level singleton maintaining `activeVoiceDraftMessage` and `activeAssistantDraftMessage` properties.
- **ChatViewModel**: Implemented `displayMessages` computed stack which injects active live drafts, and added a `listenForExternalMessages` Observer bound to `.chatMessageSavedExternally` to perfectly mirror CoreData items generated out-of-band by the Voice Assistant without duplication.
- **GlobalVoiceAssistantManager**: Swapped all standalone `saveMessage` calls with a new `saveAndMirrorMessage` helper that broadcasts to standard UI VMs.

## Wave 3 Resolutions (Continuous Flow Loop)
- **GlobalVoiceAssistantManager**: Modified `startCommandListening` to allow state transition entry if state is `.speaking` or `.speakingAIResponse`. Added specialized telemetry log: `[Voice-Flow C1] follow-up listening armed`. Added partial updates to the live store in `onTranscriptUpdate`.

## Wave 4 & 5 Resolutions (UI Gesture Fixes)
- **VoiceOrbView**: Rearranged View Modifiers to place `.gesture` BEFORE `.position` and bound position values back to the parent manager's state `orbYPosition`.
- **SiriStyleVoiceOverlayV4**: Wrapped active elements into an isolated inner `VStack` container to intercept gestures exclusively in physical console boundaries, leaving the remainder of screen height transparently touch-through.
- **ActionableMessageView / ChatView**: Bound data layer to `displayMessages` and updated the visual Bubble UI to cleanly render blinking microphones and "Đang phân tích..." labels in-place.

# Verification Checklists
- [x] Only the Orb handles drag-snaps. Remaining screen region accepts normal vertical scroll gestures.
- [x] Voice overlay minimizes successfully on pill-level swipes, without stealing swipes on empty zones.
- [x] Speaking state completion successfully triggers `startCommandListening` to capture consecutive commands.
- [x] Live Messenger-style bubbles render user text in-place in Chat Tab simultaneously as spoken.
- [x] Chat ViewModel appends finalized responses synchronously upon TTS load.
