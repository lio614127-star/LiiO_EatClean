import SwiftUI

struct MealDetailSheet: View {
    let mealType: String
    @State private var meals: [MealModel]
    var onUpdate: () -> Void
    
    @Environment(\.dismiss) var dismiss
    private let mealRepository: MealRepositoryProtocol = MealRepository()
    
    init(mealType: String, meals: [MealModel], onUpdate: @escaping () -> Void) {
        self.mealType = mealType
        self._meals = State(initialValue: meals)
        self.onUpdate = onUpdate
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
        // Update persistence manager
        MealFoodStatusManager.shared.setEaten(id: id, isEaten: isEaten)
        
        // Find and update in local state for UI responsiveness
        for (mIndex, meal) in meals.enumerated() {
            if let fIndex = meal.mealFoods.firstIndex(where: { $0.id == id }) {
                meals[mIndex].mealFoods[fIndex].isEaten = isEaten
                
                // Trigger global update
                Task {
                    await MainActor.run {
                        onUpdate()
                    }
                }
                break
            }
        }
    }
    
    private func deleteFood(at offsets: IndexSet) {
        // Implementation for deletion if needed
        // For now, focus on the isEaten toggle
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
