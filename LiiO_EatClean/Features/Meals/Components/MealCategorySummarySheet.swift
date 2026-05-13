import SwiftUI

struct MealCategorySummarySheet: View {
    let mealType: String
    let initialMeals: [MealModel]
    var onUpdate: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                let foods = initialMeals.flatMap { $0.mealFoods }
                
                if foods.isEmpty {
                    Section {
                        Text("Chưa có món ăn nào trong \(mealType)")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                } else {
                    Section {
                        ForEach(foods) { food in
                            NavigationLink {
                                MealDetailSheet(food: food.foodItem ?? FoodItemModel(id: UUID(), name: "Món ăn", calories: 0, protein: 0, carbs: 0, fat: 0, servingSize: 0))
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(food.foodItem?.name ?? "Món ăn")
                                            .font(.headline)
                                        
                                        HStack(spacing: 12) {
                                            Text("\(Int(food.caloriesSnapshot)) kcal")
                                                .foregroundColor(.primary)
                                            
                                            HStack(spacing: 4) {
                                                Text("P: \(Int(food.proteinSnapshot))g")
                                                Text("C: \(Int(food.carbsSnapshot))g")
                                                Text("F: \(Int(food.fatSnapshot))g")
                                            }
                                            .foregroundColor(.secondary)
                                        }
                                        .font(.caption)
                                    }
                                    Spacer()
                                    if food.isEaten {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteFood(id: food.id)
                                } label: {
                                    Label("Xóa", systemImage: "trash")
                                }
                            }
                        }
                    } header: {
                        Text("Các món đã log")
                    }
                }
            }
            .navigationTitle(mealType)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") { dismiss() }
                }
            }
        }
    }
    
    private func deleteFood(id: UUID) {
        Task {
            let repo = MealRepository()
            try? await repo.deleteMealFood(by: id)
            await MainActor.run {
                onUpdate()
            }
        }
    }
}
