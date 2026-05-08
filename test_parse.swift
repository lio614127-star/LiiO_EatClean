import Foundation

let sampleText = """
Đây là kế hoạch tuần của bạn:

```json
{
  "action": "weekly_plan",
  "days": [
    {
      "day": "T2",
      "totalCalories": 1800,
      "highlights": ["Phở bò", "Cơm gà", "Cá hấp"],
      "items": []
    }
  ]
}
```

Chúc bạn ngon miệng!
"""

// 1. Mock AIService parseChatResponse
let pattern = "```json(.*?)```"
let regex = try! NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
let nsString = sampleText as NSString
let results = regex.matches(in: sampleText, options: [], range: NSRange(location: 0, length: nsString.length))

var cleanText = sampleText

if let match = results.last {
    let jsonString = nsString.substring(with: match.range(at: 1))
    
    struct AISuggestedFood: Codable { let name: String }
    struct ActionWrapper: Codable {
        let action: String
        let items: [AISuggestedFood]?
    }
    
    if let data = jsonString.data(using: .utf8),
       let wrapper = try? JSONDecoder().decode(ActionWrapper.self, from: data) {
        if wrapper.action == "suggest_meal" || wrapper.action == "meal_plan" {
            cleanText = nsString.replacingCharacters(in: match.range, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}

print("1. cleanText after AIService: \n---\n\(cleanText)\n---")

// 2. Mock MealPlanViewModel parseWeeklyPlan
func parseWeeklyPlan(_ text: String) {
    var jsonText = text
    
    if let jsonBlockStart = text.range(of: "```json") {
        jsonText = String(text[jsonBlockStart.upperBound...])
        if let jsonBlockEnd = jsonText.range(of: "```") {
            jsonText = String(jsonText[..<jsonBlockEnd.lowerBound])
        }
    }
    
    guard let jsonStart = jsonText.firstIndex(of: "{"),
          let jsonEnd = jsonText.lastIndex(of: "}") else { 
        print("2. Failed to find {} bounds in: \n\(jsonText)")
        return 
    }
    
    let jsonString = String(jsonText[jsonStart...jsonEnd])
    guard let data = jsonString.data(using: .utf8) else { return }
    
    do {
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let days = json["days"] as? [[String: Any]] {
            print("2. SUCCESS: Found \(days.count) days")
            print(days)
        } else {
            print("2. FAILED to parse days from JSON: \(jsonString)")
        }
    } catch {
        print("2. Error: \(error)")
    }
}

parseWeeklyPlan(cleanText)
