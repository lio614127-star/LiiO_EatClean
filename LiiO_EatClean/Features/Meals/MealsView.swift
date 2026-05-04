import SwiftUI

struct MealSheetItem: Identifiable, Equatable {
    let id: String
}

struct MealsView: View {
    @State private var viewModel = MealsViewModel()
    @State private var activeAddMealType: MealSheetItem?
    @State private var activeDetailMealType: MealSheetItem?
    
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
                        
                        // Meal Sections
                        ForEach(["Bữa sáng", "Bữa trưa", "Bữa tối", "Ăn vặt"], id: \.self) { type in
                            mealSection(for: type)
                        }
                        
                        // Memory & AI Section
                        VStack(spacing: 16) {
                            MemorySummaryCard()
                            
                            AISuggestionSectionView(
                                remainingCalories: viewModel.remainingCalories,
                                onMealLogged: {
                                    Task { await viewModel.loadTodayMeals() }
                                }
                            )
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .padding(.vertical, 16)
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
