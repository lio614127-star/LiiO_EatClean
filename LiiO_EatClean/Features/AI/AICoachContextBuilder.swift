import Foundation

class AICoachContextBuilder {
    private let userRepository: UserRepositoryProtocol
    private let memoryRepository: MemoryRepositoryProtocol
    private let mealRepository: MealRepositoryProtocol
    private let dailyPlanRepository: DailyPlanRepositoryProtocol
    private let metabolicRepository: MetabolicRepositoryProtocol
    
    init(
        userRepository: UserRepositoryProtocol,
        memoryRepository: MemoryRepositoryProtocol,
        mealRepository: MealRepositoryProtocol,
        dailyPlanRepository: DailyPlanRepositoryProtocol,
        metabolicRepository: MetabolicRepositoryProtocol
    ) {
        self.userRepository = userRepository
        self.memoryRepository = memoryRepository
        self.mealRepository = mealRepository
        self.dailyPlanRepository = dailyPlanRepository
        self.metabolicRepository = metabolicRepository
    }
    
    // Inner enum for individual task returns within withThrowingTaskGroup
    private enum PartialContextResult {
        case success(ContextSection, (inout AICoachContextSnapshot) -> Void)
        case failure(ContextSection, MissingDataReason)
    }
    
    /// Builds a rich context snapshot with robust timeout safety and dynamic parallel loading.
    func buildSnapshot(
        for date: Date = Date(),
        mode: AICoachContextMode = .chat,
        intents: Set<ContextIntent> = [.generalChat],
        currentTab: String? = nil
    ) async -> AICoachContextSnapshot {
        let startTime = Date()
        let timeoutLimit: TimeInterval = (mode == .voice) ? 1.2 : 3.0
        
        // Resolve required sections via the intent classifier
        let requiredSections = AICoachIntentDetector.shared.mapIntentsToSections(intents)
        
        print("[AICoachContext] ⚡ Parallel load [\(mode)] (\(intents.count) intents -> \(requiredSections.count) sections) in \(timeoutLimit)s")
        
        var snapshot = AICoachContextSnapshot(currentDate: date, activeIntent: intents.first ?? .generalChat)
        snapshot.contextMode = mode
        snapshot.activeIntents = intents
        snapshot.includedSections = requiredSections
        
        do {
            snapshot = try await withThrowingTaskGroup(of: PartialContextResult.self) { group in
                // 1. Timeout watchdog task
                group.addTask {
                    try await Task.sleep(nanoseconds: UInt64(timeoutLimit * 1_000_000_000))
                    throw NSError(domain: "AICoachContext", code: 408, userInfo: [NSLocalizedDescriptionKey: "Timeout building rich context."])
                }
                
                // 2. Spawning specific section loaders in parallel
                for section in requiredSections {
                    group.addTask {
                        return await self.fetchSectionData(section, date: date)
                    }
                }
                
                var mutableSnapshot = snapshot
                var completedSections = Set<ContextSection>()
                
                // 3. Collect results as they complete
                while let result = try await group.next() {
                    switch result {
                    case .success(let section, let updateFn):
                        updateFn(&mutableSnapshot)
                        completedSections.insert(section)
                    case .failure(let section, let reason):
                        mutableSnapshot.missingReasons[section] = reason
                    }
                    
                    // If everything is satisfied, terminate wait loop early (avoiding waiting for the timeout sleep task)
                    if completedSections.count == requiredSections.count {
                        break
                    }
                }
                
                // Cancel standard timer wait
                group.cancelAll()
                
                mutableSnapshot.contextQuality = (completedSections.count == requiredSections.count) ? .full : .partial
                return mutableSnapshot
            }
        } catch {
            // Hit 408 timeout limit
            print("[AICoachContext] ⏳ Adaptive Timeout hit at \(timeoutLimit)s limit! Triggering fallback cache recovery.")
            snapshot.timedOut = true
            snapshot.contextQuality = .fallback
            
            // Assign .timedOut status to sections that failed to complete inside the task group before cancel
            for s in requiredSections {
                // If not marked complete or already failed, assign timedOut
                if snapshot.missingReasons[s] == nil {
                    // Check if properties are null
                    if isSectionMissing(s, in: snapshot) {
                        snapshot.missingReasons[s] = .timedOut
                    }
                }
            }
            
            // Pull surviving cache buckets for emergency recovery
            self.enrichWithCacheData(&snapshot)
        }
        
        // Calculate derived fields (Nutrition balances, totals)
        self.calculateDerivedSnapshotFields(&snapshot)
        
        print("[AICoachContext] ✅ Complete in \(String(format: "%.3fs", Date().timeIntervalSince(startTime))) Quality=\(snapshot.contextQuality) TimedOut=\(snapshot.timedOut)")
        return snapshot
    }
    
    // MARK: - Parallel Task Dispatcher
    
    private func fetchSectionData(_ section: ContextSection, date: Date) async -> PartialContextResult {
        switch section {
        case .profileMinimal, .healthConstraints, .todayTargets, .cookingPreferences:
            if let cached = AICoachContextCache.shared.getProfile() {
                return .success(section) { $0.profile = cached }
            }
            do {
                let prof = try await loadProfileSummary()
                if let p = prof {
                    AICoachContextCache.shared.profileCache = AICoachContextCache.CacheEntry(data: p, timestamp: Date())
                    return .success(section) { $0.profile = p }
                }
                return .failure(section, .notProvidedByUser)
            } catch {
                return .failure(section, .permissionOrStorageError)
            }
            
        case .todayMealLogs, .plannedVsActual:
            if let cached = AICoachContextCache.shared.getTodayLogs() {
                return .success(section) { $0.todayActualMeals = cached }
            }
            do {
                let logs = try await loadActualMealLogs(for: date)
                AICoachContextCache.shared.todayMealLogsCache = AICoachContextCache.CacheEntry(data: logs, timestamp: Date())
                return .success(section) { $0.todayActualMeals = logs }
            } catch {
                return .failure(section, .unavailable)
            }
            
        case .todayDailyPlan:
            // 30s quick TTL for matching plan changes
            if let cacheEntry = AICoachContextCache.shared.todayPlanCache, Date().timeIntervalSince(cacheEntry.timestamp) < 30 {
                if let inner = cacheEntry.data {
                    return .success(section) { $0.todayPlan = inner }
                } else {
                    return .failure(section, .notCreatedYet)
                }
            }
            do {
                let plan = try await loadDailyPlan(for: date)
                AICoachContextCache.shared.todayPlanCache = AICoachContextCache.CacheEntry(data: plan, timestamp: Date())
                if let p = plan {
                    return .success(section) { $0.todayPlan = p }
                } else {
                    return .failure(section, .notCreatedYet)
                }
            } catch {
                return .failure(section, .permissionOrStorageError)
            }
            
        case .weeklyPlans:
            do {
                let weekly = try await loadWeeklyStatus(for: date)
                return .success(section) { $0.weeklyPlanPresence = weekly }
            } catch {
                return .failure(section, .unavailable)
            }
            
        case .recentMealsSummary:
            do {
                let history = try await loadHistorySummary(for: date)
                return .success(section) { $0.past3DaysActualSummary = history }
            } catch {
                return .failure(section, .unavailable)
            }
            
        case .metabolicSummary:
            if let cached = AICoachContextCache.shared.getMetabolic() {
                return .success(section) { $0.metabolicOS = cached }
            }
            do {
                let meta = try await loadMetabolicSummary()
                if let m = meta {
                    AICoachContextCache.shared.metabolicCache = AICoachContextCache.CacheEntry(data: m, timestamp: Date())
                    return .success(section) { $0.metabolicOS = m }
                }
                return .failure(section, .notCreatedYet)
            } catch {
                return .failure(section, .unavailable)
            }
            
        case .progressTrend, .weightTrend, .adherenceSummary:
            do {
                let prog = try await loadProgressSummary()
                if let p = prog {
                    return .success(section) { $0.past7DaysAggregate = p }
                }
                return .failure(section, .notCreatedYet)
            } catch {
                return .failure(section, .unavailable)
            }
        }
    }
    
    // MARK: - Granular Task Loaders
    
    private func loadProfileSummary() async throws -> AICoachContextSnapshot.ProfileSummary? {
        let memory = try? await memoryRepository.fetchMemory()
        let latestGoal = try? await metabolicRepository.fetchLatestGoal()
        
        guard let user = try await userRepository.fetchUser() else { return nil }
        
        return AICoachContextSnapshot.ProfileSummary(
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
    
    private func loadActualMealLogs(for date: Date) async throws -> [AICoachContextSnapshot.ActualMealLog] {
        let fetchedMeals = (try? await mealRepository.fetchMeals(by: date)) ?? []
        return fetchedMeals.map { meal in
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
    }
    
    private func loadDailyPlan(for date: Date) async throws -> AICoachContextSnapshot.DailyPlanSummary? {
        guard let plan = try await dailyPlanRepository.fetchPlan(for: date) else { return nil }
        
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
        return AICoachContextSnapshot.DailyPlanSummary(
            date: plan.date,
            status: plan.status,
            plannedMeals: plannedDetails
        )
    }
    
    private func loadWeeklyStatus(for date: Date) async throws -> [String: Bool] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date) ?? date
        let startDate = calendar.date(byAdding: .day, value: -6, to: startOfDay) ?? startOfDay
        
        var weeklyStatus: [String: Bool] = [:]
        let weekPlans = try await dailyPlanRepository.fetchPlans(from: startDate, to: endOfDay)
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        for plan in weekPlans {
            weeklyStatus[df.string(from: plan.date)] = true
        }
        return weeklyStatus
    }
    
    private func loadHistorySummary(for date: Date) async throws -> String {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let historyStart = calendar.date(byAdding: .day, value: -3, to: startOfDay) ?? startOfDay
        let historyEnd = calendar.date(byAdding: .second, value: -1, to: startOfDay) ?? startOfDay
        
        let pastMeals = try await mealRepository.fetchMeals(from: historyStart, to: historyEnd)
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
        
        return summaryLines.isEmpty ? "  - *Không có lịch sử ghi nhận.*" : summaryLines.joined(separator: "\n")
    }
    
    private func loadMetabolicSummary() async throws -> AICoachContextSnapshot.MetabolicSummary? {
        guard let p = try await metabolicRepository.fetchMetabolicProfile() else { return nil }
        return AICoachContextSnapshot.MetabolicSummary(
            currentTDEE: p.estimatedTDEE,
            adaptiveTDEE: p.adaptiveTDEE,
            isMetabolismAdapting: abs(p.estimatedTDEE - p.adaptiveTDEE) > 50.0
        )
    }
    
    private func loadProgressSummary() async throws -> AICoachContextSnapshot.ProgressSummary? {
        guard let g = try await metabolicRepository.fetchLatestGoal() else { return nil }
        return AICoachContextSnapshot.ProgressSummary(
            latestWeight: g.weight,
            latestWeightDate: g.createdAt,
            avgCalories7Days: g.estimatedTDEE,
            weeklyAdherenceRate: g.adherenceScore * 100.0,
            recentAdherenceStatus: g.adherenceScore >= 0.85 ? "Xuất sắc" : (g.adherenceScore >= 0.7 ? "Tốt" : "Cần cố gắng")
        )
    }
    
    // MARK: - Fallback & Cache Restoration Helpers
    
    private func isSectionMissing(_ section: ContextSection, in snapshot: AICoachContextSnapshot) -> Bool {
        switch section {
        case .profileMinimal, .healthConstraints, .todayTargets, .cookingPreferences:
            return snapshot.profile == nil
        case .todayMealLogs, .plannedVsActual:
            return snapshot.todayActualMeals.isEmpty
        case .todayDailyPlan:
            return snapshot.todayPlan == nil
        case .weeklyPlans:
            return snapshot.weeklyPlanPresence.isEmpty
        case .recentMealsSummary:
            return snapshot.past3DaysActualSummary == nil
        case .metabolicSummary:
            return snapshot.metabolicOS == nil
        case .progressTrend, .weightTrend, .adherenceSummary:
            return snapshot.past7DaysAggregate == nil
        }
    }
    
    private func enrichWithCacheData(_ snapshot: inout AICoachContextSnapshot) {
        if snapshot.profile == nil, let cached = AICoachContextCache.shared.profileCache?.data {
            snapshot.profile = cached
            snapshot.missingReasons[.profileMinimal] = nil
        }
        if snapshot.todayActualMeals.isEmpty, let cached = AICoachContextCache.shared.todayMealLogsCache?.data {
            snapshot.todayActualMeals = cached
            snapshot.missingReasons[.todayMealLogs] = nil
        }
        if snapshot.todayPlan == nil, let cached = AICoachContextCache.shared.todayPlanCache?.data {
            snapshot.todayPlan = cached
            snapshot.missingReasons[.todayDailyPlan] = nil
        }
        if snapshot.metabolicOS == nil, let cached = AICoachContextCache.shared.metabolicCache?.data {
            snapshot.metabolicOS = cached
            snapshot.missingReasons[.metabolicSummary] = nil
        }
    }
    
    private func calculateDerivedSnapshotFields(_ snapshot: inout AICoachContextSnapshot) {
        if snapshot.todayNutrition == nil, let prof = snapshot.profile {
            let consumedCal = snapshot.todayActualMeals.reduce(0) { $0 + $1.calories }
            let consumedPro = snapshot.todayActualMeals.reduce(0) { $0 + $1.protein }
            let consumedCar = snapshot.todayActualMeals.reduce(0) { $0 + $1.carbs }
            let consumedFat = snapshot.todayActualMeals.reduce(0) { $0 + $1.fat }
            
            snapshot.todayNutrition = AICoachContextSnapshot.NutritionBalance(
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
    }
}
