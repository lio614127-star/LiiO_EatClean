import Foundation

struct ParsedAppAction {
    let actions: [AppAction]
    let confidence: Double
    let spokenResponse: String
    let processingText: String
    let shouldBypassLLM: Bool
}

struct VoiceCommandActionParser {
    static func parse(_ transcript: String) -> ParsedAppAction? {
        let raw = transcript.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = normalize(raw)
        
        print("[ActionParser] raw='\(raw)'")
        print("[ActionParser] normalized='\(normalized)'")
        
        // 1. Try parse WEIGHT LOGGING first (contains numbers)
        let weightPattern = "(?:them can nang|ghi can nang|hom nay toi nang|luu can nang|nang|them can|ghi can)\\s*([0-9]+(?:[.,][0-9]+)?)\\s*(?:ky|kg|kilogam)"
        if let weightValue = matchNumber(normalized, pattern: weightPattern) {
            print("[ActionParser] matched weight tracking, value=\(weightValue)")
            return ParsedAppAction(
                actions: [.addWeight(weightValue, Date())],
                confidence: 0.95,
                spokenResponse: "Mình đã lưu cân nặng \(String(format: "%.1f", weightValue)) kg cho hôm nay.",
                processingText: "Đang lưu \(String(format: "%.1f", weightValue)) kg...",
                shouldBypassLLM: true
            )
        }
        
        // 2. Try parse PROGRESS CHARTS DETAILED ("xem can nang 7 ngay", "xem calo 30 ngay", "mo bieu do nuoc tuan nay")
        let progressKeywords = ["xem can nang", "xem calo", "xem protein", "xem dinh duong", "mo bieu do", "bieu do", "tien do"]
        let isProgressCommand = progressKeywords.contains { normalized.contains($0) }
        let hasRangeOrMetric = normalized.contains("can nang") || normalized.contains("calo") || normalized.contains("7 ngay") || normalized.contains("30 ngay") || normalized.contains("tuan nay") || normalized.contains("thang nay")
        
        if isProgressCommand && hasRangeOrMetric {
            var actions: [AppAction] = [.switchTab(.progress)]
            var spokenResponse = "Đã mở Tiến độ."
            
            // Determine Metric
            if normalized.contains("can nang") || normalized.contains("weight") {
                actions.append(.openProgressMetric(.weight))
                spokenResponse = "Mình đã mở biểu đồ cân nặng."
            } else if normalized.contains("calo") || normalized.contains("calorie") {
                actions.append(.openProgressMetric(.calories))
                spokenResponse = "Mình đã mở biểu đồ Calo."
            } else if normalized.contains("ky luat") || normalized.contains("adherence") {
                actions.append(.openProgressMetric(.adherence))
                spokenResponse = "Mình đã mở biểu đồ kỷ luật."
            }
            
            // Determine Range
            if normalized.contains("7 ngay") || normalized.contains("tuan nay") {
                actions.append(.setProgressRange(.week))
                spokenResponse += " trong tuần qua."
            } else if normalized.contains("30 ngay") || normalized.contains("thang nay") {
                actions.append(.setProgressRange(.month))
                spokenResponse += " trong 30 ngày."
            }
            
            print("[ActionParser] matched progress routing detailed, confidence=0.9")
            return ParsedAppAction(
                actions: actions,
                confidence: 0.9,
                spokenResponse: spokenResponse,
                processingText: "Đang mở biểu đồ...",
                shouldBypassLLM: true
            )
        }
        
        // 3. GENERALIZED NAVIGATION ENGINE
        
        // Navigation Verbs
        let navigationVerbs = [
            "chuyen qua", "chuyen sang", "qua", "mo", "di toi", 
            "vao", "toi", "xem", "bat", "ve", "quay ve", "den"
        ]
        
        // Structural Context Words (Tab, page, etc.)
        let structuralWords = ["tab", "tap", "muc", "trang", "manhinh", "phan", "khu", "giao dien"]
        
        // Check presence of Navigation verb or Structural keyword
        let hasNavigationVerb = navigationVerbs.contains { normalized.contains($0) }
        let hasStructuralWord = structuralWords.contains { normalized.contains($0) }
        
        // Match Destination Tab
        if let dest = detectDestination(normalized) {
            // If we have Navigation intention OR explicit structure OR it's highly unambiguous standalone
            if hasNavigationVerb || hasStructuralWord || dest.isHighConfidenceStandalone {
                print("[ActionParser] matched switchTab(\(dest.tab)), confidence=0.95")
                return ParsedAppAction(
                    actions: [.switchTab(dest.tab)],
                    confidence: 0.95,
                    spokenResponse: dest.response,
                    processingText: "Đang mở...",
                    shouldBypassLLM: true
                )
            }
        }
        
        print("[ActionParser] no local action matched")
        return nil
    }
    
    private struct DestinationMatch {
        let tab: AppTab
        let response: String
        let isHighConfidenceStandalone: Bool
    }
    
    private static func detectDestination(_ text: String) -> DestinationMatch? {
        // 1. Home
        let homeKeys = ["home", "trang chu", "manhinh chinh", "chinh"]
        if homeKeys.contains(where: { text.contains($0) }) {
            return DestinationMatch(tab: .home, response: "Mình đã mở trang chủ.", isHighConfidenceStandalone: text.contains("trang chu") || text == "home")
        }
        
        // 2. Progress
        let progressKeys = ["progress", "tien do", "bieu do", "chart"]
        if progressKeys.contains(where: { text.contains($0) }) {
            return DestinationMatch(tab: .progress, response: "Mình đã mở tiến độ.", isHighConfidenceStandalone: text.contains("tien do") || text.contains("bieu do") || text == "progress")
        }
        
        // 3. AI Coach
        let coachKeys = ["ai coach", "coach", "chat", "tro ly", "hoi ai"]
        if coachKeys.contains(where: { text.contains($0) }) {
            return DestinationMatch(tab: .chat, response: "Mình đã mở AI Coach.", isHighConfidenceStandalone: text.contains("ai coach") || text.contains("tro ly") || text == "chat")
        }
        
        // 4. Meals / Planning
        let mealsKeys = ["meals", "meal", "bua an", "mon an", "nhat ky an", "lich su an", "ke hoach", "thuc don", "plan", "daily plan"]
        if mealsKeys.contains(where: { text.contains($0) }) {
            let response = text.contains("ke hoach") || text.contains("thuc don") ? "Mình đã mở kế hoạch." : "Mình đã mở bữa ăn."
            return DestinationMatch(tab: .meals, response: response, isHighConfidenceStandalone: text.contains("bua an") || text.contains("ke hoach") || text == "meals")
        }
        
        // 5. Profile
        let profileKeys = ["profile", "ho so", "ca nhan", "cai dat"]
        if profileKeys.contains(where: { text.contains($0) }) {
            return DestinationMatch(tab: .profile, response: "Mình đã mở hồ sơ.", isHighConfidenceStandalone: text.contains("ho so") || text == "profile")
        }
        
        return nil
    }
    
    private static func normalize(_ raw: String) -> String {
        var text = raw.lowercased().folding(options: .diacriticInsensitive, locale: Locale(identifier: "vi"))
        
        // Normalize 'tap' -> 'tab' and contract multi-words
        text = text.replacingOccurrences(of: "tap", with: "tab")
        text = text.replacingOccurrences(of: "man hinh", with: "manhinh")
        
        // Collapse multiple spaces
        text = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private static func matchNumber(_ text: String, pattern: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        if let match = regex.firstMatch(in: text, options: [], range: nsRange),
           let valRange = Range(match.range(at: 1), in: text) {
            let rawStr = String(text[valRange]).replacingOccurrences(of: ",", with: ".")
            return Double(rawStr)
        }
        return nil
    }
}
