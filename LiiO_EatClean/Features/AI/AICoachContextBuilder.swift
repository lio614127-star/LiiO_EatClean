import Foundation

class AICoachContextBuilder {
    private let userRepository: UserRepositoryProtocol
    private let mealRepository: MealRepositoryProtocol
    private let memoryRepository: AIMemoryRepositoryProtocol
    private let dailyPlanRepository: DailyPlanRepositoryProtocol
    private let metabolicRepository: MetabolicRepositoryProtocol
    
    init(
        userRepository: UserRepositoryProtocol = UserRepository(),
        mealRepository: MealRepositoryProtocol = MealRepository(),
        memoryRepository: AIMemoryRepositoryProtocol = AIMemoryRepository(),
        dailyPlanRepository: DailyPlanRepositoryProtocol = DailyPlanRepository(),
        metabolicRepository: MetabolicRepositoryProtocol = MetabolicRepository()
    ) {
        self.userRepository = userRepository
        self.mealRepository = mealRepository
        self.memoryRepository = memoryRepository
        self.dailyPlanRepository = dailyPlanRepository
        self.metabolicRepository = metabolicRepository
    }
    
    /// Builds a rich context snapshot with robust timeout safety and intent-based loading strategies.
    func buildSnapshot(
        for date: Date = Date(),
        mode: AICoachContextMode = .chat,
        intents: Set<ContextIntent> = [.generalChat],
        currentTab: String? = nil
    ) async -> AICoachContextSnapshot {
        let startTime = Date()
        let legacyIntent = intents.first ?? .generalChat
        print("[AICoachContext] 🛠️ Building unified context for intents=\(intents) (legacy=\(legacyIntent))...")
        
        do {
            // Create an overall timeout task for the aggregate loads (3 seconds max)
            return try await withThrowingTaskGroup(of: AICoachContextSnapshot.self) { group in
                group.addTask {
                    return try await self.loadDataSequentially(for: legacyIntent, date: date)
                }
                
                group.addTask {
                    try await Task.sleep(nanoseconds: 3_000_000_000) // 3.0s
                    throw NSError(domain: "AICoachContext", code: 408, userInfo: [NSLocalizedDescriptionKey: "Timeout building rich context."])
                }
                
                let firstResult = try await group.next()!
                group.cancelAll() // Cancel the remaining tasks
                
                print("[AICoachContext] ✅ Context built successfully in \(String(format: "%.3fs", Date().timeIntervalSince(startTime)))")
                return firstResult
            }
        } catch {
            print("[AICoachContext] ⚠️ Error or Timeout building rich context: \(error.localizedDescription). Reverting to minimal safe context.")
            return buildMinimalFallbackSnapshot(for: legacyIntent, date: date)
        }
    }
    
    // MARK: - Sequential (Parallelizable) Async Aggregation Loop
    
    private func loadDataSequentially(for intent: ContextIntent, date: Date) async throws -> AICoachContextSnapshot {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date) ?? date
        
        // Prepare variables
        var profileSummary: AICoachContextSnapshot.ProfileSummary?
        var nutrition: AICoachContextSnapshot.NutritionBalance?
        var actualMeals: [AICoachContextSnapshot.ActualMealLog] = []
        var planSummary: AICoachContextSnapshot.DailyPlanSummary?
        var weeklyStatus: [String: Bool] = [:]
        var historySummary: String?
        var progress: AICoachContextSnapshot.ProgressSummary?
        var metabolic: AICoachContextSnapshot.MetabolicSummary?
        
        // 1. Profile, Goal Targets & Memories
        let memory = (try? await memoryRepository.fetchMemory())
        let latestGoal = try? await metabolicRepository.fetchLatestGoal()
        
        if let user = try? await userRepository.fetchUser() {
            profileSummary = AICoachContextSnapshot.ProfileSummary(
                goalType: user.goalType,
                targetCalories: user.dailyCalorieTarget,
                proteinTarget: latestGoal?.proteinTarget ?? 0,
                carbsTarget: latestGoal?.carbTarget ?? 0,
                fatTarget: latestGoal?.fatTarget ?? 0,
                likes: memory?.likes ?? [],
                dislikes: memory?.dislikes ?? [],
                avoidFoods: memory?.avoidFoods ?? [],
                healthConditions: memory?.healthConditions.map { $0.name } ?? []
            )
        }
        
        // 2. Today's Actual Consumed (All Intents require today actual logs)
        let fetchedMeals = (try? await mealRepository.fetchMeals(by: date)) ?? []
        actualMeals = fetchedMeals.map { meal in
            let foodDescriptions = meal.mealFoods.map { food in
                let name = food.foodItem?.name ?? "Món ăn"
                return "\(name) (x\(String(format: "%.1f", food.quantity)))"
            }.joined(separator: ", ")
            
            let totalPro = meal.mealFoods.reduce(0) { $0 + $1.proteinSnapshot }
            let totalCar = meal.mealFoods.reduce(0) { $0 + $1.carbsSnapshot }
            let totalFat = meal.mealFoods.reduce(0) { $0 + $1.fatSnapshot }
            
            return AICoachContextSnapshot.ActualMealLog(
                id: meal.id,
                type: meal.mealType,
                time: meal.date,
                name: foodDescriptions.isEmpty ? meal.mealType : foodDescriptions,
                calories: meal.totalCalories,
                protein: totalPro,
                carbs: totalCar,
                fat: totalFat,
                isLinkedToPlan: meal.linkedPlannedMealId != nil
            )
        }
        
        // Calculate Actual Totals for today
        let consumedCal = actualMeals.reduce(0) { $0 + $1.calories }
        let consumedPro = actualMeals.reduce(0) { $0 + $1.protein }
        let consumedCar = actualMeals.reduce(0) { $0 + $1.carbs }
        let consumedFat = actualMeals.reduce(0) { $0 + $1.fat }
        
        if let prof = profileSummary {
            nutrition = AICoachContextSnapshot.NutritionBalance(
                consumedCalories: consumedCal,
                consumedProtein: consumedPro,
                consumedCarbs: consumedCar,
                consumedFat: consumedFat,
                targetCalories: prof.targetCalories,
                targetProtein: prof.proteinTarget,
                targetCarbs: prof.carbsTarget,
                targetFat: prof.fatTarget
            )
        }
        
        // 3. Today's Daily Plan (Important for meal logging, rebalance, daily planning, etc.)
        if let plan = try? await dailyPlanRepository.fetchPlan(for: date) {
            let plannedDetails = plan.plannedMeals.map { pm in
                let desc = pm.foodItems.isEmpty ? pm.type : pm.foodItems.map { "\($0.name) (x\(String(format: "%.1f", $0.servingSize)))" }.joined(separator: ", ")
                let calories = pm.foodItems.reduce(0.0) { $0 + $1.calories }
                return AICoachContextSnapshot.PlannedMealDetail(
                    id: pm.id,
                    type: pm.type,
                    status: pm.status,
                    description: desc,
                    expectedCalories: calories,
                    linkedActualMealLogId: pm.actualMealLogId
                )
            }
            planSummary = AICoachContextSnapshot.DailyPlanSummary(
                date: plan.date,
                status: plan.status,
                plannedMeals: plannedDetails
            )
        }
        
        // 4. Weekly coverage (Loaded only for Planning, Progress, General intents)
        if intent == .dailyPlanRequest || intent == .progressQuestion || intent == .generalChat {
            let startDate = calendar.date(byAdding: .day, value: -6, to: startOfDay) ?? startOfDay
            if let weekPlans = try? await dailyPlanRepository.fetchPlans(from: startDate, to: endOfDay) {
                let df = DateFormatter()
                df.dateFormat = "yyyy-MM-dd"
                for plan in weekPlans {
                    weeklyStatus[df.string(from: plan.date)] = true
                }
            }
            
            // Historical Meals (Last 3 days)
            let historyStart = calendar.date(byAdding: .day, value: -3, to: startOfDay) ?? startOfDay
            if let pastMeals = try? await mealRepository.fetchMeals(from: historyStart, to: calendar.date(byAdding: .second, value: -1, to: startOfDay) ?? startOfDay) {
                let grouped = Dictionary(grouping: pastMeals) { calendar.startOfDay(for: $0.date) }
                var summaryLines: [String] = []
                let dfShort = DateFormatter()
                dfShort.dateFormat = "dd/MM"
                
                for d in grouped.keys.sorted(by: >) {
                    let dateStr = dfShort.string(from: d)
                    let mealsForDay = grouped[d] ?? []
                    let cal = Int(mealsForDay.reduce(0) { $0 + $1.totalCalories })
                    let mealNames = mealsForDay.compactMap { $0.mealFoods.first?.foodItem?.name ?? $0.mealType }.prefix(3).joined(separator: ", ")
                    summaryLines.append("  + \(dateStr): \(cal) kcal [\(mealNames)...]")
                }
                
                if summaryLines.isEmpty {
                    historySummary = "  - *Không có lịch sử ghi nhận.*"
                } else {
                    historySummary = summaryLines.joined(separator: "\n")
                }
            }
        }
        
        // 5. Progress, Weights & Metabolic OS (Loaded only for progress & general)
        if intent == .progressQuestion || intent == .generalChat {
            let profile = try? await metabolicRepository.fetchMetabolicProfile()
            if let p = profile {
                metabolic = AICoachContextSnapshot.MetabolicSummary(
                    currentTDEE: p.estimatedTDEE,
                    adaptiveTDEE: p.adaptiveTDEE,
                    isMetabolismAdapting: abs(p.estimatedTDEE - p.adaptiveTDEE) > 50.0
                )
            }
            
            // Aggregated averages
            if let g = latestGoal {
                progress = AICoachContextSnapshot.ProgressSummary(
                    latestWeight: g.weight,
                    latestWeightDate: g.createdAt,
                    avgCalories7Days: g.estimatedTDEE, // placeholder from history if needed
                    weeklyAdherenceRate: g.adherenceScore * 100.0,
                    recentAdherenceStatus: g.adherenceScore >= 0.85 ? "Xuất sắc" : (g.adherenceScore >= 0.7 ? "Tốt" : "Cần cố gắng")
                )
            }
        }
        
        return AICoachContextSnapshot(
            currentDate: date,
            activeIntent: intent,
            profile: profileSummary,
            todayNutrition: nutrition,
            todayActualMeals: actualMeals,
            todayPlan: planSummary,
            weeklyPlanPresence: weeklyStatus,
            past3DaysActualSummary: historySummary,
            past7DaysAggregate: progress,
            metabolicOS: metabolic
        )
    }
    
    // MARK: - Fallback
    
    private func buildMinimalFallbackSnapshot(for intent: ContextIntent, date: Date) -> AICoachContextSnapshot {
        // Safely constructs a minimal model without making any heavy queries, avoiding infinite loop or crash.
        return AICoachContextSnapshot(
            currentDate: date,
            activeIntent: intent,
            profile: nil,
            todayNutrition: nil,
            todayActualMeals: [],
            todayPlan: nil,
            weeklyPlanPresence: [:],
            past3DaysActualSummary: "Chưa load kịp dữ liệu lịch sử do timeout.",
            past7DaysAggregate: nil,
            metabolicOS: nil
        )
    }
}
