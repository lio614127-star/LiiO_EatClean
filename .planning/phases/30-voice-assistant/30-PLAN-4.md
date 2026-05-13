---
phase: 30
wave: 4
title: "AI Pipeline Integration & Auto-Send"
depends_on: [30-PLAN-2, 30-PLAN-3]
requirements: [VOICE-01, VOICE-04]
files_modified:
  - LiiO_EatClean/Services/GlobalVoiceAssistantManager.swift
  - LiiO_EatClean/Features/AI/ContextBuilder.swift
  - LiiO_EatClean/Features/Chat/ChatViewModel.swift
  - LiiO_EatClean/Features/Chat/ChatView.swift
  - LiiO_EatClean/Data/Repositories/ChatRepository.swift
autonomous: true
---

# Plan 4: AI Pipeline Integration & Auto-Send

## Goal
Kết nối voice command vào cùng pipeline AI Coach hiện có, lưu transcript vào chat history, và cập nhật micro trong AI Coach tab với auto-send.

## Tasks

<task id="4.1" type="execute">
<title>Voice command → AI pipeline integration</title>
<read_first>
- LiiO_EatClean/Services/GlobalVoiceAssistantManager.swift (from Plan 2)
- LiiO_EatClean/Features/Chat/ChatViewModel.swift
- LiiO_EatClean/Features/AI/AIService.swift
- LiiO_EatClean/Features/AI/ContextBuilder.swift
- LiiO_EatClean/Data/Models/ChatMessageModel.swift
- .planning/phases/30-voice-assistant/30-CONTEXT.md (Sections 8, 9, 10)
</read_first>
<action>
In `GlobalVoiceAssistantManager`, implement `processVoiceCommand(_ text: String)`:

```swift
func processVoiceCommand(_ text: String) async {
    state = .processing
    
    do {
        // 1. Save user message to chat history
        let userMessage = ChatMessageModel(
            role: .user,
            text: text,
            inputMode: "voice"
        )
        
        // Get or create active session
        let session = try await chatRepository.fetchLatestActiveSession()
            ?? (try await chatRepository.createSession(title: "Voice Chat", source: "globalVoiceAssistant"))
        
        try await chatRepository.saveMessage(userMessage, sessionId: session.id)
        
        // 2. Build context with voice-aware settings
        let systemPrompt = try await contextBuilder.buildSystemPrompt(
            for: text,
            strategy: .chat,
            voiceMode: true,
            responseStyle: settings.getResponseStyle(for: detectIntent(text)),
            responseLength: VoiceResponseLength(rawValue: settings.voiceResponseLength) ?? .moderate
        )
        
        // 3. Send to AI pipeline (same as text chat)
        let response = try await aiService.sendChatMessage(
            history: [userMessage],
            systemPrompt: systemPrompt,
            feature: "Voice Assistant"
        )
        
        // 4. Save assistant response
        var assistantMessage = response
        assistantMessage.outputMode = settings.voiceReplyEnabled ? "voice" : "text"
        try await chatRepository.saveMessage(assistantMessage, sessionId: session.id)
        try await chatRepository.updateSessionMetadata(sessionId: session.id, lastMessage: text)
        
        // 5. Update UI
        lastResponse = response.text
        lastSuggestedFoods = response.suggestedFoods
        
        // 6. TTS if enabled
        if settings.voiceReplyEnabled {
            state = .speaking
            ttsService.onFinished = { [weak self] in
                DispatchQueue.main.asyncAfter(deadline: .now() + self?.ttsCooldown ?? 1.5) {
                    self?.resumeListeningAfterSpeech()
                }
            }
            ttsService.speak(response.text)
        } else {
            // Auto-dismiss after 5s if no TTS
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                self?.resumeListeningAfterSpeech()
            }
        }
    } catch {
        errorMessage = "Lỗi xử lý: \(error.localizedDescription)"
        state = .error
    }
}

private func detectIntent(_ text: String) -> String {
    let lower = text.lowercased()
    if lower.contains("vừa ăn") || lower.contains("đã ăn") || lower.contains("log") {
        return "meal_logging"
    } else if lower.contains("nên ăn") || lower.contains("ăn gì") || lower.contains("kế hoạch") {
        return "plan_question"
    } else if lower.contains("nấu") || lower.contains("chế biến") || lower.contains("làm") {
        return "cooking_advice"
    } else if lower.contains("sức khỏe") || lower.contains("bệnh") || lower.contains("dị ứng") {
        return "health_question"
    } else if lower.contains("tiến độ") || lower.contains("tuần qua") || lower.contains("giảm") {
        return "progress_question"
    } else if lower.contains("cân đối") || lower.contains("rebalance") || lower.contains("chỉnh lại") {
        return "rebalance_request"
    }
    return "general_chat"
}
```

IMPORTANT: Voice command must go through the SAME pipeline as text chat. No separate AI logic.
IMPORTANT: Do NOT save wake phrase "Hey LiiO" — only save the command after wake detection.
</action>
<acceptance_criteria>
- `processVoiceCommand` saves user message with `inputMode = "voice"`
- User message saved to ChatRepository (same as text chat)
- Assistant response saved with `outputMode` based on TTS setting
- `detectIntent()` returns correct intent for 6 intent types + general_chat fallback
- TTS plays response when `voiceReplyEnabled == true`
- After TTS, resumes listening with cooldown delay
- Error state set on failure
</acceptance_criteria>
</task>

<task id="4.2" type="execute">
<title>Extend ContextBuilder for voice-aware prompts</title>
<read_first>
- LiiO_EatClean/Features/AI/ContextBuilder.swift
- LiiO_EatClean/Data/Models/AssistantVoiceSettings.swift (from Plan 1)
- .planning/phases/30-voice-assistant/30-CONTEXT.md (Section 17: AI Prompt Integration)
</read_first>
<action>
Add voice-aware parameters to `ContextBuilder.buildSystemPrompt()`:

```swift
func buildSystemPrompt(
    for userMessage: String,
    strategy: ContextStrategy = .chat,
    remainingCalories: Double? = nil,
    mealType: String? = nil,
    voiceMode: Bool = false,
    responseStyle: AssistantResponseStyle? = nil,
    responseLength: VoiceResponseLength? = nil
) async throws -> String {
    // ... existing logic ...
    
    // Add voice-aware rules at the end
    if voiceMode {
        prompt += buildVoiceRules(style: responseStyle, length: responseLength)
    }
    
    return prompt
}

private func buildVoiceRules(style: AssistantResponseStyle?, length: VoiceResponseLength?) -> String {
    var rules = "\n\n[Chế độ Voice — Trả lời bằng giọng nói]\n"
    rules += "- Ưu tiên câu ngắn hơn, tự nhiên hơn, không liệt kê quá dài.\n"
    rules += "- Không dùng markdown format (**, ##, ```) vì user nghe bằng tai.\n"
    rules += "- Không liệt kê dạng bullet points dài.\n"
    
    if let style {
        rules += "\n[Phong cách]\n\(style.promptInstruction)\n"
    }
    
    if let length {
        rules += "\n[Độ dài]\n\(length.promptInstruction)\n"
    }
    
    return rules
}
```

Add `promptInstruction` computed property to `AssistantResponseStyle`:
- concise: "Trả lời tối đa 1-3 câu, đi thẳng vào ý chính."
- friendly: "Trả lời tự nhiên, gần gũi, có động viên nhẹ. 2-4 câu."
- strictCoach: "Trả lời rõ ràng, thực tế, tập trung mục tiêu. Không rào trước."
- cute: "Trả lời ấm áp, vui vẻ, nhẹ nhàng. Có emoji nhẹ nếu phù hợp."
- nutritionExpert: "Phân tích kỹ hơn, có lý do dinh dưỡng. Vẫn ngắn gọn."
</action>
<acceptance_criteria>
- `buildSystemPrompt` accepts `voiceMode`, `responseStyle`, `responseLength` parameters
- Default values are `false`, `nil`, `nil` — backward compatible
- Voice mode appends "[Chế độ Voice]" rules to prompt
- Voice rules include "không dùng markdown format" instruction
- Each `AssistantResponseStyle` has `promptInstruction` computed property
- Each `VoiceResponseLength` has `promptInstruction` computed property
</acceptance_criteria>
</task>

<task id="4.3" type="execute">
<title>Add auto-send to AI Coach microphone</title>
<read_first>
- LiiO_EatClean/Features/Chat/ChatView.swift
- LiiO_EatClean/Features/Chat/ChatViewModel.swift
- LiiO_EatClean/Features/Chat/Components/VoiceRecordingSheet.swift
- .planning/phases/30-voice-assistant/30-CONTEXT.md (Section 12: Auto-Send)
</read_first>
<action>
Modify existing voice input in AI Coach tab:

Current behavior: User taps mic → transcript fills input → user taps send.
New behavior: User taps mic → speaks → silence detected → auto-send.

In `VoiceRecordingSheet.swift` or `ChatView.swift`:
1. Read `settings.autoSendAfterSpeech`
2. If true: set `speechService.onSilenceTimeout` to auto-submit
3. On silence timeout (1.0s):
   - Get transcript
   - If not empty: call `viewModel.sendMessage(transcript, inputMode: "voice")`
   - Dismiss recording sheet
4. If transcript empty: show "Mình chưa nghe rõ." and keep listening

In `ChatViewModel.sendMessage`:
- Add optional `inputMode` parameter (default "text")
- Pass `inputMode` to ChatMessageModel creation

```swift
func sendMessage(_ text: String, inputMode: String = "text") async {
    let message = ChatMessageModel(
        role: .user,
        text: text,
        inputMode: inputMode
    )
    // ... rest of existing logic
}
```
</action>
<acceptance_criteria>
- When `autoSendAfterSpeech == true`: mic auto-sends after silence timeout
- When `autoSendAfterSpeech == false`: old behavior (transcript fills input, manual send)
- `ChatViewModel.sendMessage` accepts `inputMode` parameter
- Empty transcript shows "Mình chưa nghe rõ." instead of sending
- Recording sheet auto-dismisses after successful auto-send
</acceptance_criteria>
</task>

## Verification
- Voice command → AI response → saved in chat history
- Opening AI Coach tab shows voice messages alongside text messages
- Auto-send works from mic button in AI Coach
- Voice-mode prompt produces shorter, more natural responses

## Must Haves
- Voice goes through SAME pipeline as text (no separate AI logic)
- Wake phrase "Hey LiiO" NOT saved as message
- Only command text saved with inputMode = "voice"
- ContextBuilder backward compatible (default voiceMode = false)
