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
    
    // Backward compatibility cases
    case dailyPlanRequest
    case progressQuestion
    case rebalanceRequest
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

struct AICoachContextSnapshot: Codable {
    
    struct ProfileSummary: Codable {
        var goalType: String
        var targetCalories: Double
        var proteinTarget: Double
        var carbsTarget: Double
        var fatTarget: Double
        var likes: [String]
        var dislikes: [String]
        var avoidFoods: [String]
        var healthConditions: [String]
    }
    
    struct NutritionBalance: Codable {
        var consumedCalories: Double
        var consumedProtein: Double
        var consumedCarbs: Double
        var consumedFat: Double
        var targetCalories: Double
        var targetProtein: Double
        var targetCarbs: Double
        var targetFat: Double
        
        var remainingCalories: Double { max(0, targetCalories - consumedCalories) }
        var remainingProtein: Double { max(0, targetProtein - consumedProtein) }
        var remainingCarbs: Double { max(0, targetCarbs - consumedCarbs) }
        var remainingFat: Double { max(0, targetFat - consumedFat) }
    }
    
    struct ActualMealLog: Codable {
        var id: UUID
        var type: String // breakfast, lunch, dinner, snack
        var time: Date
        var name: String
        var calories: Double
        var protein: Double
        var carbs: Double
        var fat: Double
        var isLinkedToPlan: Bool
    }
    
    struct PlannedMealDetail: Codable {
        var id: UUID
        var type: String
        var status: String // planned, eaten, skipped, replaced
        var description: String
        var expectedCalories: Double
        var isEaten: Bool { status == "eaten" }
        var linkedActualMealLogId: UUID?
    }
    
    struct DailyPlanSummary: Codable {
        var date: Date
        var status: String // draft, generated, finalized
        var plannedMeals: [PlannedMealDetail]
    }
    
    struct ProgressSummary: Codable {
        var latestWeight: Double?
        var latestWeightDate: Date?
        var avgCalories7Days: Double?
        var weeklyAdherenceRate: Double? // % of plan followed
        var recentAdherenceStatus: String // excellent, good, low, none
    }
    
    struct MetabolicSummary: Codable {
        var currentTDEE: Double
        var adaptiveTDEE: Double
        var isMetabolismAdapting: Bool
    }
    
    // MARK: - Active Properties
    var currentDate: Date
    var activeIntent: ContextIntent
    
    // New Context Metadata
    var contextMode: AICoachContextMode = .chat
    var activeIntents: Set<ContextIntent> = [.generalChat]
    var contextQuality: ContextQuality = .full
    var timedOut: Bool = false
    var includedSections: Set<ContextSection> = []
    var missingReasons: [ContextSection: MissingDataReason] = [:]
    
    var profile: ProfileSummary?
    var todayNutrition: NutritionBalance?
    var todayActualMeals: [ActualMealLog] = []
    var todayPlan: DailyPlanSummary?
    
    var weeklyPlanPresence: [String: Bool] = [:] // "yyyy-MM-dd" : HasPlan
    var past3DaysActualSummary: String?
    var past7DaysAggregate: ProgressSummary?
    var metabolicOS: MetabolicSummary?
    
    // MARK: - Markdown Serializer
    func toMarkdown() -> String {
        var md = "### [DỮ LIỆU THẬT TỪ ỨNG DỤNG - THỜI GIAN THỰC]\n"
        md += "Thời gian hiện tại: \(formatDate(currentDate))\n"
        md += "Chế độ hoạt động: \(contextMode.rawValue.uppercased())\n"
        md += "Chất lượng Context: \(contextQuality.rawValue.uppercased()) (Chạm Ngưỡng Timeout: \(timedOut ? "CÓ" : "KHÔNG"))\n\n"
        
        // 1. Profile Context
        md += "#### 1. Hồ sơ & Mục tiêu\n"
        if let prof = profile {
            md += "- Mục tiêu: \(prof.goalType)\n"
            md += "- Calorie Mục tiêu: \(Int(prof.targetCalories)) kcal\n"
            md += "- Tỷ lệ Macro: P: \(Int(prof.proteinTarget))g, C: \(Int(prof.carbsTarget))g, F: \(Int(prof.fatTarget))g\n"
            if !prof.healthConditions.isEmpty {
                md += "- Tình trạng sức khỏe/Dị ứng: \(prof.healthConditions.joined(separator: ", "))\n"
            }
            if !prof.avoidFoods.isEmpty {
                md += "- Thực phẩm cần tránh: \(prof.avoidFoods.joined(separator: ", "))\n"
            }
            if !prof.likes.isEmpty {
                md += "- Món ưa thích: \(prof.likes.joined(separator: ", "))\n"
            }
        } else {
            md += missingMessage(for: .profileMinimal, defaultMsg: "- [Dữ liệu Bị Thiếu - Người dùng chưa thiết lập hồ sơ].\n")
        }
        md += "\n"
        
        // 2. Today Actual Consumed
        md += "#### 2. Bữa ăn Thực tế đã Ăn Hôm nay (Actual Consumed)\n"
        if !includedSections.contains(.todayMealLogs) {
            md += "- *[Mục này không được yêu cầu nạp cho intent hiện tại]*\n"
        } else if todayActualMeals.isEmpty {
            if missingReasons[.todayMealLogs] != nil {
                md += missingMessage(for: .todayMealLogs, defaultMsg: "- *Chưa ghi nhận bữa ăn thực tế nào hôm nay.*\n")
            } else {
                md += "- *Chưa ghi nhận bữa ăn thực tế nào hôm nay.*\n"
            }
        } else {
            for meal in todayActualMeals {
                let timeStr = formatTime(meal.time)
                md += "- [\(meal.type.uppercased()) tại \(timeStr)] \(meal.name): \(Int(meal.calories)) kcal (P: \(Int(meal.protein))g, C: \(Int(meal.carbs))g, F: \(Int(meal.fat))g)"
                if meal.isLinkedToPlan {
                    md += " *(Đã liên kết với Kế hoạch)*"
                }
                md += "\n"
            }
        }
        md += "\n"
        
        // 3. Nutrition Status
        if includedSections.contains(.todayTargets) || includedSections.contains(.plannedVsActual) {
            md += "#### 3. Tiến độ Dinh dưỡng Hôm nay\n"
            if let nut = todayNutrition {
                md += "- Đã nạp: \(Int(nut.consumedCalories)) / \(Int(nut.targetCalories)) kcal\n"
                md += "- Còn lại: \(Int(nut.remainingCalories)) kcal\n"
                md += "- Macros đã nạp: Protein \(Int(nut.consumedProtein))g, Carbs \(Int(nut.consumedCarbs))g, Fat \(Int(nut.consumedFat))g\n"
                md += "- Macros còn lại: Protein \(Int(nut.remainingProtein))g, Carbs \(Int(nut.remainingCarbs))g, Fat \(Int(nut.remainingFat))g\n"
            } else {
                md += missingMessage(for: .todayTargets, defaultMsg: "- [Không thể đối soát tiến độ do thiếu hồ sơ hoặc nhật ký].\n")
            }
            md += "\n"
        }
        
        // 4. Today Meal Plan
        md += "#### 4. Kế hoạch Dinh dưỡng Hôm nay (Planned - CHƯA CHẮC ĐÃ ĂN)\n"
        if !includedSections.contains(.todayDailyPlan) {
            md += "- *[Mục này không được yêu cầu nạp cho intent hiện tại]*\n"
        } else if let plan = todayPlan, !plan.plannedMeals.isEmpty {
            md += "Trạng thái Kế hoạch: \(plan.status.uppercased())\n"
            for pMeal in plan.plannedMeals {
                let statusIcon = pMeal.status == "eaten" ? "✅ ĐÃ ĂN" : (pMeal.status == "skipped" ? "❌ ĐÃ BỎ QUA" : "⏳ CHƯA ĂN (MỚI LÊN LỊCH)")
                md += "- [\(pMeal.type.uppercased())] \(pMeal.description) (\(Int(pMeal.expectedCalories)) kcal) -> **Trạng thái: \(statusIcon)**\n"
            }
        } else {
            md += missingMessage(for: .todayDailyPlan, defaultMsg: "- *Chưa có kế hoạch ngày hôm nay trong ứng dụng.*\n")
        }
        md += "\n"
        
        // 5. Past History & Weekly Presence
        if includedSections.contains(.weeklyPlans) || includedSections.contains(.recentMealsSummary) {
            md += "#### 5. Lịch sử & Tính ổn định\n"
            if includedSections.contains(.weeklyPlans) {
                if !weeklyPlanPresence.isEmpty {
                    md += "- Phủ sóng kế hoạch tuần: "
                    let sortedDays = weeklyPlanPresence.keys.sorted()
                    var presences: [String] = []
                    for d in sortedDays {
                        let icon = weeklyPlanPresence[d] == true ? "📅" : "⬜"
                        presences.append("\(d.suffix(5)): \(icon)")
                    }
                    md += presences.joined(separator: " | ") + "\n"
                } else {
                    md += missingMessage(for: .weeklyPlans, defaultMsg: "- *Không tìm thấy phủ sóng kế hoạch tuần.*\n")
                }
            }
            
            if includedSections.contains(.recentMealsSummary) {
                if let history = past3DaysActualSummary, !history.isEmpty {
                    md += "- Lịch sử thực tế 3 ngày gần đây:\n\(history)\n"
                } else {
                    md += missingMessage(for: .recentMealsSummary, defaultMsg: "- *Không tìm thấy lịch sử thực tế gần đây.*\n")
                }
            }
            md += "\n"
        }
        
        // 6. Progress & Metabolic
        if includedSections.contains(.progressTrend) || includedSections.contains(.metabolicSummary) || includedSections.contains(.weightTrend) {
            md += "#### 6. Biểu đồ Tiến độ & Metabolic OS\n"
            if includedSections.contains(.progressTrend) || includedSections.contains(.weightTrend) {
                if let prog = past7DaysAggregate {
                    if let w = prog.latestWeight {
                        let wDate = prog.latestWeightDate != nil ? " (\(formatDate(prog.latestWeightDate!)))" : ""
                        md += "- Cân nặng gần nhất: \(String(format: "%.1f", w)) kg\(wDate)\n"
                    }
                    if let avgC = prog.avgCalories7Days {
                        md += "- Trung bình Calorie 7 ngày: \(Int(avgC)) kcal/ngày\n"
                    }
                    if let adh = prog.weeklyAdherenceRate {
                        md += "- Điểm tuân thủ kế hoạch: \(Int(adh))% (\(prog.recentAdherenceStatus.uppercased()))\n"
                    }
                } else {
                    md += missingMessage(for: .progressTrend, defaultMsg: "- *Không tìm thấy biểu đồ tiến độ.*\n")
                }
            }
            
            if includedSections.contains(.metabolicSummary) {
                if let meta = metabolicOS {
                    md += "- TDEE Cơ sở: \(Int(meta.currentTDEE)) kcal\n"
                    md += "- TDEE Thích nghi (Adaptive): \(Int(meta.adaptiveTDEE)) kcal\n"
                    md += "- Trạng thái trao đổi chất: \(meta.isMetabolismAdapting ? "Đang thích nghi / Biến động" : "Ổn định")\n"
                } else {
                    md += missingMessage(for: .metabolicSummary, defaultMsg: "- *Chưa có thông tin Metabolic OS.*\n")
                }
            }
        }
        
        md += """
        \n> [HƯỚNG DẪN VẬN HÀNH AI QUAN TRỌNG]:
        - Bạn BẮT BUỘC phải xem mục LÝ DO thiếu dữ liệu ở trên để phản hồi.
        - Nếu lý do là 'Timeout' (Quá thời gian nạp): Tuyệt đối không đổ lỗi cho user. Hãy trả lời nhanh dựa trên phần dữ liệu đã kịp load và nói nhẹ nhàng 'Mình vừa ưu tiên trả lời nhanh để kịp tương tác, dưới đây là thông tin hiện tại nhé' (tùy cơ biến ứng cho tự nhiên).
        - Nếu lý do là 'Chưa tạo thực đơn' (notCreatedYet): Hãy đề xuất chủ động tạo nhanh một thực đơn cho ngày hôm nay.
        - Nếu lý do là 'Chưa điền hồ sơ' (notProvidedByUser): Hãy khéo léo khích lệ người dùng bổ sung cân nặng/mục tiêu.
        - TUYỆT ĐỐI KHÔNG BỊA ĐẶT (HALLUCINATION) các con số calo, cân nặng, dị ứng nếu mục đó báo trống hoặc bị thiếu do timeout. Phân biệt rõ ràng món trong Plan và món đã ăn thực tế.
        """
        
        return md
    }
    
    // MARK: - Helpers
    private func missingMessage(for section: ContextSection, defaultMsg: String) -> String {
        guard let reason = missingReasons[section] else { return defaultMsg }
        switch reason {
        case .timedOut:
            return "- [DỮ LIỆU BỊ THIẾU - LÝ DO: Quá thời gian nạp dữ liệu do giới hạn adaptive timeout].\n"
        case .notProvidedByUser:
            return "- [DỮ LIỆU BỊ THIẾU - LÝ DO: Người dùng chưa cung cấp thông tin trong Hồ sơ].\n"
        case .notCreatedYet:
            return "- [DỮ LIỆU BỊ THIẾU - LÝ DO: Dữ liệu kế hoạch chưa được khởi tạo].\n"
        case .notLoggedYet:
            return "- [DỮ LIỆU BỊ THIẾU - LÝ DO: Người dùng chưa thực hiện ghi chép nào].\n"
        case .unavailable:
            return "- [DỮ LIỆU BỊ THIẾU - LÝ DO: Không khả dụng vào lúc này].\n"
        case .permissionOrStorageError:
            return "- [DỮ LIỆU BỊ THIẾU - LÝ DO: Gặp lỗi hệ thống dữ liệu hoặc lưu trữ].\n"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
