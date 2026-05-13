import Foundation
import SwiftUI

@Observable
class MealPlanViewModel {
    // Plan state
    var selectedDate: Date = Date()
    var planItems: [AISuggestedFood] = []
    var isLoading = false
    var errorMessage: String?
    var showLogSuccess = false
    var healthSafetyApplied = false
    var dailyPlanStatus: String = "draft"
    
    // Journal state
    var dailyRecord: DailyNutritionRecord?
    var pendingLinks: [LinkCandidate] = []
    
    // Weekly plan state
    var weeklyPlan: [WeeklyDayPlan] = []
    var isLoadingWeekly = false
    var weeklyErrorMessage: String?
    var selectedWeekDay: Int? = nil
    var weekOffset: Int = 0
    var datesToGenerate: [Date] = [] // ⚡ Dates targeted for smart fill generation // ⚡ Added week navigation offset
    
    // Background Task Management
    private var generationTask: Task<Void, Never>?
    private var weeklyGenerationTask: Task<Void, Never>?
    
    private let aiService = AIService.shared
    private let contextBuilder = ContextBuilder()
    private let mealRepository: MealRepositoryProtocol
    private let dailyPlanRepository: DailyPlanRepositoryProtocol
    private let memoryManager: MemoryManagerProtocol
    
    // Canonical Vietnamese meal types
    static let mealTypes = ["Bữa sáng", "Bữa trưa", "Bữa tối", "Ăn vặt"]
    static let mealIcons: [String: String] = [
        "Bữa sáng": "🌅",
        "Bữa trưa": "🌤",
        "Bữa tối": "🌙",
        "Ăn vặt": "🍎"
    ]
    
    init(mealRepository: MealRepositoryProtocol = MealRepository(),
         dailyPlanRepository: DailyPlanRepositoryProtocol = DailyPlanRepository(),
         memoryManager: MemoryManagerProtocol = MemoryManager.shared) {
        self.mealRepository = mealRepository
        self.dailyPlanRepository = dailyPlanRepository
        self.memoryManager = memoryManager
        
        Task {
            try? await self.dailyPlanRepository.cleanupOldDrafts()
        }
    }
    
    // MARK: - Persistence Check
    
    func saveDraftPlan(targetCalories: Double) {
        let plan = DailyPlanModel(
            date: selectedDate,
            status: "draft",
            targetCalories: targetCalories,
            targetProtein: targetCalories * 0.3 / 4,
            targetCarbs: targetCalories * 0.4 / 4,
            targetFat: targetCalories * 0.3 / 9,
            plannedMeals: groupItemsIntoPlannedMeals()
        )
        Task {
            try? await dailyPlanRepository.savePlan(plan, status: "draft")
            await MainActor.run {
                self.dailyPlanStatus = "draft"
            }
        }
    }
    
    private func groupItemsIntoPlannedMeals() -> [PlannedMealModel] {
        var grouped: [String: [PlannedFoodItemModel]] = [:]
        for item in planItems {
            let type = item.mealType ?? "Ăn vặt"
            let foodModel = PlannedFoodItemModel(
                name: item.name,
                calories: item.calories,
                protein: item.protein,
                carbs: item.carbs,
                fat: item.fat,
                servingSize: item.servingSize
            )
            grouped[type, default: []].append(foodModel)
        }
        
        return grouped.map { (type, foods) in
            PlannedMealModel(type: type, foodItems: foods)
        }
    }
    
    func loadExistingPlan(for date: Date? = nil) async -> Bool {
        let targetDate = date ?? selectedDate
        
        // 1. Try to load AI-generated plan from CoreData DailyPlan
        do {
            if let dailyPlan = try await dailyPlanRepository.fetchPlan(for: targetDate) {
                // Map DailyPlanModel to planItems
                var loadedItems: [AISuggestedFood] = []
                for meal in dailyPlan.plannedMeals {
                    for food in meal.foodItems {
                        let suggested = AISuggestedFood(
                            name: food.name,
                            calories: food.calories,
                            protein: food.protein,
                            carbs: food.carbs,
                            fat: food.fat,
                            servingSize: food.servingSize,
                            mealType: meal.type
                        )
                        loadedItems.append(suggested)
                    }
                }
                
                let loggedMeals = try await mealRepository.fetchMeals(by: targetDate)
                
                await MainActor.run {
                    self.selectedDate = targetDate
                    self.planItems = loadedItems
                    self.dailyPlanStatus = dailyPlan.status
                    
                    // Build Journal Record
                    let adherence = MealAdherenceCalculator.shared.calculate(
                        actualMeals: loggedMeals,
                        plannedMeals: dailyPlan.plannedMeals,
                        targetCalories: dailyPlan.targetCalories,
                        targetProtein: dailyPlan.targetProtein
                    )
                    
                    self.dailyRecord = DailyNutritionRecord(
                        date: targetDate,
                        dailyPlan: dailyPlan,
                        actualMeals: loggedMeals,
                        adherence: adherence
                    )
                    
                    // Check for potential links
                    self.updatePendingLinks(actualMeals: loggedMeals, dailyPlan: dailyPlan)
                }
                return true
            }
        } catch {
            print("Error loading DailyPlan: \(error)")
        }
        
        // 2. Fallback to just loading whatever is in the DB
        do {
            let meals = try await mealRepository.fetchMeals(by: targetDate)
            if !meals.isEmpty {
                var loadedItems: [AISuggestedFood] = []
                
                for meal in meals {
                    for mf in meal.mealFoods {
                        if let food = mf.foodItem {
                            var suggested = AISuggestedFood(
                                name: food.name,
                                calories: food.calories,
                                protein: food.protein,
                                carbs: food.carbs,
                                fat: food.fat,
                                servingSize: food.servingSize,
                                mealType: meal.mealType,
                                unit: food.unit,
                                weightInGrams: food.weightInGrams,
                                ingredients: food.ingredients?.map { IngredientDTO(name: $0.name, amount: $0.amount, unit: $0.unit, protein: $0.protein, carbs: $0.carbs, fat: $0.fat) },
                                instructions: food.instructions
                            )
                            suggested.id = food.id // Keep ID consistent
                            loadedItems.append(suggested)
                        }
                    }
                }
                
                if !loadedItems.isEmpty {
                    await MainActor.run {
                        self.selectedDate = targetDate
                        self.planItems = loadedItems
                        
                        // ⚡ Phase 26: Update dailyRecord in fallback mode
                        let adherence = MealAdherenceCalculator.shared.calculate(
                            actualMeals: meals,
                            plannedMeals: [],
                            targetCalories: 2000, // Fallback target
                            targetProtein: 150
                        )
                        
                        self.dailyRecord = DailyNutritionRecord(
                            date: targetDate,
                            dailyPlan: nil,
                            actualMeals: meals,
                            adherence: adherence
                        )
                    }
                    return true
                }
            }
        } catch {
            print("Error checking existing plan: \(error)")
        }
        
        await MainActor.run {
            self.selectedDate = targetDate
            self.planItems = []
            self.dailyRecord = nil // ⚡ Phase 26: Clear journal record for empty state
        }
        return false
    }
    
    // MARK: - Day Plan Generation
    
    func generateDayPlan(targetCalories: Double) {
        guard !isLoading else { return }
        
        generationTask?.cancel()
        generationTask = Task {
            await MainActor.run {
                self.isLoading = true
                self.errorMessage = nil
                self.planItems = []
                self.healthSafetyApplied = false
            }
            
            do {
                let userContext = try await contextBuilder.buildFullUserContext()
                
                // ⚡ Single-pass Turbo Planning with Streaming
                let allFoods = try await AIOrchestrator.shared.generateDayPlanStreaming(
                    targetCalories: targetCalories,
                    userContext: userContext,
                    completedMealTypes: [], // ⚡ Always request all meals
                    isInternal: true
                ) { meal in
                    // Streaming update: Show meal immediately
                    Task { @MainActor in
                        var normalizedMeal = meal
                        normalizedMeal.mealType = Self.normalizeMealType(meal.mealType ?? "Ăn vặt")
                        self.planItems.append(normalizedMeal)
                        HapticManager.interaction()
                    }
                }
                
                // Final validation & Safety
                if allFoods.isEmpty {
                    await MainActor.run { 
                        self.errorMessage = "AI không thể tạo kế hoạch lúc này." 
                        self.isLoading = false
                    }
                    return
                }
                
                // Perform Safety Validation on the final set
                let memory = try await AIMemoryRepository.shared.fetchMemory()
                let validatedFoods = try await performSafetyCheck(items: allFoods, memory: memory)
                
                do {
                    let existingMeals = try await self.mealRepository.fetchMeals(by: self.selectedDate)
                    
                    await MainActor.run {
                        self.planItems = Self.validateCalories(items: validatedFoods, target: targetCalories)
                        self.isLoading = false
                        self.dailyPlanStatus = "draft"
                        self.saveDraftPlan(targetCalories: targetCalories)
                        
                        // ⚡ Phase 26: Update dailyRecord immediately for UI sync
                        let dailyPlan = DailyPlanModel(
                            date: selectedDate,
                            status: "draft",
                            targetCalories: targetCalories,
                            targetProtein: targetCalories * 0.3 / 4,
                            targetCarbs: targetCalories * 0.4 / 4,
                            targetFat: targetCalories * 0.3 / 9,
                            plannedMeals: groupItemsIntoPlannedMeals()
                        )
                        
                        let adherence = MealAdherenceCalculator.shared.calculate(
                            actualMeals: existingMeals,
                            plannedMeals: dailyPlan.plannedMeals,
                            targetCalories: targetCalories,
                            targetProtein: dailyPlan.targetProtein
                        )
                        
                        self.dailyRecord = DailyNutritionRecord(
                            date: selectedDate,
                            dailyPlan: dailyPlan,
                            actualMeals: existingMeals,
                            adherence: adherence
                        )
                        
                        // Check for potential links
                        self.updatePendingLinks(actualMeals: existingMeals, dailyPlan: dailyPlan)
                    }
                } catch {
                    print("Error updating dailyRecord after generation: \(error)")
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Lỗi lập kế hoạch: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func performSafetyCheck(items: [AISuggestedFood], memory: UserProfileMemory) async throws -> [AISuggestedFood] {
        var results = items
        let dictItems = items.map { ["name": $0.name] }
        let violations = FoodSafetyValidator.shared.validateFoodItems(dictItems, against: memory)
        
        if !violations.isEmpty {
            await MainActor.run { self.healthSafetyApplied = true }
            for violation in violations.reversed() {
                let originalItem = results[violation.index]
                results.remove(at: violation.index)
                
                let avoidFoodsStr = FoodSafetyValidator.shared.getAllAvoidFoods(for: memory).joined(separator: ", ")
                let reaskPrompt = """
                Thay thế món '\(originalItem.name)' bằng một món khác phù hợp.
                Yêu cầu:
                - Khoảng \(Int(originalItem.calories)) kcal
                - KHÔNG ĐƯỢC CHỨA: \(avoidFoodsStr)
                Trả về JSON duy nhất: {"action":"meal_plan","items":[{"name":"...","calories":...,"protein":...,"carbs":...,"fat":...,"servingSize":1.0,"mealType":"\(originalItem.mealType ?? "")"}]}
                """
                
                if let newFoods = try? await aiService.quickReaskForFood(prompt: reaskPrompt), let newFood = newFoods.first {
                    var nf = newFood
                    nf.mealType = Self.normalizeMealType(nf.mealType ?? originalItem.mealType ?? "Ăn vặt")
                    results.insert(nf, at: violation.index)
                }
            }
        }
        return results
    }
    
    func swapMeal(item: AISuggestedFood) async {
        guard let index = planItems.firstIndex(where: { $0.id == item.id }) else { return }
        
        do {
            let foodModel = item.toFoodItemModel()
            if let replacement = try await MagicSwapEngine.shared.swap(originalFood: foodModel) {
                await MainActor.run {
                    var newSuggested = AISuggestedFood(
                        name: replacement.name,
                        calories: replacement.calories,
                        protein: replacement.protein,
                        carbs: replacement.carbs,
                        fat: replacement.fat,
                        servingSize: replacement.servingSize,
                        mealType: item.mealType,
                        unit: replacement.unit,
                        weightInGrams: replacement.weightInGrams,
                        ingredients: replacement.ingredients?.map { IngredientDTO(name: $0.name, amount: $0.amount, unit: $0.unit, protein: $0.protein, carbs: $0.carbs, fat: $0.fat) },
                        instructions: replacement.instructions
                    )
                    self.planItems[index] = newSuggested
                    self.saveDraftPlan(targetCalories: 2000) // Saving draft with updated item, ideally we should pass actual target calories
                    HapticManager.interaction()
                }
            } else {
                // Fallback to AI re-ask if local swap fails
                let memory = try await AIMemoryRepository.shared.fetchMemory()
                let avoidFoodsStr = FoodSafetyValidator.shared.getAllAvoidFoods(for: memory).joined(separator: ", ")
                let reaskPrompt = """
                Thay thế món '\(item.name)' bằng một món khác phù hợp.
                Yêu cầu:
                - Khoảng \(Int(item.calories)) kcal
                - KHÔNG ĐƯỢC CHỨA: \(avoidFoodsStr)
                Trả về JSON duy nhất: {"action":"meal_plan","items":[{"name":"...","calories":...,"protein":...,"carbs":...,"fat":...,"servingSize":1.0,"mealType":"\(item.mealType ?? "")"}]}
                """
                
                if let newFoods = try? await aiService.quickReaskForFood(prompt: reaskPrompt, isInternal: true), let newFood = newFoods.first {
                    await MainActor.run {
                        var nf = newFood
                        nf.mealType = item.mealType
                        self.planItems[index] = nf
                        HapticManager.interaction()
                    }
                }
            }
        } catch {
            print("Swap failed: \(error)")
        }
    }
    
    // MARK: - Calorie Validation (Soft Constraints: ±15% tolerance)
    
    static func validateCalories(items: [AISuggestedFood], target: Double) -> [AISuggestedFood] {
        let total = items.reduce(0) { $0 + $1.calories }
        let upperBound = target * 1.15
        let lowerBound = target * 0.85
        
        // Only trim/scale if it's wildly off (outside ±15% tolerance)
        guard total > upperBound || total < lowerBound else { return items }
        
        // Proportional rescale — create new items with scaled values
        let ratio = target / total
        return items.map { item in
            var scaled = item
            scaled.calories = round(item.calories * ratio)
            scaled.protein = round(item.protein * ratio * 10) / 10
            scaled.carbs = round(item.carbs * ratio * 10) / 10
            scaled.fat = round(item.fat * ratio * 10) / 10
            return scaled
        }
    }
    
    // MARK: - MealType Normalizer (D-11: map AI variants to canonical Vietnamese)
    
    static func normalizeMealType(_ raw: String) -> String {
        let lower = raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        if lower.contains("sáng") || lower.contains("breakfast") || lower.contains("morning") {
            return "Bữa sáng"
        }
        if lower.contains("trưa") || lower.contains("lunch") || lower.contains("noon") {
            return "Bữa trưa"
        }
        if lower.contains("tối") || lower.contains("dinner") || lower.contains("evening") {
            return "Bữa tối"
        }
        if lower.contains("vặt") || lower.contains("snack") || lower.contains("phụ") {
            return "Ăn vặt"
        }
        
        return "Ăn vặt" // fallback
    }
    
    // MARK: - Interactive Plan Editing
    
    func addFoodToPlan(food: FoodItemModel, mealType: String) {
        let suggested = AISuggestedFood(
            name: food.name,
            calories: food.calories,
            protein: food.protein,
            carbs: food.carbs,
            fat: food.fat,
            servingSize: food.servingSize,
            mealType: mealType,
            unit: food.unit,
            weightInGrams: food.weightInGrams,
            ingredients: food.ingredients?.map { IngredientDTO(name: $0.name, amount: $0.amount, unit: $0.unit) },
            instructions: food.instructions
        )
        planItems.append(suggested)
        HapticManager.interaction()
    }
    
    func removeFoodFromPlan(id: UUID) {
        planItems.removeAll { $0.id == id }
        HapticManager.interaction()
    }
    
    // MARK: - Grouped items by meal type
    
    func items(for mealType: String) -> [AISuggestedFood] {
        planItems.filter { ($0.mealType ?? "Ăn vặt") == mealType }
    }
    
    func totalCalories(for mealType: String) -> Double {
        items(for: mealType).reduce(0) { $0 + $1.calories }
    }
    
    var totalPlanCalories: Double {
        planItems.reduce(0) { $0 + $1.calories }
    }
    
    var allMealsConfirmed: Bool {
        dailyPlanStatus == "confirmed"
    }
    
    // MARK: - Log Actions (D-06: per-meal + bulk, D-07: source = "AI Meal Plan")
    
    func logSingleFood(_ food: FoodItemModel, type: String, date: Date) async {
        do {
            let mealFood = MealFoodModel(
                quantity: food.servingSize,
                caloriesSnapshot: food.calories,
                proteinSnapshot: food.protein,
                carbsSnapshot: food.carbs,
                fatSnapshot: food.fat,
                isEaten: true,
                mealType: type,
                foodItem: food
            )
            
            let meal = MealModel(
                date: date,
                mealType: type,
                mealFoods: [mealFood]
            )
            
            try await mealRepository.saveMeal(meal, for: date)
            _ = await loadExistingPlan(for: date)
            HapticManager.success()
        } catch {
            print("Error logging single food: \(error)")
        }
    }
    
    
    func confirmDailyPlan() async {
        guard let currentPlan = self.dailyRecord?.dailyPlan else { return }
        
        do {
            try await dailyPlanRepository.savePlan(currentPlan, status: "confirmed")
            
            await MainActor.run {
                self.dailyPlanStatus = "confirmed"
                HapticManager.success()
                NotificationCenter.default.post(name: NSNotification.Name("dailyPlanDidConfirm"), object: nil)
            }
            
            // Refresh view
            await loadExistingPlan()
        } catch {
            print("❌ Failed to confirm daily plan: \(error)")
        }
    }
    
    // MARK: - Smart Daily Journal Actions
    
    @MainActor
    private func updatePendingLinks(actualMeals: [MealModel], dailyPlan: DailyPlanModel) {
        let unlinkedMeals = actualMeals.filter { $0.linkedPlannedMealId == nil }
        var newPending: [LinkCandidate] = []
        
        for meal in unlinkedMeals {
            let candidates = MealPlanLinkingService.shared.findCandidateLinks(for: meal, in: dailyPlan)
            if let best = candidates.first, best.confidence >= 0.4 {
                newPending.append(best)
            }
        }
        self.pendingLinks = newPending
    }
    
    func markPlannedMealAsEaten(plannedMeal: PlannedMealModel) async {
        do {
            // 1. Create Actual Meal Log from Planned Meal
            let foodModels = plannedMeal.foodItems.map { food -> MealFoodModel in
                var foodItem = FoodItemModel(
                    id: food.id,
                    name: food.name,
                    calories: food.calories,
                    protein: food.protein,
                    carbs: food.carbs,
                    fat: food.fat,
                    servingSize: food.servingSize,
                    source: "AI Meal Plan"
                )
                return MealFoodModel(
                    quantity: 1.0,
                    caloriesSnapshot: food.calories,
                    proteinSnapshot: food.protein,
                    carbsSnapshot: food.carbs,
                    fatSnapshot: food.fat,
                    isEaten: true,
                    mealType: plannedMeal.type,
                    foodItem: foodItem
                )
            }
            
            let mealLog = MealModel(
                date: selectedDate,
                mealType: plannedMeal.type,
                source: "plannedMeal",
                linkedPlannedMealId: plannedMeal.id,
                mealFoods: foodModels
            )
            
            // 2. Save Actual Meal
            try await mealRepository.saveMeal(mealLog, for: selectedDate)
            
            // 3. Update Planned Meal Status
            if var dailyPlan = try await dailyPlanRepository.fetchPlan(for: selectedDate) {
                if let index = dailyPlan.plannedMeals.firstIndex(where: { $0.id == plannedMeal.id }) {
                    dailyPlan.plannedMeals[index].status = "eaten"
                    dailyPlan.plannedMeals[index].actualMealLogId = mealLog.id
                    dailyPlan.plannedMeals[index].eatenAt = Date()
                    try await dailyPlanRepository.savePlan(dailyPlan, status: dailyPlan.status)
                }
            }
            
            // 4. Reload data
            _ = await loadExistingPlan()
            HapticManager.success()
            
        } catch {
            print("Error marking meal as eaten: \(error)")
        }
    }
    
    func skipPlannedMeal(plannedMeal: PlannedMealModel) async {
        do {
            if var dailyPlan = try await dailyPlanRepository.fetchPlan(for: selectedDate) {
                if let index = dailyPlan.plannedMeals.firstIndex(where: { $0.id == plannedMeal.id }) {
                    dailyPlan.plannedMeals[index].status = "skipped"
                    try await dailyPlanRepository.savePlan(dailyPlan, status: dailyPlan.status)
                    _ = await loadExistingPlan()
                    HapticManager.interaction()
                }
            }
        } catch {
            print("Error skipping meal: \(error)")
        }
    }
    
    func linkMealToPlan(meal: MealModel, plannedMealId: UUID) async {
        do {
            // 1. Update Meal Log with link
            var updatedMeal = meal
            updatedMeal.linkedPlannedMealId = plannedMealId
            try await mealRepository.saveMeal(updatedMeal, for: selectedDate)
            
            // 2. Update Planned Meal status
            if var dailyPlan = try await dailyPlanRepository.fetchPlan(for: selectedDate) {
                if let index = dailyPlan.plannedMeals.firstIndex(where: { $0.id == plannedMealId }) {
                    dailyPlan.plannedMeals[index].status = "eaten"
                    dailyPlan.plannedMeals[index].actualMealLogId = meal.id
                    dailyPlan.plannedMeals[index].eatenAt = Date()
                    try await dailyPlanRepository.savePlan(dailyPlan, status: dailyPlan.status)
                }
            }
            
            _ = await loadExistingPlan()
            HapticManager.success()
        } catch {
            print("Error linking meal: \(error)")
        }
    }
    
    func toggleLockMeal(id: UUID, locked: Bool) async {
        do {
            try await dailyPlanRepository.lockMeal(id: id, locked: locked)
            _ = await loadExistingPlan()
        } catch {
            print("Error locking meal: \(error)")
        }
    }
    
    // MARK: - Weekly Plan (D-01, D-05: compact 7-row overview)
    
    func generateWeekPlan(targetCalories: Double) {
        guard !isLoadingWeekly else { return }
        
        weeklyGenerationTask?.cancel()
        weeklyGenerationTask = Task {
            await MainActor.run {
                self.isLoadingWeekly = true
                self.weeklyPlan = []
                self.weeklyErrorMessage = nil
                self.datesToGenerate = []
            }
            
            do {
                let userContext = try await contextBuilder.buildFullUserContext()
                
                // ⚡ Smart Fill Logic (Phase 26 Refinement)
                // 1. Determine anchor date (selectedDate or Today)
                let calendar = Calendar.current
                let anchorDate = calendar.startOfDay(for: selectedDate)
                
                // 2. Find next 7 dates that don't have a plan
                var dates: [Date] = []
                var cursor = anchorDate
                while dates.count < 7 {
                    if try await dailyPlanRepository.fetchPlan(for: cursor) == nil {
                        dates.append(cursor)
                    }
                    cursor = calendar.date(byAdding: .day, value: 1, to: cursor)!
                }
                
                await MainActor.run { self.datesToGenerate = dates }
                
                // 3. Generate via AI for these specific dates
                let plans = try await AIOrchestrator.shared.generateWeekPlanBatched(userContext: userContext, dates: dates)
                
                await MainActor.run {
                    self.weeklyPlan = plans
                    self.isLoadingWeekly = false
                }
            } catch {
                print("generateWeekPlan error: \(error)")
                await MainActor.run {
                    self.weeklyErrorMessage = "Lỗi tạo kế hoạch tuần: \(error.localizedDescription)"
                    self.isLoadingWeekly = false
                }
            }
        }
    }
    
    func confirmWeeklyPlan(targetCalories: Double) {
        guard !weeklyPlan.isEmpty else { return }
        
        Task {
            for dayPlan in weeklyPlan {
                guard let date = dayPlan.date else { continue }
                
                let plan = DailyPlanModel(
                    date: date,
                    status: "confirmed",
                    targetCalories: targetCalories,
                    targetProtein: targetCalories * 0.3 / 4,
                    targetCarbs: targetCalories * 0.4 / 4,
                    targetFat: targetCalories * 0.3 / 9,
                    plannedMeals: dayPlan.items.map { item in
                        PlannedMealModel(
                            type: item.mealType ?? "Ăn vặt",
                            foodItems: [item.toPlannedFoodItemModel()]
                        )
                    }
                )
                try? await dailyPlanRepository.savePlan(plan, status: "confirmed")
            }
            
            await MainActor.run {
                HapticManager.success()
                // Clear state after confirmation
                self.weeklyPlan = []
            }
        }
    }
    
    static func parseSingleDayPlan(_ text: String, dayName: String) -> WeeklyDayPlan? {
        var jsonText = text
        if let firstBracket = jsonText.firstIndex(of: "{"),
           let lastBracket = jsonText.lastIndex(of: "}") {
            jsonText = String(jsonText[firstBracket...lastBracket])
        }
        
        guard let data = jsonText.data(using: .utf8) else { return nil }
        
        do {
            let plan = try JSONDecoder().decode(WeeklyDayPlan.self, from: data)
            return WeeklyDayPlan(
                day: dayName,
                breakfast: plan.breakfast,
                lunch: plan.lunch,
                dinner: plan.dinner,
                snack: plan.snack
            )
        } catch {
            print("Single day parse error: \(error)")
            return nil
        }
    }
    
    func reset() {
        self.planItems = []
        self.isLoading = false
        self.errorMessage = nil
        self.weeklyPlan = []
        self.isLoadingWeekly = false
        self.weeklyErrorMessage = nil
    }
    
    // MARK: - Weekly Plan Actions
    
    func swapWeeklyMeal(item: AISuggestedFood, day: String) async {
        guard let dayIndex = weeklyPlan.firstIndex(where: { $0.day == day }) else { return }
        
        do {
            let foodModel = item.toFoodItemModel()
            let replacement: FoodItemModel?
            
            if let magicReplacement = try await MagicSwapEngine.shared.swap(originalFood: foodModel) {
                replacement = magicReplacement
            } else {
                let memory = try await AIMemoryRepository.shared.fetchMemory()
                let avoidFoodsStr = FoodSafetyValidator.shared.getAllAvoidFoods(for: memory).joined(separator: ", ")
                let reaskPrompt = """
                Thay thế món '\(item.name)' bằng một món khác phù hợp.
                Yêu cầu:
                - Khoảng \(Int(item.calories)) kcal
                - KHÔNG ĐƯỢC CHỨA: \(avoidFoodsStr)
                Trả về JSON duy nhất: {"action":"meal_plan","items":[{"name":"...","calories":...,"protein":...,"carbs":...,"fat":...,"servingSize":1.0,"mealType":"\(item.mealType ?? "")"}]}
                """
                
                if let newFoods = try? await aiService.quickReaskForFood(prompt: reaskPrompt, isInternal: true) {
                    replacement = newFoods.first?.toFoodItemModel()
                } else {
                    replacement = nil
                }
            }
            
            if let rep = replacement {
                await MainActor.run {
                    let newSuggested = AISuggestedFood(
                        name: rep.name,
                        calories: rep.calories,
                        protein: rep.protein,
                        carbs: rep.carbs,
                        fat: rep.fat,
                        servingSize: rep.servingSize,
                        mealType: item.mealType,
                        unit: rep.unit,
                        weightInGrams: rep.weightInGrams,
                        ingredients: rep.ingredients?.map { IngredientDTO(name: $0.name, amount: $0.amount, unit: $0.unit) },
                        instructions: rep.instructions
                    )
                    
                    var updatedDay = weeklyPlan[dayIndex]
                    let mealType = item.mealType ?? "Ăn vặt"
                    
                    if mealType == "Bữa sáng" { updatedDay.breakfast = newSuggested }
                    else if mealType == "Bữa trưa" { updatedDay.lunch = newSuggested }
                    else if mealType == "Bữa tối" { updatedDay.dinner = newSuggested }
                    else { updatedDay.snack = newSuggested }
                    
                    self.weeklyPlan[dayIndex] = updatedDay
                    HapticManager.interaction()
                }
            }
        } catch {
            print("Weekly swap failed: \(error)")
        }
    }
    
    func removeFoodFromWeeklyPlan(id: UUID, day: String) {
        guard let dayIndex = weeklyPlan.firstIndex(where: { $0.day == day }) else { return }
        
        var updatedDay = weeklyPlan[dayIndex]
        if updatedDay.breakfast?.id == id { updatedDay.breakfast = nil }
        else if updatedDay.lunch?.id == id { updatedDay.lunch = nil }
        else if updatedDay.dinner?.id == id { updatedDay.dinner = nil }
        else if updatedDay.snack?.id == id { updatedDay.snack = nil }
        
        weeklyPlan[dayIndex] = updatedDay
        HapticManager.interaction()
    }
}

// MARK: - Weekly Plan Model

struct WeeklyDayPlan: Identifiable, Codable {
    var id = UUID()
    let day: String
    var date: Date? // ⚡ Added real date reference
    var breakfast: AISuggestedFood?
    var lunch: AISuggestedFood?
    var dinner: AISuggestedFood?
    var snack: AISuggestedFood?
    
    var items: [AISuggestedFood] {
        var results: [AISuggestedFood] = []
        if var b = breakfast { b.mealType = "Bữa sáng"; results.append(b) }
        if var l = lunch { l.mealType = "Bữa trưa"; results.append(l) }
        if var d = dinner { d.mealType = "Bữa tối"; results.append(d) }
        if var s = snack { s.mealType = "Ăn vặt"; results.append(s) }
        return results
    }
    
    var totalCalories: Double {
        items.reduce(0) { $0 + $1.calories }
    }
    
    var timelineItems: [TimelineItem] {
        MealPlanViewModel.mealTypes.compactMap { type in
            let food: AISuggestedFood?
            switch type {
            case "Bữa sáng": food = breakfast
            case "Bữa trưa": food = lunch
            case "Bữa tối": food = dinner
            default: food = snack
            }
            
            guard let food = food else { return nil }
            
            // Wrap into PlannedMealModel
            let planned = PlannedMealModel(
                type: type,
                foodItems: [food.toPlannedFoodItemModel()]
            )
            
            return TimelineItem(type: type, planned: planned, actuals: [])
        }
    }
    
    var highlights: [String] {
        items.prefix(2).map { $0.name }
    }
    
    enum CodingKeys: String, CodingKey {
        case day, date, breakfast, lunch, dinner, snack
    }
}
