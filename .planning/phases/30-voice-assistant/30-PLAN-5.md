---
phase: 30
wave: 5
title: "Voice Assistant Settings UI"
depends_on: [30-PLAN-1, 30-PLAN-2]
requirements: [VOICE-03]
files_modified:
  - LiiO_EatClean/Features/Settings/VoiceAssistantSettingsView.swift
  - LiiO_EatClean/Features/Settings/IntentResponseStyleView.swift
  - LiiO_EatClean/Features/Chat/ChatView.swift
autonomous: true
---

# Plan 5: Voice Assistant Settings UI

## Goal
Tạo giao diện Settings toàn diện cho Voice Assistant: tên trợ lý, wake responses, response styles, và per-intent customization.

## Tasks

<task id="5.1" type="execute">
<title>Create VoiceAssistantSettingsView</title>
<read_first>
- LiiO_EatClean/Features/Chat/ChatView.swift (existing AI settings location - brain icon)
- LiiO_EatClean/Data/Models/AssistantVoiceSettings.swift (from Plan 1)
- LiiO_EatClean/Data/Models/AIPersonalityTone.swift (existing personality settings)
- .planning/phases/30-voice-assistant/30-CONTEXT.md (Sections 2, 7, 12, 18)
</read_first>
<action>
Create `LiiO_EatClean/Features/Settings/VoiceAssistantSettingsView.swift`:

Full settings view with 8 sections following CONTEXT.md Section 18:

```swift
struct VoiceAssistantSettingsView: View {
    @Environment(AssistantVoiceSettings.self) var settings
    @State private var showingCustomPhraseInput = false
    @State private var newCustomPhrase = ""
    @State private var showingIntentDetail: String?
    
    var body: some View {
        List {
            // Section 1: Tên trợ lý
            Section("Tên trợ lý AI") {
                TextField("Tên", text: $settings.assistantName)
                if settings.wakePhraseDetector.isNameTooShort {
                    Label("Tên quá ngắn", systemImage: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
                if settings.wakePhraseDetector.isNameTooCommon {
                    Label("Tên này có thể dễ bị nhận nhầm", systemImage: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
            }
            
            // Section 2: Câu gọi trợ lý
            Section("Câu gọi trợ lý") {
                ForEach(wakePhraseDetector.generateWakePhrases(name: settings.assistantName), id: \.self) { phrase in
                    Text("\"\(phrase)\"")
                        .foregroundColor(.secondary)
                }
            } footer: {
                Text("Những cụm từ này được tạo tự động từ tên trợ lý.")
            }
            
            // Section 3: Câu trả lời khi được gọi
            Section("Câu trả lời khi được gọi") {
                // Preset responses
                ForEach(AssistantVoiceSettings.presetWakeResponses, id: \.self) { phrase in
                    responseRow(phrase)
                }
                // Custom responses
                ForEach(settings.customWakeResponses, id: \.self) { phrase in
                    responseRow(phrase, isCustom: true)
                }
                // Add custom
                Button("Thêm câu riêng") { showingCustomPhraseInput = true }
                
                // Random toggle
                Toggle("Thay đổi ngẫu nhiên", isOn: $settings.randomizeEnabled)
            }
            
            // Section 4: Gọi AI bằng giọng nói
            Section {
                Toggle("Gọi AI bằng giọng nói trong app", isOn: $settings.globalWakeEnabled)
            } footer: {
                Text("Khi bật, bạn có thể gọi trợ lý bằng '\(settings.assistantName) ơi' hoặc 'Hey \(settings.assistantName)' khi đang dùng app. LiiO chỉ lắng nghe khi app đang mở.")
            }
            
            // Section 5: Phong cách mặc định
            Section("Phong cách trả lời mặc định") {
                ForEach(AssistantResponseStyle.allCases, id: \.self) { style in
                    styleRow(style)
                }
            }
            
            // Section 6: Cách trả lời theo tình huống
            Section("Cách trả lời theo tình huống") {
                intentRow("meal_logging", icon: "fork.knife", title: "Khi log món ăn")
                intentRow("plan_question", icon: "calendar", title: "Khi hỏi nên ăn gì")
                intentRow("cooking_advice", icon: "flame", title: "Khi hỏi nấu ăn")
                intentRow("health_question", icon: "heart", title: "Khi hỏi sức khỏe")
                intentRow("progress_question", icon: "chart.line.uptrend.xyaxis", title: "Khi hỏi tiến độ")
                intentRow("rebalance_request", icon: "arrow.triangle.2.circlepath", title: "Khi AI Rebalance")
            }
            
            // Section 7: Độ dài trả lời voice
            Section("Độ dài câu trả lời bằng giọng nói") {
                ForEach(VoiceResponseLength.allCases, id: \.self) { length in
                    lengthRow(length)
                }
            }
            
            // Section 8: Toggles
            Section {
                Toggle("Tự gửi sau khi nói xong", isOn: $settings.autoSendAfterSpeech)
                Toggle("Trả lời bằng giọng nói", isOn: $settings.voiceReplyEnabled)
            }
        }
        .navigationTitle("Trợ lý giọng nói")
    }
}
```

Each intent row navigates to `IntentResponseStyleView` (detail sheet).
Style: Apple-native List with sections, toggles, and checkmarks.
</action>
<acceptance_criteria>
- File `VoiceAssistantSettingsView.swift` exists in `Features/Settings/`
- 8 sections matching CONTEXT.md Section 18 structure
- Assistant name TextField with validation warnings
- Wake phrases auto-generated and displayed
- Wake response picker with preset + custom + random toggle
- 5 response style options with checkmark for selected
- 6 intent rows navigating to detail view
- Voice response length picker (3 options)
- Auto-send and TTS toggles
- Privacy description under global wake toggle
</acceptance_criteria>
</task>

<task id="5.2" type="execute">
<title>Create IntentResponseStyleView</title>
<read_first>
- LiiO_EatClean/Data/Models/AssistantVoiceSettings.swift (from Plan 1)
- .planning/phases/30-voice-assistant/30-CONTEXT.md (Section 5: Per-Intent Styles)
</read_first>
<action>
Create `LiiO_EatClean/Features/Settings/IntentResponseStyleView.swift`:

Detail view for customizing response style per intent.

```swift
struct IntentResponseStyleView: View {
    let intentKey: String
    let intentTitle: String
    @Environment(AssistantVoiceSettings.self) var settings
    @State private var showingTemplateEditor = false
    
    // Each intent has its own options
    var options: [(id: String, title: String, description: String)] {
        switch intentKey {
        case "meal_logging":
            return [
                ("confirm_short", "Xác nhận ngắn", "Đã log món này cho bạn."),
                ("confirm_cal", "Xác nhận + calo", "Đã log, khoảng X kcal."),
                ("confirm_macro", "Xác nhận + macro", "Đã log, X kcal và Xg protein."),
                ("confirm_suggest", "Xác nhận + gợi ý", "Đã log. Hôm nay bạn còn thiếu..."),
            ]
        case "plan_question": ...
        case "cooking_advice": ...
        case "health_question": ...
        case "progress_question": ...
        case "rebalance_request": ...
        }
    }
    
    var body: some View {
        List {
            ForEach(options, id: \.id) { option in
                // Radio-style selection
            }
            
            Section {
                Button("Tạo template riêng") { showingTemplateEditor = true }
            }
        }
        .navigationTitle(intentTitle)
    }
}
```

Include template editor sheet with variable hints (e.g., {foodName}, {calories}).
</action>
<acceptance_criteria>
- File `IntentResponseStyleView.swift` exists in `Features/Settings/`
- Each of 6 intents shows its specific option list
- Radio-style selection (checkmark on selected)
- "Tạo template riêng" button opens template editor
- Template editor shows available variables for the intent
- Selected style saved to `settings.intentResponseStyles[intentKey]`
</acceptance_criteria>
</task>

<task id="5.3" type="execute">
<title>Add navigation to Voice Settings from AI Coach</title>
<read_first>
- LiiO_EatClean/Features/Chat/ChatView.swift
</read_first>
<action>
In `ChatView.swift`, add navigation to `VoiceAssistantSettingsView` from the existing brain icon (or add a new mic icon in toolbar):

```swift
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        NavigationLink(destination: VoiceAssistantSettingsView()) {
            Image(systemName: "mic.badge.plus")
                .foregroundColor(.secondary)
        }
    }
}
```

Or integrate into existing settings sheet if brain icon already opens a settings view.
</action>
<acceptance_criteria>
- Voice settings accessible from AI Coach tab toolbar
- Navigation to `VoiceAssistantSettingsView` works without crash
- Back button returns to AI Coach
</acceptance_criteria>
</task>

## Verification
- All settings persist across app restart (via @AppStorage)
- Changing assistant name updates wake phrases in real-time
- Custom wake responses can be added/removed
- Per-intent style selection saves and loads correctly

## Must Haves
- Settings use @AppStorage — no CoreData needed
- Assistant name NOT hard-coded anywhere
- Wake phrases auto-generated from name
- All 6 intents have customizable response styles
