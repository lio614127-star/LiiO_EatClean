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
        md += "Thời gian hiện tại: \(formatDate(currentDate))\n\n"
        
        // 1. Profile Context
        if let prof = profile {
            md += "#### 1. Hồ sơ & Mục tiêu\n"
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
            md += "\n"
        }
        
        // 2. Today Actual Consumed (CRITICAL DIFFERENCE)
        md += "#### 2. Bữa ăn Thực tế đã Ăn Hôm nay (Actual Consumed)\n"
        if todayActualMeals.isEmpty {
            md += "- *Chưa ghi nhận bữa ăn thực tế nào hôm nay.*\n"
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
        if let nut = todayNutrition {
            md += "#### 3. Tiến độ Dinh dưỡng Hôm nay\n"
            md += "- Đã nạp: \(Int(nut.consumedCalories)) / \(Int(nut.targetCalories)) kcal\n"
            md += "- Còn lại: \(Int(nut.remainingCalories)) kcal\n"
            md += "- Macros đã nạp: Protein \(Int(nut.consumedProtein))g, Carbs \(Int(nut.consumedCarbs))g, Fat \(Int(nut.consumedFat))g\n"
            md += "- Macros còn lại: Protein \(Int(nut.remainingProtein))g, Carbs \(Int(nut.remainingCarbs))g, Fat \(Int(nut.remainingFat))g\n\n"
        }
        
        // 4. Today Meal Plan (Planned BUT NOT necessarily EATEN yet)
        md += "#### 4. Kế hoạch Dinh dưỡng Hôm nay (Planned - CHƯA CHẮC ĐÃ ĂN)\n"
        if let plan = todayPlan, !plan.plannedMeals.isEmpty {
            md += "Trạng thái Kế hoạch: \(plan.status.uppercased())\n"
            for pMeal in plan.plannedMeals {
                let statusIcon = pMeal.status == "eaten" ? "✅ ĐÃ ĂN" : (pMeal.status == "skipped" ? "❌ ĐÃ BỎ QUA" : "⏳ CHƯA ĂN (MỚI LÊN LỊCH)")
                md += "- [\(pMeal.type.uppercased())] \(pMeal.description) (\(Int(pMeal.expectedCalories)) kcal) -> **Trạng thái: \(statusIcon)**\n"
            }
        } else {
            md += "- *Chưa có kế hoạch ngày hôm nay trong ứng dụng.*\n"
        }
        md += "\n"
        
        // 5. Past History & Weekly Presence
        if activeIntent == .dailyPlanRequest || activeIntent == .progressQuestion || activeIntent == .generalChat {
            md += "#### 5. Lịch sử & Tính ổn định\n"
            if !weeklyPlanPresence.isEmpty {
                md += "- Phủ sóng kế hoạch tuần: "
                let sortedDays = weeklyPlanPresence.keys.sorted()
                var presences: [String] = []
                for d in sortedDays {
                    let icon = weeklyPlanPresence[d] == true ? "📅" : "⬜"
                    presences.append("\(d.suffix(5)): \(icon)")
                }
                md += presences.joined(separator: " | ") + "\n"
            }
            
            if let history = past3DaysActualSummary, !history.isEmpty {
                md += "- Lịch sử thực tế 3 ngày gần đây:\n\(history)\n"
            }
        }
        
        // 6. Progress & Metabolic
        if activeIntent == .progressQuestion || activeIntent == .generalChat {
            md += "#### 6. Biểu đồ Tiến độ & Metabolic OS\n"
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
            }
            
            if let meta = metabolicOS {
                md += "- TDEE Cơ sở: \(Int(meta.currentTDEE)) kcal\n"
                md += "- TDEE Thích nghi (Adaptive): \(Int(meta.adaptiveTDEE)) kcal\n"
                md += "- Trạng thái trao đổi chất: \(meta.isMetabolismAdapting ? "Đang thích nghi / Biến động" : "Ổn định")\n"
            }
        }
        
        md += "\n> [Quy định Dữ liệu]: TUYỆT ĐỐI KHÔNG ĐƯỢC BỊA ĐẶT thông tin. Nếu ở trên ghi 'không có dữ liệu' hoặc 'chưa ghi nhận', hãy thông báo trung thực cho người dùng là 'Mình chưa thấy dữ liệu này trong app'. Phân biệt rõ ràng món Nằm Trong Kế Hoạch (Planned) nhưng chưa bấm tick ăn với món Đã Ăn Thực Tế (Actual Log).\n"
        
        return md
    }
    
    // MARK: - Helpers
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
