import Foundation

struct VoiceResponseTextFormatter {
    /// Formats AI response text to be more speech-friendly
    static func formatForSpeech(_ text: String, assistantName: String = "LiiO") -> String {
        var formatted = text
        
        // 1. Replace placeholder for assistant name
        formatted = formatted.replacingOccurrences(of: "{assistantName}", with: assistantName)
        
        // 2. Remove Emojis and Symbols
        formatted = formatted.filter { !$0.isEmoji }
        
        // 3. Remove common Markdown symbols
        formatted = formatted.replacingOccurrences(of: "\\*\\*", with: "", options: .regularExpression)
        formatted = formatted.replacingOccurrences(of: "\\*", with: "", options: .regularExpression)
        formatted = formatted.replacingOccurrences(of: "#", with: "")
        formatted = formatted.replacingOccurrences(of: "`", with: "")
        formatted = formatted.replacingOccurrences(of: "👉", with: "")
        formatted = formatted.replacingOccurrences(of: "✅", with: "")
        formatted = formatted.replacingOccurrences(of: "✨", with: "")
        formatted = formatted.replacingOccurrences(of: "🎙️", with: "")
        
        // 4. Normalize casual stretched words (e.g. "aloooo" -> "alo")
        formatted = formatted.replacingOccurrences(of: "([a-z])\\1{2,}", with: "$1", options: [.regularExpression, .caseInsensitive])
        
        // 5. Normalize units for Vietnamese voices
        // Calories
        formatted = formatted.replacingOccurrences(of: "kcal", with: "ki lô ca lo")
        formatted = formatted.replacingOccurrences(of: "Calorie", with: "ca lo", options: .caseInsensitive)
        
        // Weight
        formatted = formatted.replacingOccurrences(of: "(\\d+)g", with: "$1 gram", options: .regularExpression)
        formatted = formatted.replacingOccurrences(of: "(\\d+)kg", with: "$1 ki lô gam", options: .regularExpression)
        
        // Macros
        formatted = formatted.replacingOccurrences(of: "P/C/F", with: "Chất đạm, tinh bột và chất béo")
        formatted = formatted.replacingOccurrences(of: "\\bP\\b", with: "protein", options: .regularExpression)
        formatted = formatted.replacingOccurrences(of: "\\bC\\b", with: "tinh bột", options: .regularExpression)
        formatted = formatted.replacingOccurrences(of: "\\bF\\b", with: "chất béo", options: .regularExpression)
        
        // 6. Handle abbreviations & punctuation
        formatted = formatted.replacingOccurrences(of: "v.v.", with: "vân vân")
        formatted = formatted.replacingOccurrences(of: "LiiO", with: assistantName) // Force replacement if hardcoded
        formatted = formatted.replacingOccurrences(of: "[-–—]", with: ",", options: .regularExpression) // Replace dashes with pauses
        formatted = formatted.replacingOccurrences(of: "\\bmày\\b", with: "bạn", options: [.regularExpression, .caseInsensitive]) // Safety replacement
        
        // 7. Cleanup excessive whitespace
        formatted = formatted.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        return formatted.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension Character {
    var isEmoji: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmoji && (scalar.value > 0x238C || scalar.properties.isEmojiPresentation)
    }
}
