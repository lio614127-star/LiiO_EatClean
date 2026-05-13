# Phase 30: In-App Voice Assistant & Global Wake Phrase — CONTEXT

> Generated: 2026-05-13
> Requirements: VOICE-01, VOICE-02, VOICE-03, VOICE-04

## Domain

Trải nghiệm Hands-free đích thực cho AI Coach — gọi bằng giọng nói ở mọi tab, AI phản hồi thông minh theo cá tính user chọn, lưu lại lịch sử như chat text bình thường.

## Scope Boundary

**In-scope:**
- Global wake phrase detection khi app foreground (tất cả tab)
- Audio level gate + short SFSpeech recognition (không stream liên tục)
- Floating voice overlay (không auto-switch tab)
- Command listening + auto-send sau silence
- TTS response (setting-based)
- Custom AI name → auto-generate wake phrases
- Custom wake responses (preset + custom + random)
- Per-intent response styles (6 intents)
- Custom response templates with variable substitution
- Voice response length setting
- Auto-send micro trong AI Coach tab

**Out of scope (OS-level/background):**
- Wake phrase khi app background / màn hình khóa / app tắt
- Wake word OS-level (Siri-style)
- Lưu audio file (chỉ lưu transcript)

## Decisions

### 1. Phạm vi lắng nghe
- **Chọn:** Foreground toàn app, có toggle setting
- Setting: "Gọi AI bằng giọng nói trong app" — default OFF
- Khi ON: wake phrase hoạt động ở mọi tab khi app foreground
- Khi OFF: chỉ dùng micro thủ công trong AI Coach
- Khi bật lần đầu: request Mic + Speech permissions, hiển thị explanation

### 2. Cơ chế phát hiện wake phrase
- **Chọn:** Audio level threshold + short SFSpeech (2–3 giây)
- KHÔNG dùng SFSpeechRecognizer liên tục
- Flow: AVAudioEngine monitor RMS → vượt ngưỡng 250–400ms → start short SFSpeech → check wake phrase → match hoặc quay lại idle
- Normalize transcript: lowercase, remove accents, trim punctuation, collapse spaces
- Fuzzy match: "hey lio", "lio oi", "li o oi", "e lio", "alo lio"

### 3. UI phản hồi khi detect wake phrase
- **Chọn:** Floating voice overlay tại chỗ
- KHÔNG auto-switch sang tab AI Coach
- Overlay style: bottom sheet / capsule card, blur/material, rounded corners
- Overlay states: Wake Detected → Listening → Processing → Speaking → Done
- Nút "Xem trong AI Coach" sau khi trả lời xong

### 4. State Machine

```
VoiceAssistantState {
    case disabled          // Setting off hoặc thiếu permission
    case idle              // Setting on, chưa start
    case voiceGateListening // Monitor audio level nhẹ (no SFSpeech)
    case wakeChecking      // Audio vượt ngưỡng, SFSpeech 2-3s
    case wakeDetected      // Wake phrase khớp, overlay hiện
    case commandListening  // Nghe câu hỏi/lệnh chính
    case processing        // Gửi AI pipeline
    case speaking          // TTS đang đọc response
    case error             // Lỗi permission/speech/audio
}
```

### 5. Architecture — GlobalVoiceAssistantManager
- App-level singleton, inject ở root app (EnvironmentObject/AppState)
- Dependencies: WakePhraseDetector, SpeechRecognitionService, TextToSpeechService, ChatRepository, ContextBuilder
- KHÔNG đặt listener riêng trong từng tab
- Chỉ 1 AVAudioEngine instance toàn app

### 6. WakePhraseDetector
- `updateAssistantName(_ name: String)` — update wake phrases
- `generateWakePhrases(name: String) -> [String]` — "Hey {name}", "{name} ơi", "Ê {name}", "Alo {name}"
- `normalize(_ text: String) -> String` — lowercase + remove accents + collapse spaces
- `containsWakePhrase(_ transcript: String) -> Bool` — fuzzy match
- Cảnh báo nếu tên quá ngắn/phổ biến

### 7. Auto-Send & Silence Detection (VOICE-01)
- Silence timeout: 0.8–1.5 giây → auto-send
- Max duration: 12–15 giây
- Nếu transcript rỗng: "Mình chưa nghe rõ, bạn nói lại nhé." → quay lại voiceGateListening
- Micro trong AI Coach tab cũng auto-send (setting toggle, default ON)

### 8. TTS Response (VOICE-04)
- Setting toggle: "Trả lời bằng giọng nói" — default OFF
- Khi TTS đang speaking: pause voiceGateListening
- Sau TTS kết thúc: cooldown 1–2 giây trước khi resume listening
- User có thể bấm "Dừng đọc" để ngắt TTS

### 9. Anti-Self-Listen
- Khi TTS speaking → pause voiceGateListening
- Sau TTS kết thúc → wait cooldown 1–2s → resume
- Cooldown sau mỗi wake detection: 2 giây (tránh double trigger)

### 10. Chat History Integration
- KHÔNG lưu wake phrase ("Hey LiiO") vào history
- Chỉ lưu command/question sau wake phrase
- ChatMessageModel fields: `inputMode = "voice"`, `metadataJSON.source = "globalVoiceAssistant"`
- Voice command đi qua CÙNG pipeline với text chat (intent detection → ContextBuilder → AI → action handler → response → save → TTS)

### 11. Custom AI Name & Wake Phrases (VOICE-03)
- Setting "Tên trợ lý AI" — default "LiiO"
- Wake phrases auto-generated từ tên
- Khi user đổi tên → wake phrases update tự động
- Không hard-code "LiiO" bất kỳ đâu

### 12. Custom Wake Responses
- Preset list: "Mình nghe đây.", "Mình đây, bạn nói đi.", "Có mình đây.", "Bạn cần mình giúp gì?", "Nói mình nghe nè.", "Tớ đây.", "Coach đây, nói đi nào."
- User thêm custom phrases
- Random mode toggle: random trong danh sách enabled phrases
- Data: `selectedPhraseId`, `customPhrases: [String]`, `randomizeEnabled: Bool`, `enabledPhraseIds: [UUID]`

### 13. Response Style System
- **Default style** — 5 presets:
  - `concise` — 1–3 câu, đi thẳng ý chính
  - `friendly` — tự nhiên, có động viên (DEFAULT)
  - `strictCoach` — rõ ràng, thực tế
  - `cute` — ấm áp, vui vẻ
  - `nutritionExpert` — phân tích kỹ, có lý do

- **Per-intent styles** — 6 intents, mỗi intent 4–5 options:
  1. `meal_logging` — xác nhận ngắn / +calo / +macro / +gợi ý / custom
  2. `plan_question` — ngắn / dựa plan / dựa macro thiếu / phân tích kỹ / custom
  3. `cooking_advice` — tóm tắt / từng bước / mẹo nấu / eat clean / custom
  4. `health_question` — dễ hiểu / chuyên gia / ngắn+cảnh báo / ưu-nhược / custom
  5. `progress_question` — tóm tắt / trend 7 ngày / cân nặng+calo / coach động viên / custom
  6. `rebalance_request` — giải thích ngắn / lý do / so sánh trước-sau / coach / custom

### 14. Custom Response Templates
- Variable substitution: `{foodName}`, `{mealType}`, `{calories}`, `{protein}`, `{remainingCalories}`, `{assistantName}`, etc.
- Fallback sang style mặc định nếu thiếu data cho template
- Không hiển thị raw placeholder cho user

### 15. Voice Response Length
- Setting: "Độ dài câu trả lời bằng giọng nói"
- 3 levels: Rất ngắn (1 câu) / Vừa đủ (2–4 câu, DEFAULT) / Chi tiết (1 đoạn)
- Inject vào AI prompt để limit response length

### 16. Data Model — AssistantVoiceSettings
```
AssistantVoiceSettings:
  assistantName: String
  globalWakeEnabled: Bool
  wakeResponseMode: fixed | random
  selectedWakeResponse: String
  customWakeResponses: [String]
  enabledWakeResponses: [String]
  defaultResponseStyle: String (concise/friendly/strictCoach/cute/nutritionExpert)
  intentResponseStyles: [String: String]
  customIntentTemplates: [String: String]
  voiceReplyEnabled: Bool
  voiceResponseLength: String (veryShort/moderate/detailed)
  autoSendAfterSpeech: Bool
```
- Storage: UserDefaults / @AppStorage (settings nhẹ, không cần CoreData)

### 17. AI Prompt Integration
- ContextBuilder nhận thêm: `assistantName`, `defaultResponseStyle`, `currentIntentResponseStyle`, `customTemplate`, `voiceMode`
- Voice mode rule: "Ưu tiên câu ngắn hơn, tự nhiên hơn, không liệt kê quá dài"
- Response length setting inject vào prompt

### 18. Settings UI Structure
```
AI Coach Settings:
├── Section 1: Tên trợ lý
├── Section 2: Câu gọi trợ lý (auto-generated wake phrases)
├── Section 3: Câu trả lời khi được gọi (preset + custom + random toggle)
├── Section 4: Phong cách mặc định (5 presets)
├── Section 5: Cách trả lời theo tình huống (6 intents, each opens detail sheet)
├── Section 6: Độ dài câu trả lời voice
├── Section 7: Tự gửi sau khi nói (auto-send toggle)
└── Section 8: Trả lời bằng giọng nói (TTS toggle)
```

### 19. Performance & Privacy Rules
- Không chạy SFSpeech liên tục
- Stop listener khi app background
- Stop listener khi permission revoked
- Stop listener khi TTS speaking
- Không tạo nhiều AVAudioEngine
- Không lưu audio file — chỉ transcript
- Privacy copy: "LiiO chỉ lắng nghe khi app đang mở. Không nghe khi app đã đóng hoặc màn hình khóa."

## Canonical Refs
- [ROADMAP.md](.planning/ROADMAP.md) — Phase 30 definition
- [REQUIREMENTS.md](.planning/REQUIREMENTS.md) — VOICE-01 through VOICE-04
- [SpeechRecognitionService.swift](LiiO_EatClean/Services/SpeechRecognitionService.swift) — Existing STT service (156 lines, vi-VN locale)
- [VoiceRecordingSheet.swift](LiiO_EatClean/Features/Chat/Components/VoiceRecordingSheet.swift) — Existing voice UI sheet
- [VoiceInputView.swift](LiiO_EatClean/Features/Meals/Components/VoiceInputView.swift) — Existing voice input in Meals
- [ChatMessageModel.swift](LiiO_EatClean/Data/Models/ChatMessageModel.swift) — Has `inputMode` field ready for voice
- [ChatViewModel.swift](LiiO_EatClean/Features/Chat/ChatViewModel.swift) — Current AI Coach pipeline
- [ContextBuilder.swift](LiiO_EatClean/Features/AI/ContextBuilder.swift) — Prompt builder to extend
- [AIService.swift](LiiO_EatClean/Features/AI/AIService.swift) — AI API layer

## Code Context
- `SpeechRecognitionService` already has: SFSpeechRecognizer (vi-VN), silence detection, audio level tracking, permission request
- `ChatMessageModel.inputMode` already supports "text" / "voice" distinction
- `AIPersonalityTone` enum exists at `Data/Models/AIPersonalityTone.swift` — can be extended or referenced
- `ContextBuilder.buildSystemPrompt()` already has strategy pattern — add voice-aware context injection
- Existing `VoiceRecordingSheet` can be evolved into the floating overlay

## Acceptance Criteria
1. Setting "Gọi AI bằng giọng nói trong app" — toggle ON/OFF
2. Wake phrase hoạt động ở mọi tab khi app foreground (setting ON)
3. Không hoạt động khi app background/lock screen
4. Audio level gate trước khi bật short SFSpeech
5. "Hey [Tên AI]" hoặc "[Tên AI] ơi" mở floating voice overlay
6. Không auto-switch tab AI Coach
7. Sau wake phrase, nghe command → auto-send sau silence
8. Voice transcript lưu vào ChatMessageModel (inputMode = voice)
9. AI response lưu vào chat history
10. TTS khi setting bật, pause wake listener khi speaking
11. Micro trong AI Coach auto-send sau silence
12. Không nhiều AVAudioEngine song song
13. User đổi tên AI → wake phrases update
14. Custom wake responses (preset + custom + random)
15. Per-intent response styles (6 intents)
16. Custom templates with variable substitution
17. Voice response length setting
18. Nút "Xem trong AI Coach" trong overlay

## Deferred Ideas
- Voice shortcut widgets cho iOS Home Screen
- Multi-language wake phrase (English + Vietnamese mixed)
- On-device wake word ML model (thay thế SFSpeech gate)
- Voice-only mode (không cần nhìn màn hình)
