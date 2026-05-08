import SwiftUI

struct MealSheetItem: Identifiable, Equatable {
    let id: String
}

struct MealsView: View {
    @State private var viewModel = MealsViewModel()
    @State private var activeAddMealType: MealSheetItem?
    @State private var activeDetailMealType: MealSheetItem?
    @State private var showMealPlanSheet = false
    @State private var mealPlanViewModel = MealPlanViewModel()
    @State private var showMemoryHub = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.todayMeals.isEmpty {
                    ProgressView()
                } else {
                    List {
                        // Header
                        VStack(spacing: 4) {
                            Text("Hôm nay")
                                .font(.title2.bold())
                            Text("Còn \(Int(viewModel.remainingCalories)) kcal")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        
                        // Meal Plan Button (D-03: entry point)
                        Button {
                            guard !showMealPlanSheet else { return }
                            showMealPlanSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("Lên kế hoạch hôm nay")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [Color.green, Color.green.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        
                        // Meal Sections
                        ForEach(["Bữa sáng", "Bữa trưa", "Bữa tối", "Ăn vặt"], id: \.self) { type in
                            mealSection(for: type)
                        }
                        
                    }
                    .listStyle(.insetGrouped)
                    .refreshable {
                        await viewModel.loadTodayMeals()
                    }
                }
            }
            .navigationTitle("Meals")
            .navigationBarHidden(true)
            .sheet(item: $activeAddMealType, onDismiss: {
                Task { await viewModel.loadTodayMeals() }
            }) { item in
                AddMealView(selectedMealType: item.id)
            }
            .sheet(item: $activeDetailMealType) { item in
                MealDetailSheet(
                    mealType: item.id,
                    initialMeals: viewModel.meals(for: item.id),
                    onUpdate: {
                        Task { await viewModel.loadTodayMeals() }
                    }
                )
                .id(item.id + "-\(viewModel.todayMeals.flatMap { $0.mealFoods }.count)")
            }
            .fullScreenCover(isPresented: $showMealPlanSheet, onDismiss: {
                mealPlanViewModel.reset()
                Task { await viewModel.loadTodayMeals() }
            }) {
                MealPlanSheet(
                    viewModel: mealPlanViewModel,
                    isPresented: $showMealPlanSheet,
                    targetCalories: viewModel.dailyTarget
                )
            }
            .fullScreenCover(isPresented: $showMemoryHub) {
                MemoryHubView()
            }
        }
        .task {
            await viewModel.loadTodayMeals()
        }
    }
    
    @ViewBuilder
    private func mealSection(for type: String) -> some View {
        let meals = viewModel.meals(for: type)
        let foods = meals.flatMap { $0.mealFoods }.filter { $0.isEaten }
        let totalCals = foods.reduce(0) { $0 + $1.caloriesSnapshot }
        
        Section {
            if foods.isEmpty {
                Text("Chưa có bữa ăn — nhấn + để thêm")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(foods) { food in
                    MealItemRow(mealFood: food)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            activeDetailMealType = MealSheetItem(id: type)
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
