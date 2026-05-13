import Foundation
import SwiftUI

// 

enum ProgressTab: String, CaseIterable {
    case calories = "Calo"
    case adherence = "Kỷ luật"
    case weight = "Cân nặng"
}

enum TimeRange: String, CaseIterable {
    case week = "7N"
    case month = "30N"
    case quarter = "3T"
    case custom = "Tùy chọn"
}

struct CalorieDailyTotal: Identifiable {
    let id = UUID()
    let date: Date
    let total: Double
}

@Observable
class ProgressViewModel {
    var selectedTab: ProgressTab = .calories
    var selectedTimeRange: TimeRange = .week {
        didSet {
            // Need to wrap in Task if property observers support it, but SwiftUI usually prefers onChange in View for async tasks, or manual triggering.
            // However, we'll manually trigger it from the View when picker changes to ensure clean concurrency.
        }
    }
    
    var dailyTarget: Double = 2000.0
    var calorieData: [CalorieDailyTotal] = []
    var weightData: [WeightEntryModel] = []
    var weeklyData: [WeeklyAggregate] = []
    var monthlyData: [MonthlyAggregate] = []
    var isLoading = false
    
    var periodOffset: Int = 0
    var customStartDate: Date = Calendar.current.date(byAdding: .day, value: -6, to: Date())!
    var customEndDate: Date = Date()
    
    var currentDateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var start: Date
        var end: Date
        
        switch selectedTimeRange {
        case .week:
            let anchor = calendar.startOfDay(for: today)
            let offset = periodOffset * 7
            let currentAnchor = calendar.date(byAdding: .day, value: offset, to: anchor)!
            start = calendar.date(byAdding: .day, value: -6, to: currentAnchor)!
            end = currentAnchor
        case .month:
            let anchor = calendar.date(byAdding: .day, value: periodOffset * 30, to: today)!
            start = calendar.date(byAdding: .day, value: -29, to: anchor)!
            end = anchor
        case .quarter:
            let anchor = calendar.date(byAdding: .day, value: periodOffset * 90, to: today)!
            start = calendar.date(byAdding: .day, value: -89, to: anchor)!
            end = anchor
        case .custom:
            let duration = calendar.dateComponents([.day], from: customStartDate, to: customEndDate).day ?? 1
            let offsetDays = periodOffset * (duration + 1)
            start = calendar.date(byAdding: .day, value: offsetDays, to: customStartDate)!
            end = calendar.date(byAdding: .day, value: offsetDays, to: customEndDate)!
        }
        
        let finalEnd = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: end) ?? end
        return (calendar.startOfDay(for: start), finalEnd)
    }
    
    var macroAggregate: MacroAggregate?
    var macroTarget: MacroTarget?
    var macroTrend: MacroTrend?
    
    // Weekly Flex Budget
    var weeklyRemainingCalories: Double = 0
    var weeklyAverageCalories: Double = 0
    var weeklyAdherenceScore: Double = 0
    
    private let mealRepository: MealRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    
    init(mealRepository: MealRepositoryProtocol = MealRepository(),
         userRepository: UserRepositoryProtocol = UserRepository()) {
        self.mealRepository = mealRepository
        self.userRepository = userRepository
    }
    
    func loadData() async {
        isLoading = true
        do {
            let user = try await userRepository.fetchUser()
            dailyTarget = user?.dailyCalorieTarget ?? 2000.0
            
            // Calculate start and end date
            let range = currentDateRange
            let startDate = range.start
            let endOfDay = range.end
            
            let calendar = Calendar.current
            let daysInRange = calendar.dateComponents([.day], from: startDate, to: endOfDay).day ?? 1
            
            // Load and aggregate meals
            let meals = try await mealRepository.fetchMeals(from: startDate, to: endOfDay)
            print("📊 Progress: Fetched \(meals.count) meals from \(startDate) to \(endOfDay)")
            for meal in meals {
                print("  - Meal on \(meal.date): \(meal.mealFoods.count) items, total \(meal.mealFoods.reduce(0) { $0 + $1.caloriesSnapshot }) kcal")
            }
            
            var dailyCalories: [Date: Double] = [:]
            
            // Initialize all days in range with 0
            for i in 0...daysInRange {
                if let day = calendar.date(byAdding: .day, value: i, to: startDate) {
                    dailyCalories[calendar.startOfDay(for: day)] = 0.0
                }
            }
            
            // Accumulate meal calories
            var totalProtein: Double = 0
            var totalCarbs: Double = 0
            var totalFat: Double = 0
            var totalCalsForMacro: Double = 0
            
            for meal in meals {
                let day = calendar.startOfDay(for: meal.date)
                let totalCals = meal.mealFoods.reduce(0) { $0 + $1.caloriesSnapshot }
                dailyCalories[day, default: 0.0] += totalCals
                
                for food in meal.mealFoods {
                    totalProtein += food.proteinSnapshot * food.quantity
                    totalCarbs += food.carbsSnapshot * food.quantity
                    totalFat += food.fatSnapshot * food.quantity
                    totalCalsForMacro += food.caloriesSnapshot * food.quantity
                }
            }
            
            let activeDays = dailyCalories.values.filter { $0 > 0 }.count
            macroAggregate = MacroAggregate(
                totalProtein: totalProtein,
                totalCarbs: totalCarbs,
                totalFat: totalFat,
                totalCalories: totalCalsForMacro,
                daysCount: max(activeDays, 1)
            )
            
            // Calculate Weekly Remainder (Current week only)
            if selectedTimeRange == .week && periodOffset == 0 {
                let weekCals = dailyCalories.values.reduce(0, +)
                let daysSoFar = calendar.dateComponents([.day], from: startDate, to: calendar.startOfDay(for: Date())).day ?? 0
                let elapsedDays = daysSoFar + 1
                let totalWeekTarget = dailyTarget * 7.0
                weeklyRemainingCalories = max(0, totalWeekTarget - weekCals)
                weeklyAverageCalories = weekCals / Double(elapsedDays)
                weeklyAdherenceScore = 1.0 - (abs(weeklyAverageCalories - dailyTarget) / dailyTarget)
            }
            
            macroTarget = MacroTarget.default(calories: dailyTarget)
            
            // Calculate Macro Trend (aggregated views only)
            if daysInRange >= 7 && meals.count > 0 {
                let midPoint = calendar.date(byAdding: .day, value: daysInRange / 2, to: startDate)!
                
                let firstHalfMeals = meals.filter { $0.date < midPoint }
                let secondHalfMeals = meals.filter { $0.date >= midPoint }
                
                func avgMacro(_ mealList: [MealModel], _ keyPath: KeyPath<MealFoodModel, Double>) -> Double {
                    let total = mealList.flatMap { $0.mealFoods }.reduce(0.0) { $0 + $1[keyPath: keyPath] * $1.quantity }
                    let days = max(Set(mealList.map { calendar.startOfDay(for: $0.date) }).count, 1)
                    return total / Double(days)
                }
                
                func trend(_ first: Double, _ second: Double) -> MacroTrend.TrendDirection {
                    let change = second - first
                    let threshold = max(first * 0.1, 3.0) // 10% or 3g minimum threshold
                    if change > threshold { return .up }
                    if change < -threshold { return .down }
                    return .stable
                }
                
                let pFirst = avgMacro(firstHalfMeals, \.proteinSnapshot)
                let pSecond = avgMacro(secondHalfMeals, \.proteinSnapshot)
                let cFirst = avgMacro(firstHalfMeals, \.carbsSnapshot)
                let cSecond = avgMacro(secondHalfMeals, \.carbsSnapshot)
                let fFirst = avgMacro(firstHalfMeals, \.fatSnapshot)
                let fSecond = avgMacro(secondHalfMeals, \.fatSnapshot)
                
                macroTrend = MacroTrend(
                    proteinTrend: trend(pFirst, pSecond),
                    carbsTrend: trend(cFirst, cSecond),
                    fatTrend: trend(fFirst, fSecond)
                )
            } else {
                macroTrend = nil
            }
            
            // Convert to array and sort
            calorieData = dailyCalories.map { CalorieDailyTotal(date: $0.key, total: $0.value) }
                .sorted { $0.date < $1.date }
            
            // Load weights
            let allWeights = try await userRepository.fetchWeightEntries()
            weightData = allWeights.filter { $0.date >= startDate && $0.date <= endOfDay }
            
            // Smart Aggregation
            if daysInRange <= 31 {
                self.weeklyData = []
                self.monthlyData = []
            } else if daysInRange <= 120 {
                // Weekly Aggregation
                self.monthlyData = []
                var newWeeklyData: [WeeklyAggregate] = []
                var currentStart = startDate
                var weekNum = 1
                
                while currentStart < endOfDay {
                    let nextStart = calendar.date(byAdding: .day, value: 7, to: currentStart) ?? endOfDay
                    let chunkEnd = Swift.min(nextStart, endOfDay)
                    
                    let mealsInWeek = meals.filter { $0.date >= currentStart && $0.date < chunkEnd }
                    let weightsInWeek = allWeights.filter { $0.date >= currentStart && $0.date < chunkEnd }.sorted { $0.date < $1.date }
                    
                    let dailyCalsInWeek = dailyCalories.filter { $0.key >= currentStart && $0.key < chunkEnd }.values
                    let avgCals = dailyCalsInWeek.isEmpty ? 0 : dailyCalsInWeek.reduce(0, +) / Double(dailyCalsInWeek.count)
                    let minCals = dailyCalsInWeek.min() ?? 0
                    let maxCals = dailyCalsInWeek.max() ?? 0
                    
                    newWeeklyData.append(WeeklyAggregate(
                        weekNumber: weekNum,
                        averageCalories: avgCals,
                        minCalories: minCals,
                        maxCalories: maxCals,
                        lastWeight: weightsInWeek.last?.weight,
                        startDate: currentStart,
                        endDate: chunkEnd
                    ))
                    
                    currentStart = chunkEnd
                    weekNum += 1
                }
                self.weeklyData = newWeeklyData
            } else {
                // Monthly Aggregation
                self.weeklyData = []
                var newMonthlyData: [MonthlyAggregate] = []
                var currentStart = startDate
                
                while currentStart < endOfDay {
                    guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentStart) else { break }
                    let chunkEnd = self.startOfMonth(for: nextMonth)
                    
                    let actualEnd = Swift.min(chunkEnd, endOfDay)
                    if currentStart >= actualEnd { break }
                    
                    let weightsInMonth = allWeights.filter { $0.date >= currentStart && $0.date < actualEnd }.sorted { $0.date < $1.date }
                    let dailyCalsInMonth = dailyCalories.filter { $0.key >= currentStart && $0.key < actualEnd }.values
                    let avgCals = dailyCalsInMonth.isEmpty ? 0 : dailyCalsInMonth.reduce(0, +) / Double(dailyCalsInMonth.count)
                    let minCals = dailyCalsInMonth.min() ?? 0
                    let maxCals = dailyCalsInMonth.max() ?? 0
                    
                    let components = calendar.dateComponents([.month, .year], from: currentStart)
                    
                    newMonthlyData.append(MonthlyAggregate(
                        month: components.month ?? 0,
                        year: components.year ?? 0,
                        averageCalories: avgCals,
                        minCalories: minCals,
                        maxCalories: maxCals,
                        lastWeight: weightsInMonth.last?.weight,
                        startDate: currentStart,
                        endDate: actualEnd
                    ))
                    
                    currentStart = actualEnd
                }
                self.monthlyData = newMonthlyData
            }
            
        } catch {
            print("Error loading progress data: \(error)")
        }
        isLoading = false
    }
    
    func saveWeight(_ weight: Double) async {
        let entry = WeightEntryModel(id: UUID(), date: Date(), weight: weight)
        do {
            try await userRepository.saveWeightEntry(entry)
            await loadData()
        } catch {
            print("Error saving weight: \(error)")
        }
    }
    
    private func startOfMonth(for date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components)!
    }
}
