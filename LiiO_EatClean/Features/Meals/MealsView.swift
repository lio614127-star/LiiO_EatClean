import SwiftUI

struct MealSheetItem: Identifiable, Equatable {
    let id: String
}

struct MealsView: View {
    @State private var viewModel = MealsViewModel()
    @State private var activeAddMealType: MealSheetItem?
    @State private var activeDetailMealType: MealSheetItem?
    @State private var showMealPlanSheet = false
    @State private var showWeeklyPlanSheet = false
    @State private var mealPlanViewModel = MealPlanViewModel()
    @State private var showMemoryHub = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.meals.isEmpty {
                    ProgressView()
                } else {
                    List {
                        // Header
                        VStack(spacing: 4) {
                            Text(Calendar.current.isDateInToday(viewModel.selectedDate) ? "Hôm nay" : viewModel.selectedDate.formatted(.dateTime.day().month().year()))
                                .font(.title2.bold())
                            Text("Còn \(Int(viewModel.remainingCalories)) kcal")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        
                        // Dual Meal Plan Buttons (D-03: entry point split)
                        HStack(spacing: 12) {
                            Button {
                                guard !showMealPlanSheet else { return }
                                showMealPlanSheet = true
                            } label: {
                                HStack {
                                    Image(systemName: "sparkles")
                                    Text("Kế hoạch ngày")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.green)
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                            
                            Button {
                                showWeeklyPlanSheet = true
                            } label: {
                                HStack {
                                    Image(systemName: "calendar")
                                    Text("Kế hoạch tuần")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.green)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.green.opacity(0.12))
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        
                        // Meal Sections
                        ForEach(["Bữa sáng", "Bữa trưa", "Bữa tối", "Ăn vặt"], id: \.self) { type in
                            mealSection(for: type)
                        }
                        
                    }
                    .listStyle(.insetGrouped)
                    .refreshable {
                        await viewModel.loadData()
                    }
                }
            }
            .navigationTitle("Meals")
            .navigationBarHidden(true)
            .sheet(item: $activeAddMealType, onDismiss: {
                Task { await viewModel.loadData() }
            }) { item in
                AddMealView(selectedMealType: item.id)
                    .id(item.id)
            }
            .sheet(item: $activeDetailMealType) { item in
                MealCategorySummarySheet(
                    mealType: item.id,
                    initialMeals: viewModel.meals(for: item.id),
                    onUpdate: {
                        Task { await viewModel.loadData() }
                    }
                )
                .id(item.id + "-\(viewModel.meals.flatMap { $0.mealFoods }.count)")
            }
            .fullScreenCover(isPresented: $showMealPlanSheet, onDismiss: {
                // ⚡ Delay refresh to avoid transition glitch with fullScreenCover
                Task {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    await viewModel.loadData(forceSilent: true)
                }
            }) {
                MealPlanSheet(
                    viewModel: mealPlanViewModel,
                    isPresented: $showMealPlanSheet,
                    targetCalories: viewModel.dailyTarget
                )
            }
            .fullScreenCover(isPresented: $showWeeklyPlanSheet, onDismiss: {
                // ⚡ Delay refresh to avoid transition glitch with fullScreenCover
                Task {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    await viewModel.loadData(forceSilent: true)
                }
            }) {
                WeeklyPlanView(
                    viewModel: mealPlanViewModel,
                    targetCalories: viewModel.dailyTarget
                )
            }
            .fullScreenCover(isPresented: $showMemoryHub) {
                MemoryHubView()
            }
        }
        .onAppear {
            Task {
                await viewModel.loadData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("navigateToJournal"))) { notification in
            if let date = notification.object as? Date {
                viewModel.selectedDate = date
                Task { await viewModel.loadData() }
            }
        }
    }
    
    @ViewBuilder
    private func mealSection(for type: String) -> some View {
        let meals = viewModel.meals(for: type)
        let foods = meals.flatMap { $0.mealFoods }
        let totalCals = foods.filter { $0.isEaten }.reduce(0) { $0 + $1.caloriesSnapshot }
        
        return Section {
            if foods.isEmpty {
                Text("Chưa có bữa ăn — nhấn + để thêm")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(foods) { food in
                    HStack(spacing: 12) {
                        Button(action: {
                            HapticManager.success()
                            Task {
                                await viewModel.toggleMealFoodStatus(id: food.id)
                            }
                        }) {
                            Image(systemName: food.isEaten ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(food.isEaten ? .green : .secondary)
                                .font(.system(size: 20))
                        }
                        .buttonStyle(.plain)
                        
                        NavigationLink {
                            MealDetailSheet(food: food.foodItem ?? FoodItemModel(id: UUID(), name: food.foodItem?.name ?? "Món ăn", calories: food.caloriesSnapshot, protein: food.proteinSnapshot, carbs: food.carbsSnapshot, fat: food.fatSnapshot, servingSize: 1))
                        } label: {
                            MealItemRow(mealFood: food)
                        }
                        .buttonStyle(.plain)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task { await viewModel.deleteMealFood(id: food.id) }
                        } label: {
                            Label("Xóa", systemImage: "trash")
                        }
                    }
                }
            }
        } header: {
            HStack {
                Label {
                    Text(type)
                        .font(.headline)
                        .foregroundColor(.primary)
                } icon: {
                    Image(systemName: iconForMealType(type))
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                Text("\(Int(totalCals)) kcal")
                    .font(.subheadline.bold())
                    .foregroundColor(totalCals > 0 ? .primary : .secondary)
                
                Button {
                    activeAddMealType = MealSheetItem(id: type)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
                .padding(.leading, 8)
            }
            .textCase(nil) // Prevent iOS from making header all-caps
        }
    }
    
    private func iconForMealType(_ type: String) -> String {
        switch type.lowercased() {
        case "bữa sáng": return "sunrise.fill"
        case "bữa trưa": return "sun.max.fill"
        case "bữa tối": return "moon.fill"
        case "ăn vặt": return "leaf.fill"
        default: return "fork.knife"
        }
    }
}

#Preview {
    MealsView()
}
