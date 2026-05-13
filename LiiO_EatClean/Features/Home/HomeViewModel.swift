import Foundation
import SwiftUI

@Observable
class HomeViewModel {
    var user: UserModel?
    var todayMeals: [MealModel] = []
    var isLoading = false
    
    // Water tracking
    var waterConsumed: Double = 0
    var waterTarget: Double = 2000 // default 2000ml
    
    // Gamification
    var streak: StreakModel?
    var showMilestonePopup = false
    var milestoneValue = 0
    
    // Today Dashboard (v1.5 Two-Layer Execution)
    var dashboard = TodayDashboard(date: Date())
    
    // Smart Link Suggestions: [mealType: (mealId, plannedMealType)]
    var pendingLinkSuggestions: [String: (mealId: UUID, plannedMealType: String)] = [:]
    
    // Proactive AI
    var dailySummary: DailySummary?
    var insights: [DailyInsight]?
    var coachingInsight: CoachingInsight?
    var rebalanceTrigger: RebalanceTrigger?
    var rebalanceResult: RebalanceResult?
    var isRebalancing = false
    var rebalanceError: String? = nil
    let summaryService = DailySummaryService()
    
    private let mealRepository: MealRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    private let dailyPlanRepository: DailyPlanRepositoryProtocol
    private let streakService: StreakService
    private let metabolicRepo: MetabolicRepositoryProtocol
    private let goalOrchestrator: GoalOrchestrator
    
    init(mealRepository: MealRepositoryProtocol = MealRepository(),
         userRepository: UserRepositoryProtocol = UserRepository(),
         dailyPlanRepository: DailyPlanRepositoryProtocol = DailyPlanRepository(),
         streakService: StreakService = StreakService(),
         metabolicRepo: MetabolicRepositoryProtocol = MetabolicRepository()) {
        self.mealRepository = mealRepository
        self.userRepository = userRepository
        self.dailyPlanRepository = dailyPlanRepository
        self.streakService = streakService
        self.metabolicRepo = metabolicRepo
        self.goalOrchestrator = GoalOrchestrator(metabolicRepo: metabolicRepo)
        
        setupNotificationListeners()
    }
    
    private func setupNotificationListeners() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name("dailyPlanDidConfirm"), object: nil, queue: .main) { _ in
            Task { await self.loadDashboard() }
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name("mealLogDidUpdate"), object: nil, queue: .main) { _ in
            Task { await self.loadDashboard() }
        }
    }
    
    func loadDashboard() async {
        if todayMeals.isEmpty && user == nil {
            isLoading = true
        }
        do {
            user = try await userRepository.fetchUser()
            if let user = user {
                try await metabolicRepo.bootstrapMetabolicData(for: user)
            }
            
            let date = Date()
            let meals = try await mealRepository.fetchMeals(by: date)
            let confirmedPlan = try await dailyPlanRepository.fetchPlan(for: date)
            let water = try await userRepository.fetchWaterLog(for: date)
            
            // Calculate totals locally for streak evaluation
            let eatenFoods = meals.flatMap { $0.mealFoods }.filter { $0.isEaten }
            let totalCals = eatenFoods.reduce(0) { $0 + $1.caloriesSnapshot }
            let targetCals = user?.dailyCalorieTarget ?? 2000.0
            
            let streak = await streakService.evaluateToday(
                meals: meals,
                totalCalories: totalCals,
                dailyTarget: targetCals,
                waterConsumed: water,
                waterTarget: 2000.0
            )
            
            await MainActor.run {
                self.todayMeals = meals
                self.waterConsumed = water
                self.buildDashboard(date: date, meals: meals, confirmedPlan: confirmedPlan)
                self.checkAutoLinks(meals: meals, plan: confirmedPlan)
                
                let previousIsOverTarget = isOverTarget
                self.streak = streak
                
                if let streak = self.streak, [7, 14, 30].contains(streak.currentStreak) {
                    let calendar = Calendar.current
                    if calendar.isDateInToday(streak.lastActiveDate) && streak.conditionsMet == 3 {
                        self.milestoneValue = streak.currentStreak
                        self.showMilestonePopup = true
                    }
                }
                
                if !previousIsOverTarget && self.isOverTarget {
                    HapticManager.warning()
                }
                
                self.checkRebalanceTrigger(meals: meals, plan: confirmedPlan)
            }
        } catch {
            print("Error loading dashboard data: \(error)")
        }
        isLoading = false
        
        // Generate AI Summary in background — NOT blocking dashboard UI
        await loadDailySummaryIfNeeded()
        
        let insightDetector = InsightDetector()
        insights = await insightDetector.detectInsights()
        
        // Load Metabolic Coaching Insight
        await loadCoachingInsight()
        
        // Mandatory Background Enrichment safety trigger
        let allFoods = todayMeals.flatMap { $0.mealFoods }.compactMap { $0.foodItem }
        BackgroundEnrichmentManager.shared.enrich(foods: allFoods)
    }
    
    private var lastSummaryMealCount: Int = -1
    private var summaryDebounceTask: Task<Void, Never>?
    
    private func loadDailySummaryIfNeeded() async {
        // Only regenerate if meal data changed (avoid re-calling AI on every tab switch)
        let currentMealCount = todayMeals.flatMap { $0.mealFoods }.filter { $0.isEaten }.count
        guard currentMealCount != lastSummaryMealCount else { return }
        lastSummaryMealCount = currentMealCount
        
        // 10s Debounce Logic: Cancel existing task and start a new one
        summaryDebounceTask?.cancel()
        summaryDebounceTask = Task {
            do {
                // Wait for 10 seconds of inactivity
                try await Task.sleep(nanoseconds: 10 * 1_000_000_000)
                if Task.isCancelled { return }
                
                print("✨ Daily Summary: Debounce finished, generating summary...")
                await summaryService.generateSummary(isInternal: true)
                
                await MainActor.run {
                    self.dailySummary = summaryService.currentSummary
                }
            } catch {
                // Task was cancelled or failed
            }
        }
    }
    
    private func loadCoachingInsight() async {
        do {
            if let proposal = try await goalOrchestrator.generateProposal() {
                await MainActor.run {
                    self.coachingInsight = AICoachCommunicator.generateCoachingInsight(from: proposal)
                }
            } else {
                await MainActor.run {
                    self.coachingInsight = AICoachCommunicator.generateFallbackInsight()
                }
            }
        } catch {
            print("Failed to load coaching insight: \(error)")
        }
    }
    
    func applyGoalAdjustment(_ proposal: GoalAdjustmentProposal) async {
        do {
            // 1. Close previous version
            try await metabolicRepo.closePreviousGoalVersion(at: Date())
            
            // 2. Save new history entry
            let newGoal = GoalHistoryModel(
                calorieTarget: proposal.newCalorieTarget,
                proteinTarget: proposal.newProteinTarget,
                carbTarget: proposal.newCalorieTarget * 0.4 / 4.0,
                fatTarget: proposal.newCalorieTarget * 0.3 / 9.0,
                weight: user?.weight ?? 0,
                interventionType: proposal.intervention.severity.rawValue,
                interventionCategory: proposal.intervention.category.rawValue,
                reason: proposal.intervention.reason,
                source: "aiSuggestion",
                effectiveFrom: Date(),
                version: 2
            )
            try await metabolicRepo.saveGoalHistory(newGoal)
            
            // 3. Update User Profile for backward compatibility
            if var currentUser = user {
                currentUser.dailyCalorieTarget = proposal.newCalorieTarget
                try await userRepository.saveUser(currentUser)
                self.user = currentUser
            }
            
            // 4. Refresh Dashboard
            await loadDashboard()
            HapticManager.success()
        } catch {
            print("Failed to apply goal adjustment: \(error)")
        }
    }
    
    func addWater(amount: Double) async {
        do {
            try await userRepository.addWater(amount: amount, for: Date())
            waterConsumed += amount
            await refreshStreak()
        } catch {
            print("Failed to log water: \(error)")
        }
    }
    
    func resetWater() async {
        do {
            try await userRepository.resetWater(for: Date())
            waterConsumed = 0
            await refreshStreak()
        } catch {
            print("Failed to reset water: \(error)")
        }
    }
    
    private func refreshStreak() async {
        let newStreak = await streakService.evaluateToday(
            meals: todayMeals,
            totalCalories: totalCalories,
            dailyTarget: dailyTarget,
            waterConsumed: waterConsumed,
            waterTarget: waterTarget
        )
        await MainActor.run {
            self.streak = newStreak
        }
    }
    
    private func buildDashboard(date: Date, meals: [MealModel], confirmedPlan: DailyPlanModel?) {
        var newDashboard = TodayDashboard(date: date)
        
        if let plan = confirmedPlan, plan.status == "confirmed" || plan.status == "active" {
            newDashboard.confirmedDailyPlan = plan
            newDashboard.plannedCalories = plan.targetCalories
            newDashboard.plannedProtein = plan.targetProtein
            
            // Sort planned meals by type
            let sortedPlanned = plan.plannedMeals.sorted { 
                self.mealTypeOrder($0.type) < self.mealTypeOrder($1.type)
            }
            
            for pm in sortedPlanned {
                switch pm.status {
                case "eaten":
                    newDashboard.eatenPlannedMeals.append(pm)
                case "skipped":
                    newDashboard.skippedPlannedMeals.append(pm)
                default:
                    newDashboard.pendingPlannedMeals.append(pm)
                }
            }
        }
        
        newDashboard.actualMealLogs = meals.sorted { 
            self.mealTypeOrder($0.mealType) < self.mealTypeOrder($1.mealType)
        }
        
        // Unplanned meals: logs that are not linked to a planned meal in the current plan
        let linkedIdsInPlan = Set(newDashboard.confirmedDailyPlan?.plannedMeals.map { $0.id } ?? [])
        newDashboard.unplannedMealLogs = meals.filter { meal in
            if let linkedId = meal.linkedPlannedMealId {
                return !linkedIdsInPlan.contains(linkedId)
            }
            return true
        }
        
        // Calculate Actual Totals
        let eatenFoods = meals.flatMap { $0.mealFoods }.filter { $0.isEaten }
        newDashboard.actualCalories = eatenFoods.reduce(0) { $0 + $1.caloriesSnapshot }
        newDashboard.actualProtein = eatenFoods.reduce(0) { $0 + $1.proteinSnapshot }
        newDashboard.actualCarbs = eatenFoods.reduce(0) { $0 + $1.carbsSnapshot }
        newDashboard.actualFat = eatenFoods.reduce(0) { $0 + $1.fatSnapshot }
        
        self.dashboard = newDashboard
    }
    
    // MARK: - Actions
    
    func markAsEaten(plannedMeal: PlannedMealModel) async {
        guard plannedMeal.actualMealLogId == nil else { return }
        
        let date = Date()
        let mealFoods = plannedMeal.foodItems.map { food in
            MealFoodModel(
                quantity: 1.0,
                caloriesSnapshot: food.calories,
                proteinSnapshot: food.protein,
                carbsSnapshot: food.carbs,
                fatSnapshot: food.fat,
                isEaten: true,
                foodItem: FoodItemModel(
                    id: food.id,
                    name: food.name,
                    calories: food.calories,
                    protein: food.protein,
                    carbs: food.carbs,
                    fat: food.fat,
                    servingSize: food.servingSize,
                    source: "plan"
                )
            )
        }
        
        let actualMeal = MealModel(
            date: date,
            mealType: plannedMeal.type,
            source: "plannedMeal",
            linkedPlannedMealId: plannedMeal.id,
            mealFoods: mealFoods
        )
        
        do {
            try await mealRepository.saveMeal(actualMeal, for: date)
            
            // Update PlannedMeal status
            if var plan = dashboard.confirmedDailyPlan {
                if let idx = plan.plannedMeals.firstIndex(where: { $0.id == plannedMeal.id }) {
                    plan.plannedMeals[idx].status = "eaten"
                    plan.plannedMeals[idx].actualMealLogId = actualMeal.id
                    plan.plannedMeals[idx].eatenAt = date
                    try await dailyPlanRepository.savePlan(plan, status: plan.status)
                }
            }
            
            HapticManager.success()
            await loadDashboard()
            
            // Background enrichment
            BackgroundEnrichmentManager.shared.enrich(foods: actualMeal.mealFoods.compactMap { $0.foodItem })
            
        } catch {
            print("Failed to mark planned meal as eaten: \(error)")
        }
    }
    
    func skipPlannedMeal(plannedMeal: PlannedMealModel) async {
        guard var plan = dashboard.confirmedDailyPlan else { return }
        
        if let idx = plan.plannedMeals.firstIndex(where: { $0.id == plannedMeal.id }) {
            plan.plannedMeals[idx].status = "skipped"
            do {
                try await dailyPlanRepository.savePlan(plan, status: plan.status)
                HapticManager.success()
                await loadDashboard()
            } catch {
                print("Failed to skip planned meal: \(error)")
            }
        }
    }
    
    func deleteMealFood(id: UUID) async {
        do {
            try await mealRepository.deleteMealFood(by: id)
            HapticManager.success()
            await loadDashboard()
        } catch {
            print("Failed to delete meal food: \(error)")
        }
    }
    
    // Computed properties for Dashboard
    private var validMealTypes: [String] { ["Bữa sáng", "Bữa trưa", "Bữa tối", "Ăn vặt"] }
    
    var totalCalories: Double {
        dashboard.actualCalories
    }
    
    var totalProtein: Double {
        dashboard.actualProtein
    }
    
    var totalCarbs: Double {
        dashboard.actualCarbs
    }
    
    var totalFat: Double {
        dashboard.actualFat
    }
    
    var dailyTarget: Double {
        user?.dailyCalorieTarget ?? 2000.0
    }
    
    var remainingCalories: Double {
        max(0, dailyTarget - totalCalories)
    }
    
    var isOverTarget: Bool {
        totalCalories > dailyTarget
    }
    
    // Macro targets derived from calorie target (30% Protein, 40% Carbs, 30% Fat)
    var proteinTarget: Double {
        (dailyTarget * 0.30) / 4.0
    }
    
    var carbsTarget: Double {
        (dailyTarget * 0.40) / 4.0
    }
    
    var fatTarget: Double {
        (dailyTarget * 0.30) / 9.0
    }
    
    func meals(for type: String) -> [MealModel] {
        todayMeals.filter { $0.mealType.lowercased() == type.lowercased() }
    }
    
    func toggleMealFoodStatus(id: UUID) async {
        let currentStatus = todayMeals.flatMap { $0.mealFoods }.first(where: { $0.id == id })?.isEaten ?? false
        do {
            try await mealRepository.updateMealFoodStatus(id: id, isEaten: !currentStatus)
            await loadDashboard()
        } catch {
            print("Failed to toggle meal food status: \(error)")
        }
    }
    
    private func mealTypeOrder(_ mealType: String) -> Int {
        let normalized = mealType.lowercased().trimmingCharacters(in: .whitespaces)
        switch normalized {
        case "breakfast", "sang", "bữa sáng": return 0
        case "lunch", "trua", "bữa trưa": return 1
        case "dinner", "toi", "bữa tối": return 2
        case "snack", "an vat", "ăn vặt": return 3
        default: return 4
        }
    }
    
    // MARK: - Smart Auto-Link
    
    private func checkAutoLinks(meals: [MealModel], plan: DailyPlanModel?) {
        guard let plan = plan else {
            pendingLinkSuggestions = [:]
            return
        }
        
        let unlinkedMeals = meals.filter { $0.linkedPlannedMealId == nil }
        var suggestions: [String: (mealId: UUID, plannedMealType: String)] = [:]
        
        for meal in unlinkedMeals {
            let candidates = MealPlanLinkingService.shared.findCandidateLinks(for: meal, in: plan)
            if let best = candidates.first {
                if best.confidence >= 0.90 {
                    // Auto-link in background
                    Task {
                        let result = await MealPlanLinkingService.shared.tryAutoLink(
                            mealLog: meal,
                            dailyPlan: plan,
                            mealRepository: mealRepository,
                            dailyPlanRepository: dailyPlanRepository
                        )
                        if case .linked = result {
                            await loadDashboard()
                        }
                    }
                } else if best.confidence >= 0.70 {
                    // Show suggestion chip
                    suggestions[meal.mealType] = (mealId: meal.id, plannedMealType: best.plannedMeal.type)
                }
            }
        }
        
        pendingLinkSuggestions = suggestions
    }
    
    func linkMealToPlan(mealId: UUID) async {
        guard let meal = todayMeals.first(where: { $0.id == mealId }),
              let plan = dashboard.confirmedDailyPlan,
              let suggestion = pendingLinkSuggestions[meal.mealType] else { return }
        
        // Find the planned meal ID by type
        guard let plannedMeal = plan.plannedMeals.first(where: { $0.type.lowercased().trimmingCharacters(in: .whitespaces) == suggestion.plannedMealType.lowercased().trimmingCharacters(in: .whitespaces) && $0.status == "planned" && $0.actualMealLogId == nil }) else { return }
        
        let success = await MealPlanLinkingService.shared.forceLink(
            mealLog: meal,
            dailyPlan: plan,
            plannedMealId: plannedMeal.id,
            mealRepository: mealRepository,
            dailyPlanRepository: dailyPlanRepository
        )
        
        if success {
            HapticManager.success()
            await loadDashboard()
        }
    }
    
    // MARK: - AI Rebalance
    
    private func checkRebalanceTrigger(meals: [MealModel], plan: DailyPlanModel?) {
        guard let plan = plan, plan.status == "confirmed" else {
            self.rebalanceTrigger = nil
            return
        }
        
        let record = DailyNutritionRecord(
            date: Date(),
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
        guard let plan = dashboard.confirmedDailyPlan else { return }
        
        await MainActor.run {
            self.isRebalancing = true
            self.rebalanceResult = nil
        }
        
        do {
            let record = DailyNutritionRecord(
                date: Date(),
                dailyPlan: plan,
                actualMeals: todayMeals,
                adherence: MealAdherenceCalculator.shared.calculate(
                    actualMeals: todayMeals,
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
                self.rebalanceError = nil
            }
        } catch {
            print("Rebalance failed: \(error)")
            await MainActor.run {
                self.isRebalancing = false
                self.rebalanceError = "Không thể kết nối với AI hoặc dữ liệu không hợp lệ. Vui lòng thử lại sau."
            }
        }
    }
    
    func confirmRebalance() async {
        guard let result = rebalanceResult else {
            await MainActor.run { self.rebalanceError = "Không tìm thấy kết quả điều chỉnh để áp dụng." }
            return 
        }
        
        guard var plan = dashboard.confirmedDailyPlan else {
            await MainActor.run { self.rebalanceError = "Không tìm thấy kế hoạch gốc để cập nhật." }
            return
        }
        
        do {
            var updatedPlannedMeals = plan.plannedMeals
            
            for suggestion in result.changedMeals {
                // Sử dụng case-insensitive matching cho ID
                if let idx = updatedPlannedMeals.firstIndex(where: { $0.id.uuidString.lowercased() == suggestion.plannedMealId.lowercased() }) {
                    // Update the meal
                    updatedPlannedMeals[idx].status = suggestion.changeType == "removed" ? "skipped" : "planned"
                    
                    // Update food items if it was portionAdjusted or swapped
                    if suggestion.changeType == "portionAdjusted" || suggestion.changeType == "swapped" {
                        // For simplicity, we create a new food item model with the new cal/macros
                        // In a real app, we might want to keep the same food ID if it's the same dish
                        let newFood = PlannedFoodItemModel(
                            name: suggestion.newName ?? suggestion.oldName,
                            calories: suggestion.newCalories,
                            protein: suggestion.newProtein,
                            carbs: suggestion.newCarbs,
                            fat: suggestion.newFat,
                            servingSize: 1.0 // Simplified
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
            
            await loadDashboard()
            
        } catch {
            print("Failed to confirm rebalance: \(error)")
            await MainActor.run {
                self.rebalanceError = "Không thể lưu kế hoạch mới: \(error.localizedDescription)"
            }
        }
    }
}
