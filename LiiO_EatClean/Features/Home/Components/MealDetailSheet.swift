import SwiftUI

struct MealDetailSheet: View {
    let mealType: String
    @State private var meals: [MealModel] = []
    @State private var isLoading = false
    var onUpdate: () -> Void
    
    @Environment(\.dismiss) var dismiss
    private let mealRepository: MealRepositoryProtocol = MealRepository()
    
    init(mealType: String, initialMeals: [MealModel] = [], onUpdate: @escaping () -> Void) {
        self.mealType = mealType
        self.onUpdate = onUpdate
        self._meals = State(initialValue: initialMeals)
    }
    
    private var allFoods: [MealFoodModel] {
        meals.flatMap { $0.mealFoods }
    }
    
    private var totalCalories: Double {
        allFoods.filter { $0.isEaten }.reduce(0) { $0 + $1.caloriesSnapshot }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Summary
                VStack(spacing: 8) {
                    Text("\(Int(totalCalories))")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                    Text("kcal đã ăn")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 32)
                
                List {
                    Section("Danh sách món ăn") {
                        if allFoods.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "fork.knife")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                Text("Chưa có món ăn nào được thêm")
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            ForEach(allFoods) { food in
                                HStack(spacing: 16) {
                                    Toggle(isOn: binding(for: food.id)) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(food.foodItem?.name ?? "Món ăn")
                                                .font(.headline)
                                            
                                            HStack(spacing: 12) {
                                                Text("\(food.quantity, specifier: "%.1f") phần")
                                                    .foregroundColor(.secondary)
                                                
                                                Text("\(Int(food.caloriesSnapshot)) kcal")
                                                    .foregroundColor(.primary)
                                            }
                                            .font(.caption)
                                            
                                            HStack(spacing: 8) {
                                                Text("P: \(Int(food.proteinSnapshot))g")
                                                    .foregroundColor(.blue)
                                                Text("C: \(Int(food.carbsSnapshot))g")
                                                    .foregroundColor(.orange)
                                                Text("F: \(Int(food.fatSnapshot))g")
                                                    .foregroundColor(.pink)
                                            }
                                            .font(.caption2.bold())
                                        }
                                    }
                                    .toggleStyle(CheckboxStyle())
                                }
                                .padding(.vertical, 4)
                            }
                            .onDelete(perform: deleteFood)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .overlay {
                    if isLoading {
                        ProgressView()
                    }
                }
            }
            .navigationTitle(mealType)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Xong") {
                        dismiss()
                    }
                    .bold()
                }
            }
            .task {
                await loadMeals()
            }
        }
    }
    
    private func loadMeals() async {
        guard !isLoading else { return }
        isLoading = true
        
        do {
            try await performLoad()
            
            // If empty, wait a bit and retry once (CoreData sync fallback)
            if allFoods.isEmpty {
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                try await performLoad()
            }
        } catch {
            print("Error loading meals in detail: \(error)")
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    private func performLoad() async throws {
        let allTodayMeals = try await mealRepository.fetchMeals(by: Date())
        await MainActor.run {
            let targetType = mealType.trimmingCharacters(in: .whitespacesAndNewlines)
            self.meals = allTodayMeals.filter { meal in
                let mType = meal.mealType.trimmingCharacters(in: .whitespacesAndNewlines)
                return mType.localizedCaseInsensitiveCompare(targetType) == .orderedSame
            }
        }
    }
    
    private func binding(for id: UUID) -> Binding<Bool> {
        Binding(
            get: {
                if let food = allFoods.first(where: { $0.id == id }) {
                    return food.isEaten
                }
                return false
            },
            set: { newValue in
                updateEatenStatus(id: id, isEaten: newValue)
            }
        )
    }
    
    private func updateEatenStatus(id: UUID, isEaten: Bool) {
        Task {
            // Update CoreData
            try? await mealRepository.updateMealFoodStatus(id: id, isEaten: isEaten)
            
            // Update local state for UI responsiveness
            await MainActor.run {
                for (mIndex, meal) in meals.enumerated() {
                    if let fIndex = meal.mealFoods.firstIndex(where: { $0.id == id }) {
                        meals[mIndex].mealFoods[fIndex].isEaten = isEaten
                        onUpdate()
                        break
                    }
                }
            }
        }
    }
    
    private func deleteFood(at offsets: IndexSet) {
        let foodsToDelete = offsets.map { allFoods[$0] }
        Task {
            for food in foodsToDelete {
                try? await mealRepository.deleteMealFood(by: food.id)
            }
            await loadMeals()
            await MainActor.run {
                onUpdate()
            }
        }
    }
}

// Custom Checkbox Style
struct CheckboxStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }) {
            HStack {
                Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(configuration.isOn ? .green : .secondary)
                    .font(.title2)
                
                configuration.label
            }
        }
        .buttonStyle(.plain)
    }
}
