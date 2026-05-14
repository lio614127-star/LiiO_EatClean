import Foundation

struct WakeMatchResult {
    let isMatch: Bool
    let matchedBy: String
    let rawTranscript: String
    let normalizedTranscript: String
    let commandRemainder: String?
}

class WakePhraseDetector {
    private var assistantName: String = "LiiO"
    private(set) var currentWakePhrases: [String] = []
    private(set) var assistantAliases: [String] = []
    
    // Configurable trigger words
    private let triggerWords = ["hey", "hay", "hayy", "hây", "alo", "e", "ê", "ok", "okey"]
    private let suffixTriggers = ["oi", "ơi"]
    
    init(assistantName: String) {
        updateAssistantName(assistantName)
    }
    
    func updateAssistantName(_ name: String) {
        let sanitized = sanitizeName(name)
        self.assistantName = sanitized
        self.assistantAliases = generateAliases(for: sanitized)
        self.currentWakePhrases = generateWakePhrases(name: sanitized, aliases: assistantAliases)
    }
    
    func checkWakePhrase(_ transcript: String) -> WakeMatchResult {
        let normalized = normalize(transcript)
        
        // Helper to extract remainder from raw transcript based on normalized match
        func getRemainder(matchedPattern: String) -> String? {
            guard let range = normalized.range(of: matchedPattern) else { return nil }
            let remainderNorm = String(normalized[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            if remainderNorm.isEmpty { return nil }
            
            // We have a remainder in normalized. Now let's map back to the raw transcript if possible, 
            // or just use the normalized one if we can't easily map.
            // A simple way is to split raw transcript by whitespace, and skip the number of words corresponding to the pattern.
            let patternWordCount = matchedPattern.components(separatedBy: .whitespaces).filter { !$0.isEmpty }.count
            let rawWords = transcript.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            if rawWords.count > patternWordCount {
                let remainderWords = rawWords.dropFirst(patternWordCount)
                return remainderWords.joined(separator: " ")
            }
            return remainderNorm
        }
        
        // 1. Check direct phrases (stable list)
        for phrase in currentWakePhrases {
            let normalizedPhrase = normalize(phrase)
            if normalized.contains(normalizedPhrase) {
                return WakeMatchResult(
                    isMatch: true,
                    matchedBy: "direct_phrase: \(normalizedPhrase)",
                    rawTranscript: transcript,
                    normalizedTranscript: normalized,
                    commandRemainder: getRemainder(matchedPattern: normalizedPhrase)
                )
            }
        }
        
        // 2. Check Trigger + Alias (e.g. "hay" + "may")
        for trigger in triggerWords {
            for alias in assistantAliases {
                let combined = "\(trigger) \(alias)"
                if normalized.contains(combined) {
                    // Safety check for "may": only match if it has a clear trigger
                    if alias == "may" && !triggerWords.contains(trigger) {
                        continue
                    }
                    
                    return WakeMatchResult(
                        isMatch: true,
                        matchedBy: "trigger+alias: \(trigger) + \(alias)",
                        rawTranscript: transcript,
                        normalizedTranscript: normalized,
                        commandRemainder: getRemainder(matchedPattern: combined)
                    )
                }
            }
        }
        
        // 3. Check Alias + Suffix (e.g. "lio" + "oi")
        for alias in assistantAliases {
            for suffix in suffixTriggers {
                let combined = "\(alias) \(suffix)"
                let normalizedSuffix = normalize(suffix)
                let combinedNormalized = "\(alias) \(normalizedSuffix)"
                
                if normalized.contains(combinedNormalized) {
                    return WakeMatchResult(
                        isMatch: true,
                        matchedBy: "alias+suffix: \(alias) + \(normalizedSuffix)",
                        rawTranscript: transcript,
                        normalizedTranscript: normalized,
                        commandRemainder: getRemainder(matchedPattern: combinedNormalized)
                    )
                }
            }
        }
        
        return WakeMatchResult(
            isMatch: false,
            matchedBy: "none",
            rawTranscript: transcript,
            normalizedTranscript: normalized,
            commandRemainder: nil
        )
    }
    
    // For backward compatibility but returns boolean
    func containsWakePhrase(_ transcript: String) -> Bool {
        return checkWakePhrase(transcript).isMatch
    }
    
    func normalize(_ text: String) -> String {
        var normalized = text.lowercased()
        
        // Remove accents (Vietnamese)
        normalized = normalized.folding(options: .diacriticInsensitive, locale: .current)
        
        // Replace Vietnamese specific characters that folding might miss
        normalized = normalized.replacingOccurrences(of: "đ", with: "d")
        
        // Remove punctuation
        let punctuation = CharacterSet.punctuationCharacters
        normalized = normalized.components(separatedBy: punctuation).joined()
        
        // Collapse spaces
        normalized = normalized.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        normalized = normalized.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Phonetic normalize "ơi" -> "oi"
        normalized = normalized.replacingOccurrences(of: " ơi", with: " oi")
        if normalized.hasSuffix("ơi") { normalized = String(normalized.dropLast(2)) + "oi" }
        
        // Phonetic normalize "LiiO" variations
        normalized = normalized.replacingOccurrences(of: "lii o", with: "lio")
        normalized = normalized.replacingOccurrences(of: "li o", with: "lio")
        normalized = normalized.replacingOccurrences(of: "li ô", with: "lio")
        normalized = normalized.replacingOccurrences(of: "liô", with: "lio")
        normalized = normalized.replacingOccurrences(of: "liio", with: "lio")
        
        // Normalize triggers
        normalized = normalized.replacingOccurrences(of: "hay", with: "hey")
        normalized = normalized.replacingOccurrences(of: "hây", with: "hey")
        
        return normalized
    }
    
    private func sanitizeName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "LiiO" }
        
        // Prevent names that are too short or common (unless it's LiiO)
        let lower = trimmed.lowercased()
        let forbidden = ["mày", "tao", "ơi", "hey", "alo", "bạn", "tôi", "anh", "em", "nó"]
        if forbidden.contains(lower) && lower != "liio" && lower != "lio" {
            return "LiiO"
        }
        
        return String(trimmed.prefix(20))
    }
    
    private func generateAliases(for name: String) -> [String] {
        let normalizedName = normalize(name)
        var aliases = [normalizedName]
        
        if normalizedName == "lio" || normalizedName == "liio" {
            aliases.append(contentsOf: ["lio", "liio", "li o", "leo", "liu", "li ô", "liô"])
            // Fallback for speech recognition error "Hay mày" or "Hey mày"
            // This is ONLY for transcript matching, never for TTS output.
            aliases.append("may")
        }
        
        return Array(Set(aliases))
    }
    
    private func generateWakePhrases(name: String, aliases: [String]) -> [String] {
        var phrases: [String] = []
        
        for alias in aliases {
            phrases.append("\(alias) ơi")
            phrases.append("hey \(alias)")
            phrases.append("alo \(alias)")
            phrases.append("e \(alias)")
            phrases.append("ok \(alias)")
        }
        
        phrases.append("trợ lý ơi")
        
        return Array(Set(phrases))
    }
}
