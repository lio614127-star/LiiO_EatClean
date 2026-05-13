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
