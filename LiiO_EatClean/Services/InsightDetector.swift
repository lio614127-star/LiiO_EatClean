import Foundation

struct DailyInsight: Identifiable {
    let id = UUID()
    let type: InsightType
    let message: String
    let suggestion: String
    let severity: InsightSeverity
    
    enum InsightType: String {
        case lowProtein = "low_protein"
        case skippedMeal = "skipped_meal"
        case calorieOverrun = "calorie_overrun"
        case lowWater = "low_water"
        case repeatedMeals = "repeated_meals"
        case macroImbalance = "macro_imbalance"
    }
    
    enum InsightSeverity: Int, Comparable {
        case low = 0      // informational
        case medium = 1   // attention needed
        case high = 2     // critical
        
        static func < (lhs: InsightSeverity, rhs: InsightSeverity) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
}

class InsightDetector {
    private let mealRepository: MealRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    
    init(mealRepository: MealRepositoryProtocol = MealRepository(),
         userRepository: UserRepositoryProtocol = UserRepository()) {
        self.mealRepository = mealRepository
        self.userRepository = userRepository
    }
    
    func detectInsights() async -> [DailyInsight] {
        var insights: [DailyInsight] = []
        
        let calendar = Calendar.current
        let endDate = Date()
        let startDate7Days = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        
        do {
            let meals7Days = try await mealRepository.fetchMeals(from: startDate7Days, to: endDate)
            let user = try await userRepository.fetchUser()
            let targetCalories = user?.dailyCalorieTarget ?? 2000
            
            // Group by day using DateComponents (year, month, day)
            var mealsByDay: [DateComponents: [MealModel]] = [:]
            for meal in meals7Days {
                let comp = calendar.dateComponents([.year, .month, .day], from: meal.date)
                mealsByDay[comp, default: []].append(meal)
            }
            
            // Get last 7 days components
            var last7DaysComps: [DateComponents] = []
            for i in 0..<7 {
                if let d = calendar.date(byAdding: .day, value: -i, to: endDate) {
                    last7DaysComps.append(calendar.dateComponents([.year, .month, .day], from: d))
                }
            }
            let last3DaysComps = Array(last7DaysComps.prefix(3))
            
            // P1: Low Protein (< 30g)
            var lowProtein3DaysCount = 0
            var lowProtein7DaysCount = 0
            for comp in last7DaysComps {
                let dayMeals = mealsByDay[comp] ?? []
                let protein = dayMeals.flatMap { $0.mealFoods }.filter { $0.isEaten }.map { $0.proteinSnapshot }.reduce(0, +)
                
                // Only count days where there is SOME data (don't count empty days as low protein if they haven't logged anything)
                let cals = dayMeals.flatMap { $0.mealFoods }.filter { $0.isEaten }.map { $0.caloriesSnapshot }.reduce(0, +)
                
                if cals > 0 && protein < 30 {
                    lowProtein7DaysCount += 1
                    if last3DaysComps.contains(comp) {
                        lowProtein3DaysCount += 1
                    }
                }
            }
            
            if lowProtein7DaysCount >= 5 {
                insights.append(DailyInsight(type: .lowProtein, message: "Bạn đang thiếu protein liên tục trong tuần qua.", suggestion: "Thêm trứng, ức gà hoặc đậu phụ vào các bữa ăn chính.", severity: .high))
            } else if lowProtein3DaysCount >= 3 {
                insights.append(DailyInsight(type: .lowProtein, message: "3 ngày gần đây bạn nạp khá ít protein.", suggestion: "Cố gắng bổ sung thêm protein vào bữa sáng hoặc trưa nhé.", severity: .medium))
            }
            
            // P3: Skipped Breakfast
            var skippedBreakfastCount = 0
            for comp in last7DaysComps {
                let dayMeals = mealsByDay[comp] ?? []
                // Only evaluate days that have SOME meal logged
                if !dayMeals.isEmpty {
                    let hasBreakfast = dayMeals.contains { $0.mealType.lowercased().contains("sáng") }
                    if !hasBreakfast {
                        skippedBreakfastCount += 1
                    }
                }
            }
            if skippedBreakfastCount >= 4 {
                insights.append(DailyInsight(type: .skippedMeal, message: "Bạn đã bỏ bữa sáng \(skippedBreakfastCount) lần trong tuần này.", suggestion: "Nên ăn sáng nhẹ nhàng như yến mạch hoặc trái cây để có năng lượng.", severity: .medium))
            }
            
            // P5: Calorie overrun (3 consecutive days)
            var consecutiveOverrun = 0
            for comp in last3DaysComps {
                let dayMeals = mealsByDay[comp] ?? []
                let calories = dayMeals.flatMap { $0.mealFoods }.filter { $0.isEaten }.map { $0.caloriesSnapshot }.reduce(0, +)
                if calories > targetCalories {
                    consecutiveOverrun += 1
                }
            }
            if consecutiveOverrun >= 3 {
                insights.append(DailyInsight(type: .calorieOverrun, message: "3 ngày liên tiếp bạn nạp vượt mức calories mục tiêu.", suggestion: "Hãy thử giảm một nửa khẩu phần ăn vào bữa tối hoặc tránh ăn vặt.", severity: .medium))
            }
            
            // P6: Low water (< 50% target average over 7 days)
            var totalWater7Days: Double = 0
            for comp in last7DaysComps {
                if let d = calendar.date(from: comp) {
                    totalWater7Days += try await userRepository.fetchWaterLog(for: d)
                }
            }
            let waterTarget = 2000.0 // Default
            let averageWater = totalWater7Days / 7.0
            
            // Only trigger if they log water but it's too low
            if averageWater > 0 && averageWater < (waterTarget * 0.5) {
                insights.append(DailyInsight(type: .lowWater, message: "Tuần này bạn uống khá ít nước (trung bình \(Int(averageWater))ml/ngày).", suggestion: "Hãy đặt một chai nước trên bàn làm việc để nhắc nhở bản thân.", severity: .low))
            }
            
            // P7: Repeated meals (5-day window)
            let last5DaysComps = Array(last7DaysComps.prefix(5))
            insights.append(contentsOf: detectRepeatedMeals(mealsByDay: mealsByDay, last5DaysComps: last5DaysComps))
            
            // P8: Macro imbalance (3-day consecutive)
            insights.append(contentsOf: detectMacroImbalance(mealsByDay: mealsByDay, last7DaysComps: last7DaysComps))
            
        } catch {
            print("InsightDetector Error: \(error)")
        }
        
        // Sort by severity descending
        insights.sort { $0.severity > $1.severity }
        
        // Cap at 5 insights
        return Array(insights.prefix(5))
    }
    
    // MARK: - New Detection Logic
    
    private func detectRepeatedMeals(mealsByDay: [DateComponents: [MealModel]], last5DaysComps: [DateComponents]) -> [DailyInsight] {
        var insights: [DailyInsight] = []
        let stopWords = ["phần", "vừa", "mini", "đặc biệt", "sốt", "cay", "xào", "chiên", "nướng", "luộc", "hấp", "rang", "kho"]
        
        var nameCounts: [String: Int] = [:]
        var originalNames: [String: String] = [:]
        
        for comp in last5DaysComps {
            let dayMeals = mealsByDay[comp] ?? []
            let eatenFoods = dayMeals.flatMap { $0.mealFoods }.filter { $0.isEaten }
            
            for food in eatenFoods {
                let name = food.foodItem?.name ?? ""
                var normalized = FoodSafetyValidator.shared.normalizeText(name)
                
                for word in stopWords {
                    normalized = normalized.replacingOccurrences(of: word, with: "")
                }
                normalized = normalized.components(separatedBy: .whitespaces).filter { !$0.isEmpty }.joined(separator: " ")
                
                if !normalized.isEmpty {
                    nameCounts[normalized, default: 0] += 1
                    if originalNames[normalized] == nil {
                        originalNames[normalized] = name
                    }
                }
            }
        }
        
        for (normalized, count) in nameCounts where count >= 3 {
            if let original = originalNames[normalized] {
                insights.append(DailyInsight(
                    type: .repeatedMeals,
                    message: "Bạn đang ăn món \(original) khá thường xuyên tuần này. Thử đổi món để đa dạng dinh dưỡng nhé.",
                    suggestion: "Thay \(original) bằng cá, bò, hoặc đậu phụ để cân bằng.",
                    severity: .low
                ))
            }
        }
        
        return Array(insights.prefix(2))
    }
    
    private func detectMacroImbalance(mealsByDay: [DateComponents: [MealModel]], last7DaysComps: [DateComponents]) -> [DailyInsight] {
        var insights: [DailyInsight] = []
        
        var fatOutDays = 0
        var avgFatPct: Double = 0
        
        // Iterate from newest (today) to oldest (6 days ago)
        for i in 0..<last7DaysComps.count {
            let comp = last7DaysComps[i]
            let dayMeals = mealsByDay[comp] ?? []
            let foods = dayMeals.flatMap { $0.mealFoods }.filter { $0.isEaten }
            
            let protein = foods.map { $0.proteinSnapshot }.reduce(0, +)
            let carbs = foods.map { $0.carbsSnapshot }.reduce(0, +)
            let fat = foods.map { $0.fatSnapshot }.reduce(0, +)
            let calories = foods.map { $0.caloriesSnapshot }.reduce(0, +)
            
            if calories > 0 {
                let totalCals = max(protein * 4 + carbs * 4 + fat * 9, 1)
                let fatPct = (fat * 9) / totalCals * 100
                
                if fatPct > 40 {
                    fatOutDays += 1
                    if i < 3 { avgFatPct += fatPct }
                } else {
                    break // Streak broken
                }
            } else {
                break // No data breaks streak
            }
        }
        
        if fatOutDays >= 3 {
            let severity: DailyInsight.InsightSeverity = fatOutDays >= 5 ? .high : .medium
            insights.append(DailyInsight(
                type: .macroImbalance,
                message: "3 ngày gần đây lượng chất béo của bạn hơi cao (\(Int(avgFatPct / 3))%). Hãy thử giảm món chiên hoặc nước sốt béo nhé.",
                suggestion: "Thay đồ chiên bằng hấp hoặc luộc, chọn thịt nạc thay thịt mỡ.",
                severity: severity
            ))
        }
        
        return insights
    }
}
