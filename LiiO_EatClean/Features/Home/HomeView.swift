import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    
    // Add Meal Sheet State
    @State private var activeAddMealType: MealSheetItem?
    
    // Meal Detail Sheet
    @State private var activeDetailMealType: MealSheetItem?
    
    @Environment(GlobalVoiceAssistantManager.self) var voiceManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    GeometryReader { geometry in
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 24) {
                                // Header
                                headerSection
                                
                                // Progress Ring
                                CalorieRingView(
                                    consumed: viewModel.totalCalories,
                                    target: viewModel.dailyTarget
                                )
                                .frame(width: 240, height: 240)
                                .animation(.easeInOut(duration: 0.6), value: viewModel.totalCalories)
                                
                                // Macro Bars
                                macroBarsSection
                                
                                if let insight = viewModel.coachingInsight {
                                    AICoachingCardView(insight: insight, onApply: { proposal in
                                        Task { await viewModel.applyGoalAdjustment(proposal) }
                                    })
                                    .padding(.horizontal, 24)
                                }
                                
                                if let streak = viewModel.streak {
                                    StreakCardView(streak: streak, onTap: { })
                                        .padding(.horizontal, 24)
                                }
                                
                                // ⚡ Phase 28: Proactive AI Rebalance Card
                                if let trigger = viewModel.rebalanceTrigger {
                                    RebalanceSuggestionCard(trigger: trigger) {
                                        Task { await viewModel.startRebalance() }
                                    }
                                    .padding(.horizontal, 24)
                                }
                                
                                // Proactive AI Daily Summary
                                if viewModel.dailySummary != nil || !viewModel.todayMeals.isEmpty {
                                    DailySummaryCardView(
                                        summary: viewModel.dailySummary,
                                        isLoading: viewModel.summaryService.isLoading
                                    )
                                    .padding(.horizontal, 24)
                                }
                                
                                // Water Card
                                WaterCardView(
                                    consumed: viewModel.waterConsumed,
                                    target: viewModel.waterTarget,
                                    onAdd: { amount in Task { await viewModel.addWater(amount: amount) } },
                                    onReset: { Task { await viewModel.resetWater() } }
                                )
                                .padding(.horizontal, 24)
                                
                                // Planned Meals Section
                                if !viewModel.dashboard.pendingPlannedMeals.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Kế hoạch hôm nay").font(.headline).padding(.horizontal, 24)
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 16) {
                                                ForEach(viewModel.dashboard.pendingPlannedMeals) { plannedMeal in
                                                    PendingPlannedMealCard(
                                                        plannedMeal: plannedMeal,
                                                        onMarkAsEaten: { Task { await viewModel.markAsEaten(plannedMeal: plannedMeal) } },
                                                        onSkip: { Task { await viewModel.skipPlannedMeal(plannedMeal: plannedMeal) } },
                                                        onReplace: { HapticManager.warning() }
                                                    )
                                                    .frame(width: 300)
                                                }
                                            }
                                            .padding(.horizontal, 24)
                                        }
                                    }
                                }
                                
                                // Meal Cards
                                mealsSection
                                
                                // Add Meal Button
                                addMealButton.padding(.bottom, 24)
                            }
                            .padding(.vertical, 16)
                            .frame(width: geometry.size.width)
                        }
                        .refreshable { await viewModel.loadDashboard() }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $activeAddMealType, onDismiss: {
                Task { await viewModel.loadDashboard() }
            }) { item in
                AddMealView(selectedMealType: item.id).id(item.id)
            }
            .sheet(item: $activeDetailMealType) { item in
                MealCategorySummarySheet(
                    mealType: item.id,
                    initialMeals: viewModel.meals(for: item.id),
                    onUpdate: { Task { await viewModel.loadDashboard() } }
                )
                .id(item.id + "-\(viewModel.todayMeals.flatMap { $0.mealFoods }.count)")
            }
            .sheet(item: Binding(
                get: { viewModel.rebalanceResult.map { IdentifiableResult(result: $0) } },
                set: { _ in viewModel.rebalanceResult = nil }
            )) { identifiable in
                RebalancePreviewSheet(
                    result: identifiable.result,
                    onConfirm: { Task { await viewModel.confirmRebalance() } },
                    onCancel: { viewModel.rebalanceResult = nil }
                )
            }
            .overlay {
                if viewModel.showMilestonePopup {
                    MilestonePopupView(milestone: viewModel.milestoneValue, isPresented: $viewModel.showMilestonePopup)
                }
            }
            .overlay {
                if viewModel.isRebalancing {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView().scaleEffect(1.5).tint(.white)
                            Text("AI đang cân đối lại thực đơn...").foregroundColor(.white).font(.system(size: 16, weight: .bold))
                        }
                    }
                }
            }
            .onAppear {
                Task { await viewModel.loadDashboard() }
            }
            .alert("Thông báo", isPresented: Binding(
                get: { viewModel.rebalanceError != nil },
                set: { if !$0 { viewModel.rebalanceError = nil } }
            )) {
                Button("Đồng ý", role: .cancel) { }
            } message: {
                if let error = viewModel.rebalanceError {
                    Text(error)
                }
            }
        }
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Xin chào, \(viewModel.user?.name.isEmpty == false ? viewModel.user!.name : "bạn")!")
                    .font(.title2.bold())
                
                if viewModel.dashboard.confirmedDailyPlan != nil {
                    Text("Còn \(Int(viewModel.dashboard.remainingPlannedCalories)) kcal theo plan")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                } else if viewModel.isOverTarget {
                    Text("Đã vượt \(Int(viewModel.totalCalories - viewModel.dailyTarget)) kcal hôm nay")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                } else {
                    Text("Còn \(Int(viewModel.remainingCalories)) kcal hôm nay")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: { voiceManager.startListening() }) {
                Image(systemName: "mic.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.green)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 24)
    }
    
    private var macroBarsSection: some View {
        VStack(spacing: 16) {
            MacroBarView(label: "Protein", consumed: viewModel.totalProtein, target: viewModel.proteinTarget, color: .blue)
            MacroBarView(label: "Carbs", consumed: viewModel.totalCarbs, target: viewModel.carbsTarget, color: .orange)
            MacroBarView(label: "Fat", consumed: viewModel.totalFat, target: viewModel.fatTarget, color: .pink)
        }
        .padding(.horizontal, 24)
    }
    
    private var mealsSection: some View {
        VStack(spacing: 16) {
            MealCardView(
                mealType: "Bữa sáng",
                icon: "sunrise.fill",
                meals: viewModel.meals(for: "Bữa sáng"),
                pendingLinkSuggestion: viewModel.pendingLinkSuggestions["Bữa sáng"],
                onAddTapped: { showAddMealSheet(for: "Bữa sáng") },
                onRowTapped: { showMealDetailSheet(for: "Bữa sáng") },
                onDelete: deleteMealFood,
                onToggleEaten: { id in Task { await viewModel.toggleMealFoodStatus(id: id) } },
                onLinkToPlan: { mealId in Task { await viewModel.linkMealToPlan(mealId: mealId) } }
            )
            
            MealCardView(
                mealType: "Bữa trưa",
                icon: "sun.max.fill",
                meals: viewModel.meals(for: "Bữa trưa"),
                pendingLinkSuggestion: viewModel.pendingLinkSuggestions["Bữa trưa"],
                onAddTapped: { showAddMealSheet(for: "Bữa trưa") },
                onRowTapped: { showMealDetailSheet(for: "Bữa trưa") },
                onDelete: deleteMealFood,
                onToggleEaten: { id in Task { await viewModel.toggleMealFoodStatus(id: id) } },
                onLinkToPlan: { mealId in Task { await viewModel.linkMealToPlan(mealId: mealId) } }
            )
            
            MealCardView(
                mealType: "Bữa tối",
                icon: "moon.fill",
                meals: viewModel.meals(for: "Bữa tối"),
                pendingLinkSuggestion: viewModel.pendingLinkSuggestions["Bữa tối"],
                onAddTapped: { showAddMealSheet(for: "Bữa tối") },
                onRowTapped: { showMealDetailSheet(for: "Bữa tối") },
                onDelete: deleteMealFood,
                onToggleEaten: { id in Task { await viewModel.toggleMealFoodStatus(id: id) } },
                onLinkToPlan: { mealId in Task { await viewModel.linkMealToPlan(mealId: mealId) } }
            )
            
            MealCardView(
                mealType: "Ăn vặt",
                icon: "leaf.fill",
                meals: viewModel.meals(for: "Ăn vặt"),
                pendingLinkSuggestion: viewModel.pendingLinkSuggestions["Ăn vặt"],
                onAddTapped: { showAddMealSheet(for: "Ăn vặt") },
                onRowTapped: { showMealDetailSheet(for: "Ăn vặt") },
                onDelete: deleteMealFood,
                onToggleEaten: { id in Task { await viewModel.toggleMealFoodStatus(id: id) } },
                onLinkToPlan: { mealId in Task { await viewModel.linkMealToPlan(mealId: mealId) } }
            )
        }
        .padding(.horizontal, 24)
    }
    
    private var addMealButton: some View {
        Button(action: {
            let hour = Calendar.current.component(.hour, from: Date())
            let currentType: String
            if hour < 10 { currentType = "Bữa sáng" }
            else if hour < 15 { currentType = "Bữa trưa" }
            else if hour < 20 { currentType = "Bữa tối" }
            else { currentType = "Ăn vặt" }
            
            showAddMealSheet(for: currentType)
        }) {
            HStack {
                Image(systemName: "plus")
                Text("Thêm bữa ăn")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .cornerRadius(14)
        }
        .padding(.horizontal, 24)
    }
    
    private func showAddMealSheet(for type: String) {
        activeAddMealType = MealSheetItem(id: type)
    }
    
    private func showMealDetailSheet(for type: String) {
        activeDetailMealType = MealSheetItem(id: type)
    }
    
    private func deleteMealFood(id: UUID) {
        Task {
            await viewModel.deleteMealFood(id: id)
        }
    }
}

#Preview {
    HomeView()
}

struct RebalanceSuggestionCard: View {
    let trigger: RebalanceTrigger
    let onAction: () -> Void
    
    var body: some View {
        Button(action: onAction) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(trigger.reason)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("AI có thể cân đối lại các bữa còn lại giúp bạn.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var iconName: String {
        switch trigger.type {
        case .overCalorie: return "flame.fill"
        case .underProtein: return "bolt.fill"
        case .lateNightUnderEating: return "moon.fill"
        default: return "sparkles"
        }
    }
    
    private var iconColor: Color {
        switch trigger.type {
        case .overCalorie: return .orange
        case .underProtein: return .blue
        case .lateNightUnderEating: return .purple
        default: return .mint
        }
    }
}
