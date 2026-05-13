import Foundation
import SwiftUI

@Observable
class MealsViewModel {
    var meals: [MealModel] = []
    var selectedDate: Date = Date()
    var isLoading = false
    var user: UserModel?
    var dailyPlan: DailyPlanModel?
    var rebalanceTrigger: RebalanceTrigger?
    var rebalanceResult: RebalanceResult?
    var isRebalancing = false
    var rebalanceError: String? = nil
    
    private let mealRepository: MealRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    private let dailyPlanRepository: DailyPlanRepositoryProtocol
    
    init(mealRepository: MealRepositoryProtocol = MealRepository(),
         userRepository: UserRepositoryProtocol = UserRepository(),
         dailyPlanRepository: DailyPlanRepositoryProtocol = DailyPlanRepository()) {
        self.mealRepository = mealRepository
        self.userRepository = userRepository
        self.dailyPlanRepository = dailyPlanRepository
    }
    
    func loadData(for date: Date? = nil, forceSilent: Bool = false) async {
        let targetDate = date ?? selectedDate
        let isInitialLoad = meals.isEmpty && !forceSilent
        
        if isInitialLoad {
            isLoading = true
        }
        
        do {
            user = try await userRepository.fetchUser()
            let fetchedMeals = try await mealRepository.fetchMeals(by: targetDate)
            
            if fetchedMeals != meals {
                meals = fetchedMeals
            }
            
            dailyPlan = try await dailyPlanRepository.fetchPlan(for: targetDate)
            
            if meals.isEmpty && isInitialLoad {
                try await Task.sleep(nanoseconds: 200_000_000)
                meals = try await mealRepository.fetchMeals(by: targetDate)
            }
            
        } catch {
            print("Error loading meals for \(targetDate): \(error)")
        }
        
        if isInitialLoad {
            isLoading = false
        }
        
        let allFoods = meals.flatMap { $0.mealFoods }.compactMap { $0.foodItem }
        BackgroundEnrichmentManager.shared.enrich(foods: allFoods)
    }
    
    func deleteMealFood(id: UUID) async {
        do {
            try await mealRepository.deleteMealFood(by: id)
            await loadData()
        } catch {
            print("Failed to delete meal food: \(error)")
        }
    }
    
    func toggleMealFoodStatus(id: UUID) async {
        let currentStatus = meals.flatMap { $0.mealFoods }.first(where: { $0.id == id })?.isEaten ?? false
        do {
            try await mealRepository.updateMealFoodStatus(id: id, isEaten: !currentStatus)
            await loadData()
        } catch {
            print("Failed to toggle meal food status: \(error)")
        }
    }
    
    // Group meals by type
    func meals(for type: String) -> [MealModel] {
        meals.filter { $0.mealType.lowercased() == type.lowercased() }
    }
    
    private var validMealTypes: [String] { ["Bữa sáng", "Bữa trưa", "Bữa tối", "Ăn vặt"] }
    
    var totalCalories: Double {
        meals
            .filter { meal in validMealTypes.contains { $0.lowercased() == meal.mealType.lowercased() } }
            .flatMap { $0.mealFoods }
            .filter { $0.isEaten }
            .reduce(0) { $0 + $1.caloriesSnapshot }
    }
    
    var dailyTarget: Double {
        user?.dailyCalorieTarget ?? 2000.0
    }
    
    var remainingCalories: Double {
        max(0, dailyTarget - totalCalories)
    }
    
    // MARK: - AI Rebalance
    
    private func checkRebalanceTrigger() {
        guard let plan = dailyPlan, plan.status == "confirmed" || plan.status == "active" else {
            self.rebalanceTrigger = nil
            return
        }
        
        let record = DailyNutritionRecord(
            date: selectedDate,
            dailyPlan: plan,
            actualMeals: meals,
            adherence: MealAdherenceCalculator.shared.calculate(
                actualMeals: meals,
                plannedMeals: plan.plannedMeals,
                targetCalories: plan.targetCalories,
                targetProtein: plan.targetProtein
            )
        )
        
        self.rebalanceTrigger = AIRebalanceService.shared.checkRebalanceNeeded(record: record)
    }
    
    func startRebalance(preference: RebalancePreference = .hybrid) async {
        guard let plan = dailyPlan else { return }
        
        await MainActor.run {
            self.isRebalancing = true
            self.rebalanceResult = nil
        }
        
        do {
            let record = DailyNutritionRecord(
                date: selectedDate,
                dailyPlan: plan,
                actualMeals: meals,
                adherence: MealAdherenceCalculator.shared.calculate(
                    actualMeals: meals,
                    plannedMeals: plan.plannedMeals,
                    targetCalories: plan.targetCalories,
                    targetProtein: plan.targetProtein
                )
            )
            
            let context = AIRebalanceService.shared.buildRebalanceContext(record: record, preference: preference)
            let result = try await AIOrchestrator.shared.generateRebalancePlan(context: context)
            
            await MainActor.run {
                self.rebalanceResult = result
                self.isRebalancing = false
            }
        } catch {
            print("Rebalance failed: \(error)")
            await MainActor.run {
                self.isRebalancing = false
            }
        }
    }
    
    func confirmRebalance() async {
        guard let result = rebalanceResult else {
            await MainActor.run { self.rebalanceError = "Không tìm thấy kết quả điều chỉnh để áp dụng." }
            return
        }
        
        guard var plan = dailyPlan else {
            await MainActor.run { self.rebalanceError = "Không tìm thấy kế hoạch gốc để cập nhật." }
            return
        }
        
        do {
            var updatedPlannedMeals = plan.plannedMeals
            
            for suggestion in result.changedMeals {
                if let idx = updatedPlannedMeals.firstIndex(where: { $0.id.uuidString.lowercased() == suggestion.plannedMealId.lowercased() }) {
                    updatedPlannedMeals[idx].status = suggestion.changeType == "removed" ? "skipped" : "planned"
                    
                    if suggestion.changeType == "portionAdjusted" || suggestion.changeType == "swapped" {
                        let newFood = PlannedFoodItemModel(
                            name: suggestion.newName ?? suggestion.oldName,
                            calories: suggestion.newCalories,
                            protein: suggestion.newProtein,
                            carbs: suggestion.newCarbs,
                            fat: suggestion.newFat,
                            servingSize: 1.0
                        )
                        updatedPlannedMeals[idx].foodItems = [newFood]
                        
                        if suggestion.changeType == "swapped" {
                            updatedPlannedMeals[idx].type = suggestion.mealType
                        }
                    }
                }
            }
            
            plan.plannedMeals = updatedPlannedMeals
            plan.isRebalanced = true
            plan.rebalanceReason = result.reason
            plan.rebalancedAt = Date()
            
            try await dailyPlanRepository.savePlan(plan, status: plan.status)
            
            await MainActor.run {
                self.rebalanceResult = nil
                self.rebalanceTrigger = nil
                HapticManager.success()
            }
            
            await loadData()
        } catch {
            print("Failed to confirm rebalance: \(error)")
            await MainActor.run {
                self.rebalanceError = "Không thể lưu kế hoạch mới: \(error.localizedDescription)"
            }
        }
    }
}
