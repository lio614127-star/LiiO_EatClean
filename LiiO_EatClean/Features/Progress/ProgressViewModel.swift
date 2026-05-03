import Foundation
import SwiftUI

enum ProgressTab: String, CaseIterable {
    case calories = "Calo"
    case weight = "Cân nặng"
}

enum TimeRange: String, CaseIterable {
    case week = "Tuần"
    case month = "Tháng"
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
    var isLoading = false
    
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
            let daysToSubtract = selectedTimeRange == .week ? 6 : 29
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
            for meal in meals {
                let day = calendar.startOfDay(for: meal.date)
                let totalCals = meal.mealFoods.reduce(0) { $0 + $1.caloriesSnapshot }
                dailyCalories[day, default: 0.0] += totalCals
            }
            
            // Convert to array and sort
            calorieData = dailyCalories.map { CalorieDailyTotal(date: $0.key, total: $0.value) }
                .sorted { $0.date < $1.date }
            
            // Load weights
            let allWeights = try await userRepository.fetchWeightEntries()
            // Filter weights by date range
            weightData = allWeights.filter { $0.date >= startDate && $0.date < endOfDay }
            
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
