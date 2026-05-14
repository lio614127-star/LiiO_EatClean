---
phase: 31
wave: 1
title: "Context Infra — Data Models, Caching & Intent Detection"
depends_on: []
requirements: [VOICE-05]
files_modified:
  - LiiO_EatClean/Features/AI/AICoachContextSnapshot.swift
  - LiiO_EatClean/Features/AI/AICoachContextCache.swift
  - LiiO_EatClean/Features/AI/AICoachIntentDetector.swift
  - LiiO_EatClean/Features/AI/AICoachContextBuilder.swift
  - LiiO_EatClean/Features/AI/ContextBuilder.swift
  - LiiO_EatClean/Data/Repositories/UserRepository.swift
autonomous: true
---

# Plan 1: Context Infra — Data Models, Caching & Intent Detection

## Goal
Thiết lập hạ tầng dữ liệu cốt lõi cho Phase 31: định nghĩa các Enum phân loại trạng thái/dữ liệu thiếu, xây dựng bộ nhận diện Đa ý định (`AICoachIntentDetector`), phát triển lớp `AICoachContextCache` hỗ trợ invalidation qua Notification, và tái cấu trúc sơ bộ các giao diện (Interface stubbing) để duy trì khả năng build của ứng dụng.

## Tasks

<task id="1.1" type="execute">
<title>Refactor AICoachContextSnapshot models</title>
<read_first>
- LiiO_EatClean/Features/AI/AICoachContextSnapshot.swift
- .planning/phases/31-global-context-builder/31-CONTEXT.md (Section 1 & 2)
</read_first>
<action>
1. Khai báo các Models toàn cục mới bên trong `AICoachContextSnapshot.swift` (hoặc ngay phía trên struct):
```swift
import Foundation

enum AICoachContextMode: String, Codable {
    case voice
    case chat
    case planning
    case rebalance
}

enum ContextIntent: String, Codable, CaseIterable {
    case mealLogging
    case todayNutrition
    case dailyPlanStatus
    case dailyPlanGeneration
    case weeklyPlan
    case progress
    case weightTrend
    case adherence
    case metabolic
    case rebalance
    case cooking
    case healthNutrition
    case generalChat
}

enum ContextSection: String, CaseIterable {
    case profileMinimal
    case healthConstraints
    case todayTargets
    case todayMealLogs
    case todayDailyPlan
    case plannedVsActual
    case weeklyPlans
    case recentMealsSummary
    case progressTrend
    case weightTrend
    case adherenceSummary
    case metabolicSummary
    case cookingPreferences
}

enum MissingDataReason: String, Codable {
    case notProvidedByUser
    case notCreatedYet
    case notLoggedYet
    case timedOut
    case unavailable
    case permissionOrStorageError
}

enum ContextQuality: String, Codable {
    case full
    case partial
    case fallback
}

struct DetectedIntent {
    let intent: ContextIntent
    let confidence: Double
    let matchedKeywords: [String]
}
```

2. Cập nhật struct `AICoachContextSnapshot`:
- Xóa enum `ContextIntent` cũ lồng bên trong.
- Thêm thuộc tính:
```swift
    var contextMode: AICoachContextMode = .chat
    var activeIntents: Set<ContextIntent> = [.generalChat]
    var contextQuality: ContextQuality = .full
    var timedOut: Bool = false
    var includedSections: Set<ContextSection> = []
    var missingReasons: [ContextSection: MissingDataReason] = [:]
```
- Tạm thời giữ hàm `toMarkdown()` để không bị lỗi build, chúng ta sẽ tối ưu hóa chi tiết chuỗi format prompt ở Plan 2.
</action>
<acceptance_criteria>
- File `AICoachContextSnapshot.swift` định nghĩa đầy đủ các enum mới: `AICoachContextMode`, `ContextIntent`, `ContextSection`, `MissingDataReason`, `ContextQuality`.
- Struct `AICoachContextSnapshot` chứa `contextQuality`, `timedOut`, và `activeIntents` (Set thay vì single intent).
- Mã nguồn không còn enum `ContextIntent` lồng nhau (nested).
</acceptance_criteria>
</task>

<task id="1.2" type="execute">
<title>Create AICoachIntentDetector</title>
<read_first>
- LiiO_EatClean/Features/AI/AICoachContextSnapshot.swift
- .planning/phases/31-global-context-builder/31-CONTEXT.md (D-09, D-10)
</read_first>
<action>
Tạo file `LiiO_EatClean/Features/AI/AICoachIntentDetector.swift`:
```swift
import Foundation

class AICoachIntentDetector {
    static let shared = AICoachIntentDetector()
    
    private init() {}
    
    func detectContextIntents(
        from text: String,
        currentTab: String? = nil,
        mode: AICoachContextMode = .chat
    ) -> [DetectedIntent] {
        let query = text.lowercased().folding(options: .diacriticInsensitive, locale: Locale(identifier: "vi"))
        var detected: [DetectedIntent] = []
        
        let intentMap: [ContextIntent: [String]] = [
            .mealLogging: ["an", "log", "ghi", "mon an", "bua phu", "sang", "trua", "toi", "vua an", "da an"],
            .todayNutrition: ["calo", "ninh duong", "macro", "nap", "protein", "carb", "fat", "duong", "con lai"],
            .dailyPlanStatus: ["ke hoach", "thuc don", "plan", "hom nay an gi", "dung ke hoach", "co thuc don chua"],
            .dailyPlanGeneration: ["len thuc don", "tao ke hoach", "tinh thuc don", "len plan"],
            .weeklyPlan: ["tuan nay", "ca tuan", "tuan toi"],
            .progress: ["tien do", "adherence", "bieu do", "hieu qua", "tuan thu"],
            .weightTrend: ["can nang", "can", "giam can", "tang can", "xu huong", "kg"],
            .adherence: ["tuan thu", "dung gio", "bo qua", "tuan thu ke hoach"],
            .metabolic: ["metabolic", "tdee", "bmr", "trao doi chat", "co dia", "hap thu"],
            .rebalance: ["rebalance", "can bang lai", "bu calo", "an lo", "quá chén", "an qua"],
            .cooking: ["nau", "che bien", "cong thuc", "nguyen lieu"],
            .healthNutrition: ["di ung", "suc khoe", "benh", "kieng"]
        ]
        
        for (intent, keywords) in intentMap {
            var matched: [String] = []
            for kw in keywords {
                if query.contains(kw) {
                    matched.append(kw)
                }
            }
            
            if !matched.isEmpty {
                // Simple confidence calculation
                let confidence = Double(matched.count) / Double(keywords.count) * 0.5 + 0.5
                detected.append(DetectedIntent(intent: intent, confidence: min(1.0, confidence), matchedKeywords: matched))
            }
        }
        
        // Confidence Filtering (>= 0.45)
        let filtered = detected.filter { $0.confidence >= 0.45 }
        
        if filtered.isEmpty {
            return [DetectedIntent(intent: .generalChat, confidence: 1.0, matchedKeywords: [])]
        }
        
        // Limit to top 4 intents to prevent bloating
        return Array(filtered.sorted(by: { $0.confidence > $1.confidence }).prefix(4))
    }
    
    func mapIntentsToSections(_ intents: Set<ContextIntent>) -> Set<ContextSection> {
        var sections = Set<ContextSection>()
        // Luôn nạp profileMinimal cho mọi intent
        sections.insert(.profileMinimal)
        
        for intent in intents {
            switch intent {
            case .mealLogging, .todayNutrition:
                sections.insert(.todayTargets)
                sections.insert(.todayMealLogs)
            case .dailyPlanStatus, .dailyPlanGeneration:
                sections.insert(.todayTargets)
                sections.insert(.todayMealLogs)
                sections.insert(.todayDailyPlan)
                sections.insert(.plannedVsActual)
            case .weeklyPlan:
                sections.insert(.weeklyPlans)
            case .progress, .weightTrend:
                sections.insert(.progressTrend)
                sections.insert(.weightTrend)
                sections.insert(.adherenceSummary)
            case .adherence:
                sections.insert(.adherenceSummary)
                sections.insert(.plannedVsActual)
            case .metabolic:
                sections.insert(.metabolicSummary)
                sections.insert(.weightTrend)
            case .rebalance:
                sections.insert(.todayMealLogs)
                sections.insert(.todayDailyPlan)
                sections.insert(.plannedVsActual)
            case .cooking:
                sections.insert(.cookingPreferences)
            case .healthNutrition:
                sections.insert(.healthConstraints)
            case .generalChat:
                // Basic info
                sections.insert(.todayTargets)
                sections.insert(.todayMealLogs)
            }
        }
        return sections
    }
}
```
</action>
<acceptance_criteria>
- File `AICoachIntentDetector.swift` tồn tại trong `Features/AI/`.
- Cung cấp hàm `detectContextIntents` trả về mảng các `DetectedIntent` có confidence >= 0.45.
- Hàm `mapIntentsToSections` thực hiện gom nhóm Union các `ContextSection` cần thiết theo Intent.
- Tự động fallback sang `.generalChat` nếu không khớp từ khóa nào.
</acceptance_criteria>
</task>

<task id="1.3" type="execute">
<title>Create AICoachContextCache and Invalidation events</title>
<read_first>
- LiiO_EatClean/Data/Repositories/UserRepository.swift
- .planning/phases/31-global-context-builder/31-CONTEXT.md (D-14, D-15)
</read_first>
<action>
1. Tạo file `LiiO_EatClean/Features/AI/AICoachContextCache.swift`:
```swift
import Foundation

@Observable
class AICoachContextCache {
    static let shared = AICoachContextCache()
    
    // Cache entries using generic Wrapper for timestamp checking
    struct CacheEntry<T> {
        let data: T
        let timestamp: Date
    }
    
    var todayMealLogsCache: CacheEntry<[AICoachContextSnapshot.ActualMealLog]>?
    var todayPlanCache: CacheEntry<AICoachContextSnapshot.DailyPlanSummary?>?
    var profileCache: CacheEntry<AICoachContextSnapshot.ProfileSummary>?
    var metabolicCache: CacheEntry<AICoachContextSnapshot.MetabolicSummary>?
    
    private init() {
        setupObservers()
    }
    
    private func setupObservers() {
        let nc = NotificationCenter.default
        
        nc.addObserver(forName: NSNotification.Name("mealLogDidUpdate"), object: nil, queue: .main) { [weak self] _ in
            self?.invalidateTodayNutrition()
        }
        
        nc.addObserver(forName: NSNotification.Name("mealPlanDidUpdate"), object: nil, queue: .main) { [weak self] _ in
            self?.invalidateTodayPlan()
        }
        
        nc.addObserver(forName: NSNotification.Name("dailyPlanDidConfirm"), object: nil, queue: .main) { [weak self] _ in
            self?.invalidateTodayPlan()
        }
        
        nc.addObserver(forName: NSNotification.Name("userProfileDidUpdate"), object: nil, queue: .main) { [weak self] _ in
            self?.invalidateProfile()
        }
        
        nc.addObserver(forName: NSNotification.Name("weightDidUpdate"), object: nil, queue: .main) { [weak self] _ in
            self?.invalidateProfile()
            self?.invalidateMetabolic()
        }
    }
    
    func invalidateTodayNutrition() {
        todayMealLogsCache = nil
    }
    
    func invalidateTodayPlan() {
        todayPlanCache = nil
    }
    
    func invalidateProfile() {
        profileCache = nil
    }
    
    func invalidateMetabolic() {
        metabolicCache = nil
    }
    
    func clearAll() {
        todayMealLogsCache = nil
        todayPlanCache = nil
        profileCache = nil
        metabolicCache = nil
    }
    
    // Helper functions to fetch safely with TTL
    func getTodayLogs(ttl: TimeInterval = 30) -> [AICoachContextSnapshot.ActualMealLog]? {
        guard let entry = todayMealLogsCache, Date().timeIntervalSince(entry.timestamp) < ttl else { return nil }
        return entry.data
    }
    
    func getTodayPlan(ttl: TimeInterval = 30) -> AICoachContextSnapshot.DailyPlanSummary?? {
        guard let entry = todayPlanCache, Date().timeIntervalSince(entry.timestamp) < ttl else { return nil }
        return entry.data
    }
    
    func getProfile(ttl: TimeInterval = 300) -> AICoachContextSnapshot.ProfileSummary? {
        guard let entry = profileCache, Date().timeIntervalSince(entry.timestamp) < ttl else { return nil }
        return entry.data
    }
    
    func getMetabolic(ttl: TimeInterval = 600) -> AICoachContextSnapshot.MetabolicSummary? {
        guard let entry = metabolicCache, Date().timeIntervalSince(entry.timestamp) < ttl else { return nil }
        return entry.data
    }
}
```

2. Bổ sung post notification vào `LiiO_EatClean/Data/Repositories/UserRepository.swift`:
- Ở cuối hàm `saveUser`: `NotificationCenter.default.post(name: NSNotification.Name("userProfileDidUpdate"), object: nil)` (trước dòng `try self.context.save()`).
- Ở cuối hàm `saveWeightEntry`: `NotificationCenter.default.post(name: NSNotification.Name("weightDidUpdate"), object: nil)`.
</action>
<acceptance_criteria>
- File `AICoachContextCache.swift` tồn tại và được cấu trúc như một Singleton `@Observable`.
- Observer được đăng ký đầy đủ để lắng nghe `mealLogDidUpdate`, `mealPlanDidUpdate`, `dailyPlanDidConfirm`, `userProfileDidUpdate`, `weightDidUpdate`.
- `UserRepository.swift` bắn đầy đủ các event thông báo tương ứng khi user data và weight entry thay đổi.
</acceptance_criteria>
</task>

<task id="1.4" type="execute">
<title>Stub updated Builder Interfaces to restore compilation</title>
<read_first>
- LiiO_EatClean/Features/AI/AICoachContextBuilder.swift
- LiiO_EatClean/Features/AI/ContextBuilder.swift
</read_first>
<action>
1. Cập nhật tạm thời chữ ký hàm trong `LiiO_EatClean/Features/AI/AICoachContextBuilder.swift`:
- Đổi:
```swift
func buildSnapshot(for intent: AICoachContextSnapshot.ContextIntent, date: Date = Date()) async -> AICoachContextSnapshot
```
Thành:
```swift
func buildSnapshot(
    for date: Date = Date(),
    mode: AICoachContextMode = .chat,
    intents: Set<ContextIntent> = [.generalChat],
    currentTab: String? = nil
) async -> AICoachContextSnapshot
```
- Bên trong thân hàm, ta tạm thời map map logic cũ để không báo lỗi compile:
```swift
    // TẠM THỜI: Lấy intent đầu tiên hoặc fallback để duy trì chạy flow cũ của builder
    let legacyIntent = AICoachContextSnapshot.ContextIntent(rawValue: intents.first?.rawValue ?? "generalChat") ?? .generalChat
```
(Lưu ý: Đoạn này chỉ là hack duy trì compile, ở Plan 2 ta sẽ thay đổi toàn bộ TaskGroup).

2. Cập nhật `LiiO_EatClean/Features/AI/ContextBuilder.swift`:
- Chuyển hàm `detectSnapshotIntent` thành kiểu trả về `Set<ContextIntent>`.
- Gọi qua `AICoachIntentDetector.shared.detectContextIntents(from: text)`.
- Thay thế các lời gọi `aiCoachContextBuilder.buildSnapshot` để truyền đủ `mode` và `intents`.
</action>
<acceptance_criteria>
- File `AICoachContextBuilder.swift` chấp nhận các tham số mới: `mode`, `intents: Set<ContextIntent>`.
- Lời gọi hàm trong `ContextBuilder.swift` được cập nhật để truyền `Set<ContextIntent>` và `AICoachContextMode`.
- Ứng dụng build thành công (Success) mà không bị lỗi Syntax hay Signature mismatch.
</acceptance_criteria>
</task>

## Verification
```bash
# Verify file structures
ls LiiO_EatClean/Features/AI/AICoachContextCache.swift
ls LiiO_EatClean/Features/AI/AICoachIntentDetector.swift
grep -rn "AICoachContextMode" LiiO_EatClean/Features/AI/AICoachContextSnapshot.swift
```

## Must Haves
- Đầy đủ định nghĩa enum `AICoachContextMode`, `ContextIntent`, `ContextSection`, `MissingDataReason`.
- Lớp Cache phản ứng nhạy bén với Notifications.
- Bộ tách chuỗi và nhận diện đa ý định (Multi-Intent) hoạt động chính xác.
- Source code hoàn toàn buildable sau Wave 1.
