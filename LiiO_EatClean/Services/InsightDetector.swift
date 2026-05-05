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
    }
    
    enum InsightSeverity {
        case warning  // 3-day pattern
        case alert    // 7-day pattern
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
                let protein = dayMeals.flatMap { $0.mealFoods }.map { $0.proteinSnapshot * $0.quantity }.reduce(0, +)
                
                // Only count days where there is SOME data (don't count empty days as low protein if they haven't logged anything)
                let cals = dayMeals.flatMap { $0.mealFoods }.map { $0.caloriesSnapshot * $0.quantity }.reduce(0, +)
                
                if cals > 0 && protein < 30 {
                    lowProtein7DaysCount += 1
                    if last3DaysComps.contains(comp) {
                        lowProtein3DaysCount += 1
                    }
                }
            }
            
            if lowProtein7DaysCount >= 5 {
                insights.append(DailyInsight(type: .lowProtein, message: "Bạn đang thiếu protein liên tục trong tuần qua.", suggestion: "Thêm trứng, ức gà hoặc đậu phụ vào các bữa ăn chính.", severity: .alert))
            } else if lowProtein3DaysCount >= 3 {
                insights.append(DailyInsight(type: .lowProtein, message: "3 ngày gần đây bạn nạp khá ít protein.", suggestion: "Cố gắng bổ sung thêm protein vào bữa sáng hoặc trưa nhé.", severity: .warning))
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
                insights.append(DailyInsight(type: .skippedMeal, message: "Bạn đã bỏ bữa sáng \(skippedBreakfastCount) lần trong tuần này.", suggestion: "Nên ăn sáng nhẹ nhàng như yến mạch hoặc trái cây để có năng lượng.", severity: .alert))
            }
            
            // P5: Calorie overrun (3 consecutive days)
            var consecutiveOverrun = 0
            for comp in last3DaysComps {
                let dayMeals = mealsByDay[comp] ?? []
                let calories = dayMeals.flatMap { $0.mealFoods }.map { $0.caloriesSnapshot * $0.quantity }.reduce(0, +)
                if calories > targetCalories {
                    consecutiveOverrun += 1
                }
            }
            if consecutiveOverrun >= 3 {
                insights.append(DailyInsight(type: .calorieOverrun, message: "3 ngày liên tiếp bạn nạp vượt mức calories mục tiêu.", suggestion: "Hãy thử giảm một nửa khẩu phần ăn vào bữa tối hoặc tránh ăn vặt.", severity: .warning))
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
                insights.append(DailyInsight(type: .lowWater, message: "Tuần này bạn uống khá ít nước (trung bình \(Int(averageWater))ml/ngày).", suggestion: "Hãy đặt một chai nước trên bàn làm việc để nhắc nhở bản thân.", severity: .alert))
            }
            
        } catch {
            print("InsightDetector Error: \(error)")
        }
        
        // Sort: alerts first, then warnings
        insights.sort {
            if $0.severity == .alert && $1.severity == .warning { return true }
            if $0.severity == .warning && $1.severity == .alert { return false }
            return false
        }
        
        // Cap at 3 insights
        return Array(insights.prefix(3))
    }
}
