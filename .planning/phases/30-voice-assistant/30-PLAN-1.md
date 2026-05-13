---
phase: 30
wave: 1
title: "Voice Foundation — Data Models & Core Services"
depends_on: []
requirements: [VOICE-01, VOICE-02, VOICE-03]
files_modified:
  - LiiO_EatClean/Data/Models/AssistantVoiceSettings.swift
  - LiiO_EatClean/Data/Models/VoiceAssistantState.swift
  - LiiO_EatClean/Services/WakePhraseDetector.swift
  - LiiO_EatClean/Services/TextToSpeechService.swift
autonomous: true
---

# Plan 1: Voice Foundation — Data Models & Core Services

## Goal
Tạo nền tảng dữ liệu và các service cốt lõi cho Voice Assistant: state machine, settings model, wake phrase detector, và TTS service.

## Tasks

<task id="1.1" type="execute">
<title>Create VoiceAssistantState enum</title>
<read_first>
- LiiO_EatClean/Data/Models/ChatMessageModel.swift
- .planning/phases/30-voice-assistant/30-CONTEXT.md (Section 4: State Machine)
</read_first>
<action>
Create `LiiO_EatClean/Data/Models/VoiceAssistantState.swift`:

```swift
import Foundation

enum VoiceAssistantState: String {
    case disabled           // Setting off hoặc thiếu permission
    case idle               // Setting on, chưa start
    case voiceGateListening // Monitor audio level nhẹ (no SFSpeech)
    case wakeChecking       // Audio vượt ngưỡng, SFSpeech 2-3s
    case wakeDetected       // Wake phrase khớp, overlay hiện
    case commandListening   // Nghe câu hỏi/lệnh chính
    case processing         // Gửi AI pipeline
    case speaking           // TTS đang đọc response
    case error              // Lỗi permission/speech/audio
}
```
</action>
<acceptance_criteria>
- File `VoiceAssistantState.swift` exists in `Data/Models/`
- Enum contains exactly 9 cases: disabled, idle, voiceGateListening, wakeChecking, wakeDetected, commandListening, processing, speaking, error
- Enum conforms to `String` for debug logging
</acceptance_criteria>
</task>

<task id="1.2" type="execute">
<title>Create AssistantVoiceSettings model</title>
<read_first>
- LiiO_EatClean/Data/Models/AIPersonalityTone.swift
- .planning/phases/30-voice-assistant/30-CONTEXT.md (Section 16: Data Model)
</read_first>
<action>
Create `LiiO_EatClean/Data/Models/AssistantVoiceSettings.swift`:

```swift
import Foundation
import SwiftUI

enum AssistantResponseStyle: String, CaseIterable, Codable {
    case concise = "concise"
    case friendly = "friendly"
    case strictCoach = "strictCoach"
    case cute = "cute"
    case nutritionExpert = "nutritionExpert"
    
    var displayName: String { ... }
    var description: String { ... }
}

enum VoiceResponseLength: String, CaseIterable, Codable {
    case veryShort = "veryShort"
    case moderate = "moderate"
    case detailed = "detailed"
    
    var displayName: String { ... }
    var promptInstruction: String { ... }
}

@Observable
class AssistantVoiceSettings {
    // Core
    @AppStorage("assistantName") var assistantName: String = "LiiO"
    @AppStorage("globalWakeEnabled") var globalWakeEnabled: Bool = false
    @AppStorage("voiceReplyEnabled") var voiceReplyEnabled: Bool = false
    @AppStorage("autoSendAfterSpeech") var autoSendAfterSpeech: Bool = true
    
    // Wake Responses
    @AppStorage("wakeResponseMode") var wakeResponseMode: String = "fixed" // fixed | random
    @AppStorage("selectedWakeResponse") var selectedWakeResponse: String = "Mình nghe đây."
    
    // Response Style
    @AppStorage("defaultResponseStyle") var defaultResponseStyle: String = "friendly"
    @AppStorage("voiceResponseLength") var voiceResponseLength: String = "moderate"
    
    // Custom data (JSON-encoded in UserDefaults)
    var customWakeResponses: [String] { get/set via UserDefaults }
    var enabledWakeResponses: [String] { get/set via UserDefaults }
    var intentResponseStyles: [String: String] { get/set via UserDefaults }
    var customIntentTemplates: [String: String] { get/set via UserDefaults }
    
    // Preset wake responses
    static let presetWakeResponses: [String] = [
        "Mình nghe đây.",
        "Mình đây, bạn nói đi.",
        "Có mình đây.",
        "Mình sẵn sàng hỗ trợ bạn.",
        "Bạn cần mình giúp gì?",
        "Nói mình nghe nè.",
        "Tớ đây.",
        "Coach đây, nói đi nào."
    ]
    
    func getWakeResponse() -> String {
        if wakeResponseMode == "random" {
            return enabledWakeResponses.randomElement() ?? selectedWakeResponse
        }
        return selectedWakeResponse
    }
    
    func getResponseStyle(for intent: String) -> AssistantResponseStyle {
        if let style = intentResponseStyles[intent],
           let parsed = AssistantResponseStyle(rawValue: style) {
            return parsed
        }
        return AssistantResponseStyle(rawValue: defaultResponseStyle) ?? .friendly
    }
}
```

Include all 6 intent keys: meal_logging, plan_question, cooking_advice, health_question, progress_question, rebalance_request.
</action>
<acceptance_criteria>
- File `AssistantVoiceSettings.swift` exists in `Data/Models/`
- `AssistantResponseStyle` enum has 5 cases: concise, friendly, strictCoach, cute, nutritionExpert
- `VoiceResponseLength` enum has 3 cases: veryShort, moderate, detailed
- `AssistantVoiceSettings` class uses `@AppStorage` for persistence
- `presetWakeResponses` contains exactly 8 preset strings
- `getWakeResponse()` supports fixed and random modes
- `getResponseStyle(for:)` returns per-intent style with fallback to default
</acceptance_criteria>
</task>

<task id="1.3" type="execute">
<title>Create WakePhraseDetector service</title>
<read_first>
- LiiO_EatClean/Services/SpeechRecognitionService.swift
- .planning/phases/30-voice-assistant/30-CONTEXT.md (Section 6: Wake Phrase Matching)
</read_first>
<action>
Create `LiiO_EatClean/Services/WakePhraseDetector.swift`:

```swift
import Foundation

class WakePhraseDetector {
    private var assistantName: String = "LiiO"
    private var wakePhrases: [String] = []
    
    init(assistantName: String = "LiiO") {
        updateAssistantName(assistantName)
    }
    
    func updateAssistantName(_ name: String) {
        self.assistantName = name
        self.wakePhrases = generateWakePhrases(name: name)
    }
    
    func generateWakePhrases(name: String) -> [String] {
        let normalized = normalize(name)
        return [
            "hey \(normalized)",
            "\(normalized) oi",
            "e \(normalized)",
            "alo \(normalized)"
        ]
    }
    
    func normalize(_ text: String) -> String {
        var result = text.lowercased()
        // Remove Vietnamese diacritics
        result = result.folding(options: .diacriticInsensitive, locale: Locale(identifier: "vi"))
        // Remove punctuation
        result = result.components(separatedBy: CharacterSet.punctuationCharacters).joined()
        // Collapse whitespace
        result = result.components(separatedBy: .whitespaces).filter { !$0.isEmpty }.joined(separator: " ")
        return result.trimmingCharacters(in: .whitespaces)
    }
    
    func containsWakePhrase(_ transcript: String) -> Bool {
        let normalizedTranscript = normalize(transcript)
        return wakePhrases.contains { normalizedTranscript.contains($0) }
    }
    
    var isNameTooShort: Bool {
        assistantName.count < 2
    }
    
    var isNameTooCommon: Bool {
        let commonWords = ["ai", "ok", "hey", "hi", "oi", "a"]
        return commonWords.contains(assistantName.lowercased())
    }
}
```

Key: normalize() must handle Vietnamese diacritics (ơ→o, ê→e) using .diacriticInsensitive folding.
Fuzzy match: "hey lio", "lio oi", "li o oi", "e lio", "alo lio" all must match.
</action>
<acceptance_criteria>
- File `WakePhraseDetector.swift` exists in `Services/`
- `normalize("LiiO ơi")` returns `"lio oi"`
- `normalize("Hey LiiO")` returns `"hey lio"`
- `containsWakePhrase("hey lio toi muon")` returns `true`
- `containsWakePhrase("chào buổi sáng")` returns `false`
- `generateWakePhrases(name: "LiiO")` returns array with 4 patterns
- `isNameTooShort` returns true for names < 2 chars
- `isNameTooCommon` returns true for "ai", "ok", "hey"
</acceptance_criteria>
</task>

<task id="1.4" type="execute">
<title>Create TextToSpeechService</title>
<read_first>
- LiiO_EatClean/Services/SpeechRecognitionService.swift
- .planning/phases/30-voice-assistant/30-CONTEXT.md (Section 8: TTS Response)
</read_first>
<action>
Create `LiiO_EatClean/Services/TextToSpeechService.swift`:

```swift
import AVFoundation
import Foundation

@Observable
class TextToSpeechService: NSObject, AVSpeechSynthesizerDelegate {
    var isSpeaking: Bool = false
    var onFinished: (() -> Void)?
    
    private let synthesizer = AVSpeechSynthesizer()
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func speak(_ text: String, rate: Float = 0.52) {
        stop() // Cancel any ongoing speech
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "vi-VN")
        utterance.rate = rate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        isSpeaking = true
        synthesizer.speak(utterance)
    }
    
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }
    
    // AVSpeechSynthesizerDelegate
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.onFinished?()
        }
    }
}
```

Voice: vi-VN (Vietnamese). Rate: 0.52 (natural speed).
</action>
<acceptance_criteria>
- File `TextToSpeechService.swift` exists in `Services/`
- Class uses `AVSpeechSynthesizer` with `vi-VN` voice
- `speak()` cancels any ongoing speech before starting
- `stop()` immediately stops speech and sets `isSpeaking = false`
- `speechSynthesizer(_:didFinish:)` delegate calls `onFinished` callback
- Class is `@Observable` for SwiftUI binding
</acceptance_criteria>
</task>

## Verification
```bash
# All 4 files exist
ls LiiO_EatClean/Data/Models/VoiceAssistantState.swift
ls LiiO_EatClean/Data/Models/AssistantVoiceSettings.swift
ls LiiO_EatClean/Services/WakePhraseDetector.swift
ls LiiO_EatClean/Services/TextToSpeechService.swift
```

## Must Haves
- VoiceAssistantState enum with 9 states matching CONTEXT.md state machine
- AssistantVoiceSettings with @AppStorage persistence
- WakePhraseDetector with Vietnamese diacritics normalization
- TextToSpeechService with vi-VN voice
