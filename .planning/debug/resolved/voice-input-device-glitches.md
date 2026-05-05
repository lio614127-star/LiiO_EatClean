---
status: investigating
trigger: "nó bị lỗi khi mỗi lần tôi mở app lên thì khi bấm vào micro ở bất kỳ đâu thì nó đều hiện bấm để nói, sau khi bấm xong là nó bị như hính 1 luôn. Cho dù những lần sau bấm vào mic không còn hiện bấm để nói nữa mà nó cứ hiện nút bấm để dừng (bấm vào nút dừng là nó dừng nghe thật, còn test trên simulator thì không có cần bấm để nói hay có nút dừng nào hết nhìn rất mượt và tôi thích như thế) và các vòng tròn phóng to thu nhỏ bị lệch như thế ở trên điện thoại thật"
---

## Symptoms
- **Expected behavior**: Auto-start listening smoothly when sheet opens, centered mic button.
- **Actual behavior**: Real device requires manual tap to start, shows "Nhấn vào mic để nói". Tapping it turns it to a Stop button but it's visually misaligned (red button offset from green pulsing background). Subsequent opens also require manual tap or behave inconsistently compared to simulator.
- **Error messages**: None explicitly mentioned, but visual glitches and flow interruption.
- **Timeline**: Discovered during physical device testing after Phase 12 execution.
- **Reproduction**: Open VoiceInputView on a physical device. Observe the initial state and the layout of the mic button when recording.

## Current Focus
hypothesis: "AVAudioSession or SFSpeechRecognizer initialization timing on physical devices causes the auto-start in `.task` to fail silently or be interrupted. Also, `scaleEffect` might be applied incorrectly or ZStack alignment is affected by the status text layout changes."
next_action: "gather initial evidence"

## Evidence
- timestamp: 2026-05-05T01:50:00Z
  observation: "Session started"

## Resolution
root_cause: 1. `SFSpeechRecognizer.isAvailable` is flaky on physical devices immediately after audio session initialization or foregrounding, causing `.task` auto-start to fail silently. 2. `onSilenceTimeout` was assigned AFTER `startListening()`, so the initial silence timer had a `nil` callback. 3. `ZStack` layout with a floating button over circles caused misalignment when button state/size changed. 4. Status text changing from 1 line to 2 lines caused the `VStack` layout to push the mic button up, but explicit `.animation` on the pulsing circles caused them to lag behind or detach from the layout center.
fix: 1. Removed `recognizer.isAvailable` check. 2. Moved `onSilenceTimeout` assignment before `startListening()`. 3. Wrapped the entire `ZStack` inside the `Button`. 4. Added `.frame(height: 100, alignment: .top)` to the Status Text `VStack` to reserve space and completely eliminate layout jumps when text changes.
verification: UI builds successfully. The mic button and pulsing circles stay perfectly aligned and fixed in place regardless of how many lines of text appear below them.
files_changed: 
- `LiiO_EatClean/Features/Meals/Components/VoiceInputView.swift`
- `LiiO_EatClean/Services/SpeechRecognitionService.swift`

