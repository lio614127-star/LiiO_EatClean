import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    
    // Add Meal Sheet State
    @State private var activeAddMealType: MealSheetItem?
    
    // Meal Detail Sheet
    @State private var activeDetailMealType: MealSheetItem?
    
    // Voice Input State
    @State private var showVoiceInput = false
    @State private var voiceParsedFoods: [AISuggestedFood] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header
                            headerSection
                            
                            // Progress Ring with sweep animation
                            CalorieRingView(
                                consumed: viewModel.totalCalories,
                                target: viewModel.dailyTarget
                            )
                            .frame(width: 240, height: 240)
                            .animation(.easeInOut(duration: 0.6), value: viewModel.totalCalories)
                            
                            // Macro Bars
                            macroBarsSection
                            
                            if let streak = viewModel.streak {
                                StreakCardView(streak: streak, onTap: { })
                                    .padding(.horizontal, 24)
                                    .transition(.asymmetric(insertion: .slide.combined(with: .opacity), removal: .opacity))
                            }
                            
                            // Proactive AI Daily Summary
                            if viewModel.dailySummary != nil || !viewModel.todayMeals.isEmpty {
                                DailySummaryCardView(summary: viewModel.dailySummary)
                                    .padding(.horizontal, 24)
                                    .transition(.asymmetric(insertion: .slide.combined(with: .opacity), removal: .opacity))
                            }
                            
                            // Water Card (Daily Control Center)
                            WaterCardView(
                                consumed: viewModel.waterConsumed,
                                target: viewModel.waterTarget,
                                onAdd: { amount in
                                    Task {
                                        await viewModel.addWater(amount: amount)
                                    }
                                },
                                onReset: {
                                    Task {
                                        await viewModel.resetWater()
                                    }
                                }
                            )
                            .padding(.horizontal, 24)
                            .animation(.easeInOut(duration: 0.4), value: viewModel.waterConsumed)
                            
                            // Meal Cards
                            mealsSection
                                .animation(.easeInOut(duration: 0.3), value: viewModel.todayMeals)
                            
                            // Add Meal Button (Fallback)
                            addMealButton
                                .padding(.bottom, 24)
                        }
                        .padding(.vertical, 16)
                    }
                    .refreshable {
                        await viewModel.loadDashboard()
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $activeAddMealType, onDismiss: {
                HapticManager.success()
                Task {
                    await viewModel.loadDashboard()
                }
            }) { item in
                AddMealView(selectedMealType: item.id)
            }
            .sheet(item: $activeDetailMealType) { item in
                MealDetailSheet(
                    mealType: item.id,
                    initialMeals: viewModel.meals(for: item.id),
                    onUpdate: {
                        Task { await viewModel.loadDashboard() }
                    }
                )
                .id(item.id + "-\(viewModel.todayMeals.flatMap { $0.mealFoods }.count)")
            }
            .overlay {
                if viewModel.showMilestonePopup {
                    MilestonePopupView(milestone: viewModel.milestoneValue, isPresented: $viewModel.showMilestonePopup)
                }
            }
            .sheet(isPresented: $showVoiceInput) {
                VoiceInputView(isPresented: $showVoiceInput) { foods in
                    // When voice confirmed, open AddMealView with pre-filled items
                    self.voiceParsedFoods = foods
                    // Default to Breakfast or current time appropriate meal
                    showAddMealSheet(for: "Bữa sáng") // TODO: could pass foods to AddMealView if we customize it
                }
            }
        }
        .task {
            print("🚀 HomeView: Loading dashboard data...")
            await viewModel.loadDashboard()
        }
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Xin chào, \(viewModel.user?.name.isEmpty == false ? viewModel.user!.name : "bạn")!")
                    .font(.title2.bold())
                
                if viewModel.isOverTarget {
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
            
            Button(action: { showVoiceInput = true }) {
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
                onAddTapped: { showAddMealSheet(for: "Bữa sáng") },
                onRowTapped: { showMealDetailSheet(for: "Bữa sáng") },
                onDelete: deleteMealFood,
                onToggleEaten: { id in Task { await viewModel.toggleMealFoodStatus(id: id) } }
            )
            
            MealCardView(
                mealType: "Bữa trưa",
                icon: "sun.max.fill",
                meals: viewModel.meals(for: "Bữa trưa"),
                onAddTapped: { showAddMealSheet(for: "Bữa trưa") },
                onRowTapped: { showMealDetailSheet(for: "Bữa trưa") },
                onDelete: deleteMealFood,
                onToggleEaten: { id in Task { await viewModel.toggleMealFoodStatus(id: id) } }
            )
            
            MealCardView(
                mealType: "Bữa tối",
                icon: "moon.fill",
                meals: viewModel.meals(for: "Bữa tối"),
                onAddTapped: { showAddMealSheet(for: "Bữa tối") },
                onRowTapped: { showMealDetailSheet(for: "Bữa tối") },
                onDelete: deleteMealFood,
                onToggleEaten: { id in Task { await viewModel.toggleMealFoodStatus(id: id) } }
            )
            
            MealCardView(
                mealType: "Ăn vặt",
                icon: "leaf.fill",
                meals: viewModel.meals(for: "Ăn vặt"),
                onAddTapped: { showAddMealSheet(for: "Ăn vặt") },
                onRowTapped: { showMealDetailSheet(for: "Ăn vặt") },
                onDelete: deleteMealFood,
                onToggleEaten: { id in Task { await viewModel.toggleMealFoodStatus(id: id) } }
            )
        }
        .padding(.horizontal, 24)
    }
    
    private var addMealButton: some View {
        Button(action: {
            showAddMealSheet(for: "Bữa sáng")
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
