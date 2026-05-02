import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    
    // Add Meal Sheet State
    @State private var isShowingAddMeal = false
    @State private var selectedMealTypeForAdd = "Bữa sáng"
    
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
                            
                            // Water Card (Daily Control Center)
                            WaterCardView(
                                consumed: viewModel.waterConsumed,
                                target: viewModel.waterTarget,
                                onAdd: { amount in
                                    Task {
                                        await viewModel.addWater(amount: amount)
                                    }
                                }
                            )
                            .padding(.horizontal, 24)
                            .animation(.easeInOut(duration: 0.4), value: viewModel.waterConsumed)
                            
                            // Meal Cards
                            mealsSection
                            
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
            .sheet(isPresented: $isShowingAddMeal, onDismiss: {
                Task {
                    await viewModel.loadDashboard()
                }
            }) {
                AddMealView(selectedMealType: selectedMealTypeForAdd)
            }
        }
        .task {
            await viewModel.loadDashboard()
        }
        .onAppear {
            Task {
                await viewModel.loadDashboard()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .center, spacing: 4) {
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
                onDelete: deleteMealFood
            )
            
            MealCardView(
                mealType: "Bữa trưa",
                icon: "sun.max.fill",
                meals: viewModel.meals(for: "Bữa trưa"),
                onAddTapped: { showAddMealSheet(for: "Bữa trưa") },
                onDelete: deleteMealFood
            )
            
            MealCardView(
                mealType: "Bữa tối",
                icon: "moon.fill",
                meals: viewModel.meals(for: "Bữa tối"),
                onAddTapped: { showAddMealSheet(for: "Bữa tối") },
                onDelete: deleteMealFood
            )
            
            MealCardView(
                mealType: "Ăn vặt",
                icon: "leaf.fill",
                meals: viewModel.meals(for: "Ăn vặt"),
                onAddTapped: { showAddMealSheet(for: "Ăn vặt") },
                onDelete: deleteMealFood
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
        selectedMealTypeForAdd = type
        isShowingAddMeal = true
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
