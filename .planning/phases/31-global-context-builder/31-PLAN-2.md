---
phase: 31
wave: 2
title: "High Performance Adaptive Engine & Context Engine Wiring"
depends_on: [31-PLAN-1]
requirements: [VOICE-05]
files_modified:
  - LiiO_EatClean/Features/AI/AICoachContextBuilder.swift
  - LiiO_EatClean/Features/AI/AICoachContextSnapshot.swift
  - LiiO_EatClean/Features/AI/ContextBuilder.swift
  - LiiO_EatClean/Features/Chat/ChatViewModel.swift
  - LiiO_EatClean/Services/GlobalVoiceAssistantManager.swift
autonomous: true
---

# Plan 2: High Performance Adaptive Engine & Context Engine Wiring

## Goal
Hoàn thiện toàn bộ hệ thống nạp dữ liệu song song (Swift Concurrency TaskGroup) trong `AICoachContextBuilder` với khả năng chịu lỗi (Timeout 1.2s/3.0s) và lấy Cache. Sau đó, hoàn tất phần kết xuất ngôn ngữ thông minh (Anti-hallucination Prompting) và đấu nối hoàn chỉnh vào tầng ChatViewModel & GlobalVoiceAssistantManager.

## Tasks

<task id="2.1" type="execute">
<title>Rewrite AICoachContextBuilder with Priority-Based Parallel Loading</title>
<read_first>
- LiiO_EatClean/Features/AI/AICoachContextBuilder.swift
- LiiO_EatClean/Features/AI/AICoachContextCache.swift
- .planning/phases/31-global-context-builder/31-CONTEXT.md (Section 1, 2, 3)
</read_first>
<action>
Tái cấu trúc toàn bộ file `LiiO_EatClean/Features/AI/AICoachContextBuilder.swift` để load song song và xử lý timeout:

1. Cập nhật hàm `buildSnapshot`:
```swift
    func buildSnapshot(
        for date: Date = Date(),
        mode: AICoachContextMode = .chat,
        intents: Set<ContextIntent> = [.generalChat],
        currentTab: String? = nil
    ) async -> AICoachContextSnapshot {
        let startTime = Date()
        let timeoutLimit: TimeInterval = (mode == .voice) ? 1.2 : 3.0
        
        // Lấy danh sách Sections cần nạp từ intents qua IntentDetector
        let requiredSections = AICoachIntentDetector.shared.mapIntentsToSections(intents)
        
        print("[AICoachContext] ⚡ Nạp Context dạng \(mode) cho \(intents.count) intents trong \(timeoutLimit)s")
        
        var snapshot = AICoachContextSnapshot(currentDate: date, activeIntents: intents)
        snapshot.contextMode = mode
        snapshot.includedSections = requiredSections
        
        // Load song song qua TaskGroup
        do {
            snapshot = try await withThrowingTaskGroup(of: PartialContextResult.self) { group in
                // Task Timeout giám sát
                group.addTask {
                    try await Task.sleep(nanoseconds: UInt64(timeoutLimit * 1_000_000_000))
                    throw NSError(domain: "AICoachContext", code: 408, userInfo: [NSLocalizedDescriptionKey: "Timeout building rich context."])
                }
                
                // Thêm các Section Loading Task song song
                for section in requiredSections {
                    group.addTask {
                        return await self.fetchSectionData(section, date: date)
                    }
                }
                
                var finalSnapshot = snapshot
                var completedSections = Set<ContextSection>()
                
                // Chờ từng task trả về kết quả
                while let result = try? await group.next() {
                    switch result {
                    case .success(let section, let updateFn):
                        updateFn(&finalSnapshot)
                        completedSections.insert(section)
                    case .failure(let section, let reason):
                        finalSnapshot.missingReasons[section] = reason
                    }
                    
                    // Nếu tất cả sections đã xong (không tính task timeout):
                    if completedSections.count == requiredSections.count {
                        break
                    }
                }
                
                // Xác định chất lượng context
                finalSnapshot.contextQuality = completedSections.count == requiredSections.count ? .full : .partial
                return finalSnapshot
            }
        } catch {
            // Chạm Timeout (code 408)
            print("[AICoachContext] ⏳ Timeout chạm ngưỡng \(timeoutLimit)s! Khởi động Fallback...")
            snapshot.timedOut = true
            snapshot.contextQuality = .fallback
            
            // Tự động đánh dấu `.timedOut` cho các section chưa kịp load
            for s in requiredSections where !snapshot.includedSections.contains(s) {
                snapshot.missingReasons[s] = .timedOut
            }
            
            // Đẩy một số dữ liệu tối thiểu từ Cache (nếu có) để cứu trợ
            self.enrichWithCacheData(&snapshot)
        }
        
        print("[AICoachContext] ✅ Nạp xong trong \(String(format: "%.3fs", Date().timeIntervalSince(startTime))) - Chất lượng: \(snapshot.contextQuality)")
        return snapshot
    }
```

2. Định nghĩa `enum PartialContextResult` chứa kết quả nạp một phần:
```swift
    private enum PartialContextResult {
        case success(ContextSection, (inout AICoachContextSnapshot) -> Void)
        case failure(ContextSection, MissingDataReason)
    }
```

3. Triển khai hàm `fetchSectionData` gọi đến Cache trước, nếu hụt thì gọi Repository:
- Ví dụ cho `.profileMinimal`: Kiểm tra `AICoachContextCache.shared.getProfile()`. Nếu có, trả về ngay `.success`. Nếu không, gọi repository nạp và lưu lại vào cache trước khi return.
- Nếu dữ liệu load về là `nil` -> trả về `.failure(section, .notProvidedByUser / .notCreatedYet)`.

4. Triển khai hàm `enrichWithCacheData` dùng để nạp dự phòng các khối dữ liệu từ cache khi timeout xảy ra.
</action>
<acceptance_criteria>
- Tái cấu trúc thành công `AICoachContextBuilder` sử dụng `withThrowingTaskGroup` không đơ main thread.
- Hệ thống giới hạn thời gian chính xác (1.2s cho `.voice` và 3.0s cho `.chat`).
- Tích hợp `AICoachContextCache.shared` để lấy và ghi đè cache cho các key nạp thành công.
- Timeout không trả về snapshot trống hoàn toàn, mà tận dụng cache và dữ liệu đã load kịp.
</acceptance_criteria>
</task>

<task id="2.2" type="execute">
<title>Enhance toMarkdown in AICoachContextSnapshot with Anti-hallucination rules</title>
<read_first>
- LiiO_EatClean/Features/AI/AICoachContextSnapshot.swift
- .planning/phases/31-global-context-builder/31-CONTEXT.md (Section 2 - D-08)
</read_first>
<action>
Nâng cấp hàm `toMarkdown()` trong `AICoachContextSnapshot.swift`:

1. Bổ sung metadata chất lượng context ở đầu chuỗi Prompt:
```swift
        var md = "### [DỮ LIỆU THẬT TỪ ỨNG DỤNG - THỜI GIAN THỰC]\n"
        md += "Thời gian hiện tại: \(formatDate(currentDate))\n"
        md += "Chế độ hoạt động: \(contextMode.rawValue)\n"
        md += "Chất lượng Context: \(contextQuality.rawValue) (Timed out: \(timedOut))\n\n"
```

2. Đối với mỗi khối Section trong markdown (Profile, Today actual logs, Plan...), kiểm tra nếu thuộc tính bị `nil`:
- Dựa vào `missingReasons[section]` để in ra lý do cụ thể.
- Ví dụ:
```swift
        // Section: Kế hoạch hôm nay
        if let plan = todayPlan {
            // in thông tin plan...
        } else {
            let reason = missingReasons[.todayDailyPlan] ?? .notCreatedYet
            switch reason {
            case .timedOut:
                md += "- [Dữ liệu Bị Thiếu - LÝ DO: Hết thời gian tải (Timeout)].\n"
            case .notCreatedYet:
                md += "- [Dữ liệu Bị Thiếu - LÝ DO: Người dùng chưa tạo kế hoạch hôm nay].\n"
            case .notProvidedByUser:
                md += "- [Dữ liệu Bị Thiếu - LÝ DO: Người dùng chưa cung cấp thông tin này trong hồ sơ].\n"
            default:
                md += "- [Dữ liệu Bị Thiếu - LÝ DO: Không khả dụng].\n"
            }
        }
```

3. Cập nhật đoạn luật phòng ngừa ảo giác (Anti-hallucination Rule) ở cuối chuỗi:
```swift
        md += """
        \n> [HƯỚNG DẪN VẬN HÀNH AI QUAN TRỌNG]:
        - Bạn BẮT BUỘC phải xem mục LÝ DO thiếu dữ liệu ở trên để phản hồi.
        - Nếu lý do là 'Timeout' hoặc 'Chưa load kịp': Tuyệt đối không đổ lỗi cho user. Hãy trả lời nhanh dựa trên phần dữ liệu đã load và nói nhẹ nhàng 'Mình chưa kịp tải đủ dữ liệu nâng cao, mình trả lời theo thông tin hôm nay trước nhé'.
        - Nếu lý do là 'Chưa tạo thực đơn' (notCreatedYet): Hãy đề xuất tạo nhanh một thực đơn.
        - Nếu lý do là 'Chưa điền hồ sơ' (notProvidedByUser): Có thể khuyến khích người dùng bổ sung.
        - TUYỆT ĐỐI KHÔNG BỊA ĐẶT (HALLUCINATION) dữ liệu số liệu (calo, cân nặng, dị ứng) nếu mục đó báo trống hoặc chưa load kịp.
        """
```
</action>
<acceptance_criteria>
- Hàm `toMarkdown()` chứa nhãn metadata về `contextQuality` và `timedOut`.
- Phản ứng thông minh và in rõ các nhãn lý do thiếu dữ liệu (`MissingDataReason`) thay vì chỉ in mặc định là "không có".
- Chuỗi prompt cuối cùng tuân thủ 100% các quy tắc anti-hallucination đã chốt.
</acceptance_criteria>
</task>

<task id="2.3" type="execute">
<title>E2E Wiring: ContextBuilder, ChatViewModel & GlobalVoiceAssistantManager</title>
<read_first>
- LiiO_EatClean/Features/AI/ContextBuilder.swift
- LiiO_EatClean/Features/Chat/ChatViewModel.swift
- LiiO_EatClean/Services/GlobalVoiceAssistantManager.swift
</read_first>
<action>
1. Cập nhật hàm `buildSystemPrompt` và `buildChatContext` trong `ContextBuilder.swift`:
- Gọi `AICoachIntentDetector.shared.detectContextIntents(from: userMessage)` để nhận được `detectedIntents`.
- Chuyển đổi `voiceMode: Bool` thành `AICoachContextMode`: `let mode: AICoachContextMode = voiceMode ? .voice : .chat`.
- Gọi:
```swift
let snapshot = await aiCoachContextBuilder.buildSnapshot(
    for: Date(),
    mode: mode,
    intents: Set(detectedIntents.map { $0.intent }),
    currentTab: nil
)
```

2. Cập nhật `ChatViewModel.swift`:
- Khi gọi `aiService.sendChatMessage` hoặc `contextBuilder.buildSystemPrompt`, hãy đảm bảo truyền `voiceMode: false` (hoặc ngầm hiểu là `.chat` thông qua API).

3. Cập nhật `GlobalVoiceAssistantManager.swift`:
- Đảm bảo cuộc gọi sinh prompt từ Assistant truyền `voiceMode: true` để hệ thống chuyển mạch thông minh sang 1.2s Timeout!
</action>
<acceptance_criteria>
- Luồng Chat thông thường nhận diện đầy đủ đa ý định và sử dụng timeout 3.0 giây.
- Luồng Voice Assistant được cấu hình `voiceMode: true`, tự động kích hoạt giới hạn thời gian siêu tốc 1.2 giây của `AICoachContextBuilder`.
- Mọi file đấu nối biên dịch thành công (Compile Succeeded) và không phát sinh lỗi liên kết.
</acceptance_criteria>
</task>

## Verification
```bash
# Ensure overall compilation
# We will perform syntax auditing and then ask user to build target.
grep -rn "AICoachContextMode.voice" LiiO_EatClean/
grep -rn "withThrowingTaskGroup" LiiO_EatClean/Features/AI/AICoachContextBuilder.swift
```

## Must Haves
- Cơ chế nạp song song (Priority Parallel Data Loading) chuẩn xác, không block luồng chính.
- Đảm bảo giới hạn thời gian (Adaptive Timeout) hoạt động hoàn hảo theo hai nhánh (1.2s vs 3.0s).
- AI prompt chứa nhãn Anti-hallucination động theo `MissingDataReason`.
- Kết nối đầu cuối E2E hoàn chỉnh, ứng dụng build thành công tuyệt đối.
