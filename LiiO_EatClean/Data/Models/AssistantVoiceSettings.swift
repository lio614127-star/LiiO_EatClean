import Foundation
import SwiftUI

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

@Observable
class AssistantVoiceSettings {
    // Core
    @ObservationIgnored @AppStorage("assistantName") var assistantName: String = "LiiO"
    @ObservationIgnored @AppStorage("globalWakeEnabled") var globalWakeEnabled: Bool = false
    @ObservationIgnored @AppStorage("voiceReplyEnabled") var voiceReplyEnabled: Bool = false
    @ObservationIgnored @AppStorage("autoSendAfterSpeech") var autoSendAfterSpeech: Bool = true
    
    // Wake Responses
    @ObservationIgnored @AppStorage("wakeResponseMode") var wakeResponseMode: String = "fixed" // fixed | random
    @ObservationIgnored @AppStorage("selectedWakeResponse") var selectedWakeResponse: String = "Mình nghe đây."
    @ObservationIgnored @AppStorage("randomizeEnabled") var randomizeEnabled: Bool = false
    
    // Response Style
    @ObservationIgnored @AppStorage("defaultResponseStyle") var defaultResponseStyle: String = "friendly"
    @ObservationIgnored @AppStorage("voiceResponseLength") var voiceResponseLength: String = "moderate"
    
    // Custom data (JSON-encoded in UserDefaults)
    var customWakeResponses: [String] {
        get {
            guard let data = UserDefaults.standard.data(forKey: "customWakeResponses"),
                  let decoded = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return decoded
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: "customWakeResponses")
            }
        }
    }
    
    var enabledWakeResponses: [String] {
        get {
            guard let data = UserDefaults.standard.data(forKey: "enabledWakeResponses"),
                  let decoded = try? JSONDecoder().decode([String].self, from: data) else {
                return AssistantVoiceSettings.presetWakeResponses
            }
            return decoded
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: "enabledWakeResponses")
            }
        }
    }
    
    var intentResponseStyles: [String: String] {
        get {
            guard let data = UserDefaults.standard.data(forKey: "intentResponseStyles"),
                  let decoded = try? JSONDecoder().decode([String: String].self, from: data) else {
                return [:]
            }
            return decoded
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: "intentResponseStyles")
            }
        }
    }
    
    var customIntentTemplates: [String: String] {
        get {
            guard let data = UserDefaults.standard.data(forKey: "customIntentTemplates"),
                  let decoded = try? JSONDecoder().decode([String: String].self, from: data) else {
                return [:]
            }
            return decoded
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: "customIntentTemplates")
            }
        }
    }
    
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
        if wakeResponseMode == "random" || randomizeEnabled {
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
