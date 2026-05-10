import Foundation
import SwiftUI

enum ProgressTab: String, CaseIterable {
    case calories = "Calo"
    case weight = "Cân nặng"
}

enum TimeRange: String, CaseIterable {
    case week = "7N"
    case month = "30N"
    case quarter = "3T"
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
    var isLoading = false
    
    var macroAggregate: MacroAggregate?
    var macroTarget: MacroTarget?
    var macroTrend: MacroTrend?
    
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
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let daysToSubtract: Int
            switch selectedTimeRange {
            case .week: daysToSubtract = 6
            case .month: daysToSubtract = 29
            case .quarter: daysToSubtract = 89 // 90 days total for 12+ weeks
            }
            guard let startDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: today) else { return }
            
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: today)!
            
            // Load and aggregate meals
            let meals = try await mealRepository.fetchMeals(from: startDate, to: endOfDay)
            print("📊 Progress: Fetched \(meals.count) meals from \(startDate) to \(endOfDay)")
            for meal in meals {
                print("  - Meal on \(meal.date): \(meal.mealFoods.count) items, total \(meal.mealFoods.reduce(0) { $0 + $1.caloriesSnapshot }) kcal")
            }
            
            var dailyCalories: [Date: Double] = [:]
            
            // Initialize all days in range with 0
            for i in 0...daysToSubtract {
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
            
            macroTarget = MacroTarget.default(calories: dailyTarget)
            
            // Calculate Macro Trend (30N and 3T only)
            if selectedTimeRange != .week && meals.count > 7 {
                let midPoint = calendar.date(byAdding: .day, value: -daysToSubtract / 2, to: today)!
                
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
            // Filter weights by date range
            weightData = allWeights.filter { $0.date >= startDate && $0.date < endOfDay }
            
            // Calculate Weekly Aggregates if quarter is selected
            if selectedTimeRange == .quarter {
                var newWeeklyData: [WeeklyAggregate] = []
                var currentStart = startDate
                var weekNum = 1
                
                while currentStart < endOfDay {
                    let nextStart = calendar.date(byAdding: .day, value: 7, to: currentStart) ?? endOfDay
                    let chunkEnd = Swift.min(nextStart, endOfDay)
                    
                    let mealsInWeek = meals.filter { $0.date >= currentStart && $0.date < chunkEnd }
                    let weightsInWeek = allWeights.filter { $0.date >= currentStart && $0.date < chunkEnd }.sorted { $0.date < $1.date }
                    
                    // Sum up calories from meals in the week
                    let totalCaloriesInWeek = mealsInWeek.reduce(0.0) { sum, meal in
                        sum + meal.mealFoods.reduce(0) { $0 + $1.caloriesSnapshot }
                    }
                    
                    // Find unique days with logged meals to avoid punishing if they just didn't use the app,
                    // OR simple average by 7. We'll average by 7 to show daily average intake across the week.
                    let avgCals = totalCaloriesInWeek / 7.0
                    
                    newWeeklyData.append(WeeklyAggregate(
                        weekNumber: weekNum,
                        averageCalories: avgCals,
                        lastWeight: weightsInWeek.last?.weight,
                        startDate: currentStart,
                        endDate: chunkEnd
                    ))
                    
                    currentStart = chunkEnd
                    weekNum += 1
                }
                self.weeklyData = newWeeklyData
            } else {
                self.weeklyData = []
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
}
