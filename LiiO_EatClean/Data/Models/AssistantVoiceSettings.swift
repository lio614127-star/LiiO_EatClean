import Foundation
import SwiftUI
import Combine

enum AssistantResponseStyle: String, CaseIterable, Codable {
    case concise = "concise"
    case friendly = "friendly"
    case strictCoach = "strictCoach"
    case cute = "cute"
    case nutritionExpert = "nutritionExpert"
    
    var displayName: String {
        switch self {
        case .concise: return "Ngắn gọn"
        case .friendly: return "Thân thiện"
        case .strictCoach: return "Nghiêm khắc"
        case .cute: return "Dễ thương"
        case .nutritionExpert: return "Chuyên gia"
        }
    }
    
    var description: String {
        switch self {
        case .concise: return "Trả lời tối đa 1-3 câu, đi thẳng vào ý chính."
        case .friendly: return "Trả lời tự nhiên, gần gũi, có động viên nhẹ. 2-4 câu."
        case .strictCoach: return "Trả lời rõ ràng, thực tế, tập trung mục tiêu. Không rào trước."
        case .cute: return "Trả lời ấm áp, vui vẻ, nhẹ nhàng. Có emoji nhẹ nếu phù hợp."
        case .nutritionExpert: return "Phân tích kỹ hơn, có lý do dinh dưỡng. Vẫn ngắn gọn."
        }
    }
    
    var promptInstruction: String {
        description
    }
}

enum VoiceResponseLength: String, CaseIterable, Codable {
    case veryShort = "veryShort"
    case moderate = "moderate"
    case detailed = "detailed"
    
    var displayName: String {
        switch self {
        case .veryShort: return "Rất ngắn (1 câu)"
        case .moderate: return "Vừa phải (2-3 câu)"
        case .detailed: return "Chi tiết (4+ câu)"
        }
    }
    
    var promptInstruction: String {
        switch self {
        case .veryShort: return "Chỉ trả lời bằng 1 câu duy nhất."
        case .moderate: return "Trả lời vừa đủ trong 2 đến 3 câu."
        case .detailed: return "Trả lời chi tiết, có thể dài từ 4 câu trở lên."
        }
    }
}

struct WakeResponseOption: Identifiable, Codable, Equatable {
    var id: String
    var text: String
    var isCustom: Bool = false
}

@Observable
class AssistantVoiceSettings {
    // MARK: - AppStorage Properties with Manual Observation
    
    var assistantName: String {
        get {
            access(keyPath: \.assistantName)
            return UserDefaults.standard.string(forKey: "assistantName") ?? "LiiO"
        }
        set {
            withMutation(keyPath: \.assistantName) {
                UserDefaults.standard.set(newValue, forKey: "assistantName")
                NotificationCenter.default.post(name: NSNotification.Name("AssistantNameChanged"), object: newValue)
            }
        }
    }
    
    var globalWakeEnabled: Bool {
        get {
            access(keyPath: \.globalWakeEnabled)
            return UserDefaults.standard.bool(forKey: "globalWakeEnabled")
        }
        set {
            withMutation(keyPath: \.globalWakeEnabled) {
                UserDefaults.standard.set(newValue, forKey: "globalWakeEnabled")
            }
        }
    }
    
    var voiceReplyEnabled: Bool {
        get {
            access(keyPath: \.voiceReplyEnabled)
            return UserDefaults.standard.bool(forKey: "voiceReplyEnabled")
        }
        set {
            withMutation(keyPath: \.voiceReplyEnabled) {
                UserDefaults.standard.set(newValue, forKey: "voiceReplyEnabled")
            }
        }
    }
    
    var autoSendAfterSpeech: Bool {
        get {
            access(keyPath: \.autoSendAfterSpeech)
            // Default to true
            if UserDefaults.standard.object(forKey: "autoSendAfterSpeech") == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: "autoSendAfterSpeech")
        }
        set {
            withMutation(keyPath: \.autoSendAfterSpeech) {
                UserDefaults.standard.set(newValue, forKey: "autoSendAfterSpeech")
            }
        }
    }
    
    var wakeResponseMode: String {
        get {
            access(keyPath: \.wakeResponseMode)
            return UserDefaults.standard.string(forKey: "wakeResponseMode") ?? "fixed"
        }
        set {
            withMutation(keyPath: \.wakeResponseMode) {
                UserDefaults.standard.set(newValue, forKey: "wakeResponseMode")
            }
        }
    }
    
    var selectedWakeResponseId: String {
        get {
            access(keyPath: \.selectedWakeResponseId)
            return UserDefaults.standard.string(forKey: "selectedWakeResponseId") ?? "wake_minh_nghe_day"
        }
        set {
            withMutation(keyPath: \.selectedWakeResponseId) {
                UserDefaults.standard.set(newValue, forKey: "selectedWakeResponseId")
            }
        }
    }
    
    var assistantNamePronunciation: String {
        get {
            access(keyPath: \.assistantNamePronunciation)
            return UserDefaults.standard.string(forKey: "assistantNamePronunciation") ?? ""
        }
        set {
            withMutation(keyPath: \.assistantNamePronunciation) {
                UserDefaults.standard.set(newValue, forKey: "assistantNamePronunciation")
            }
        }
    }
    
    var assistantSpokenName: String {
        assistantNamePronunciation.isEmpty ? assistantName : assistantNamePronunciation
    }
    
    var defaultResponseStyle: String {
        get {
            access(keyPath: \.defaultResponseStyle)
            return UserDefaults.standard.string(forKey: "defaultResponseStyle") ?? "friendly"
        }
        set {
            withMutation(keyPath: \.defaultResponseStyle) {
                UserDefaults.standard.set(newValue, forKey: "defaultResponseStyle")
            }
        }
    }
    
    var voiceResponseLength: String {
        get {
            access(keyPath: \.voiceResponseLength)
            return UserDefaults.standard.string(forKey: "voiceResponseLength") ?? "moderate"
        }
        set {
            withMutation(keyPath: \.voiceResponseLength) {
                UserDefaults.standard.set(newValue, forKey: "voiceResponseLength")
            }
        }
    }
    
    var ttsEngineMode: String {
        get {
            access(keyPath: \.ttsEngineMode)
            return UserDefaults.standard.string(forKey: "ttsEngineMode") ?? "auto"
        }
        set {
            withMutation(keyPath: \.ttsEngineMode) {
                UserDefaults.standard.set(newValue, forKey: "ttsEngineMode")
            }
        }
    }
    
    var selectedTTSVoice: String {
        get {
            access(keyPath: \.selectedTTSVoice)
            return UserDefaults.standard.string(forKey: "selectedTTSVoice") ?? "vi-VN-HoaiMyNeural"
        }
        set {
            withMutation(keyPath: \.selectedTTSVoice) {
                UserDefaults.standard.set(newValue, forKey: "selectedTTSVoice")
            }
        }
    }
    
    var ttsRate: Double {
        get {
            access(keyPath: \.ttsRate)
            let val = UserDefaults.standard.double(forKey: "ttsRate")
            return val == 0 ? 1.0 : val // 1.0 is default/normal
        }
        set {
            withMutation(keyPath: \.ttsRate) {
                UserDefaults.standard.set(newValue, forKey: "ttsRate")
            }
        }
    }
    
    var ttsPitch: Double {
        get {
            access(keyPath: \.ttsPitch)
            let val = UserDefaults.standard.double(forKey: "ttsPitch")
            return val == 0 ? 1.0 : val
        }
        set {
            withMutation(keyPath: \.ttsPitch) {
                UserDefaults.standard.set(newValue, forKey: "ttsPitch")
            }
        }
    }
    
    var ttsVolume: Double {
        get {
            access(keyPath: \.ttsVolume)
            let val = UserDefaults.standard.double(forKey: "ttsVolume")
            return val == 0 ? 1.0 : val
        }
        set {
            withMutation(keyPath: \.ttsVolume) {
                UserDefaults.standard.set(newValue, forKey: "ttsVolume")
            }
        }
    }
    
    // MARK: - Custom Data Storage (JSON)
    
    var customWakeResponses: [WakeResponseOption] {
        get {
            access(keyPath: \.customWakeResponses)
            guard let data = UserDefaults.standard.data(forKey: "customWakeResponses_v2"),
                  let decoded = try? JSONDecoder().decode([WakeResponseOption].self, from: data) else {
                return []
            }
            return decoded
        }
        set {
            withMutation(keyPath: \.customWakeResponses) {
                if let encoded = try? JSONEncoder().encode(newValue) {
                    UserDefaults.standard.set(encoded, forKey: "customWakeResponses_v2")
                }
            }
        }
    }
    
    var enabledRandomResponseIds: Set<String> {
        get {
            access(keyPath: \.enabledRandomResponseIds)
            guard let data = UserDefaults.standard.data(forKey: "enabledRandomResponseIds"),
                  let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) else {
                return Set(["wake_minh_nghe_day", "wake_minh_day_noi_di", "wake_co_minh_day"])
            }
            return decoded
        }
        set {
            withMutation(keyPath: \.enabledRandomResponseIds) {
                if let encoded = try? JSONEncoder().encode(newValue) {
                    UserDefaults.standard.set(encoded, forKey: "enabledRandomResponseIds")
                }
            }
        }
    }
    
    var intentResponseStyles: [String: String] {
        get {
            access(keyPath: \.intentResponseStyles)
            guard let data = UserDefaults.standard.data(forKey: "intentResponseStyles"),
                  let decoded = try? JSONDecoder().decode([String: String].self, from: data) else {
                return [:]
            }
            return decoded
        }
        set {
            withMutation(keyPath: \.intentResponseStyles) {
                if let encoded = try? JSONEncoder().encode(newValue) {
                    UserDefaults.standard.set(encoded, forKey: "intentResponseStyles")
                }
            }
        }
    }
    
    // MARK: - Static Data
    
    static let presetWakeResponses: [WakeResponseOption] = [
        WakeResponseOption(id: "wake_minh_nghe_day", text: "Mình nghe đây."),
        WakeResponseOption(id: "wake_minh_day_noi_di", text: "Mình đây, bạn nói đi."),
        WakeResponseOption(id: "wake_co_minh_day", text: "Có mình đây."),
        WakeResponseOption(id: "wake_san_sang", text: "Mình sẵn sàng hỗ trợ bạn."),
        WakeResponseOption(id: "wake_can_giup_gi", text: "Bạn cần mình giúp gì?"),
        WakeResponseOption(id: "wake_noi_nghe_ne", text: "Nói mình nghe nè."),
        WakeResponseOption(id: "wake_to_day", text: "Tớ đây."),
        WakeResponseOption(id: "wake_coach_day", text: "Coach đây, nói đi nào.")
    ]
    
    var allWakeResponses: [WakeResponseOption] {
        AssistantVoiceSettings.presetWakeResponses + customWakeResponses
    }
    
    // MARK: - Logic
    
    func getWakeResponse() -> String {
        let responses = allWakeResponses
        
        if wakeResponseMode == "random" {
            let enabled = responses.filter { enabledRandomResponseIds.contains($0.id) }
            return enabled.randomElement()?.text ?? responses.first?.text ?? "Mình nghe đây."
        } else {
            return responses.first { $0.id == selectedWakeResponseId }?.text ?? responses.first?.text ?? "Mình nghe đây."
        }
    }
    
    func getResponseStyle(for intent: String) -> AssistantResponseStyle {
        if let style = intentResponseStyles[intent],
           let parsed = AssistantResponseStyle(rawValue: style) {
            return parsed
        }
        return AssistantResponseStyle(rawValue: defaultResponseStyle) ?? .friendly
    }
    
    func setResponseStyle(_ style: AssistantResponseStyle, for intent: String) {
        var current = intentResponseStyles
        current[intent] = style.rawValue
        intentResponseStyles = current
    }
    
    func addCustomWakeResponse(_ text: String) {
        var current = customWakeResponses
        let newOption = WakeResponseOption(id: UUID().uuidString, text: text, isCustom: true)
        current.append(newOption)
        customWakeResponses = current
        
        // Auto-select if in fixed mode and nothing selected
        if wakeResponseMode == "fixed" && (selectedWakeResponseId.isEmpty || selectedWakeResponseId == "wake_minh_nghe_day") {
            selectedWakeResponseId = newOption.id
        }
    }
    
    func removeCustomWakeResponse(id: String) {
        var current = customWakeResponses
        current.removeAll { $0.id == id }
        customWakeResponses = current
        
        if selectedWakeResponseId == id {
            selectedWakeResponseId = "wake_minh_nghe_day"
        }
        
        var enabledIds = enabledRandomResponseIds
        enabledIds.remove(id)
        enabledRandomResponseIds = enabledIds
    }
}
