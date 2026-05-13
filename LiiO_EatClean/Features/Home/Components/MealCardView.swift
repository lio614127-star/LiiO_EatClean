import SwiftUI

struct MealCardView: View {
    let mealType: String
    let icon: String
    let meals: [MealModel]
    var pendingLinkSuggestion: (mealId: UUID, plannedMealType: String)? = nil
    var onAddTapped: (() -> Void)? = nil
    var onRowTapped: (() -> Void)? = nil
    var onDelete: ((UUID) -> Void)? = nil
    var onToggleEaten: ((UUID) -> Void)? = nil
    var onLinkToPlan: ((UUID) -> Void)? = nil
    
    // Calculate total calories for this meal type
    private var totalCalories: Double {
        meals.flatMap { $0.mealFoods }.filter { $0.isEaten }.reduce(0) { $0 + $1.caloriesSnapshot }
    }
    
    // Get all foods flattened across multiple meals of this type (if any)
    private var allFoods: [MealFoodModel] {
        meals.flatMap { $0.mealFoods }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header — NO tags here, just mealType + kcal + add button
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.green)
                    .font(.title3)
                
                Text(mealType)
                    .font(.headline)
                
                Spacer()
                
                if !allFoods.isEmpty {
                    Text("\(Int(totalCalories)) kcal")
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                }
                
                Button(action: {
                    onAddTapped?()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
            }
            
            // Content
            if allFoods.isEmpty {
                // Empty state
                HStack {
                    Text("Chưa có bữa ăn")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .frame(minHeight: 32)
                .padding(.top, 4)
            } else {
                // Food items with inline tags per item
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(meals) { meal in
                        ForEach(meal.mealFoods) { mealFood in
                            Button(action: {
                                onRowTapped?()
                            }) {
                                HStack(spacing: 10) {
                                    Button(action: {
                                        HapticManager.success()
                                        onToggleEaten?(mealFood.id)
                                    }) {
                                        Image(systemName: mealFood.isEaten ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(mealFood.isEaten ? .green : .secondary)
                                            .font(.system(size: 18))
                                    }
                                    .buttonStyle(.plain)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(mealFood.foodItem?.name ?? "Món ăn")
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                        
                                        // Inline tag — only one tag per item
                                        if meal.linkedPlannedMealId != nil {
                                            Text("Theo kế hoạch")
                                                .font(.system(size: 9, weight: .bold))
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 1)
                                                .background(Color.blue.opacity(0.1))
                                                .foregroundColor(.blue)
                                                .cornerRadius(3)
                                        } else {
                                            Text("Ngoài kế hoạch")
                                                .font(.system(size: 9, weight: .bold))
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 1)
                                                .background(Color.orange.opacity(0.1))
                                                .foregroundColor(.orange)
                                                .cornerRadius(3)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(Int(mealFood.caloriesSnapshot)) kcal")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Button(action: {
                                        onDelete?(mealFood.id)
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red.opacity(0.7))
                                            .font(.caption)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Suggestion chip: show when this unlinked meal matches a plan
                        if meal.linkedPlannedMealId == nil,
                           let suggestion = pendingLinkSuggestion,
                           suggestion.mealId == meal.id {
                            Button(action: { onLinkToPlan?(meal.id) }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles")
                                        .font(.caption2)
                                    Text("Khớp với \(suggestion.plannedMealType) trong kế hoạch · Gắn")
                                        .font(.caption2.bold())
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                        .font(.caption2)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.purple.opacity(0.08))
                                .foregroundColor(.purple)
                                .cornerRadius(8)
                            }
                            .padding(.leading, 30)
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: meals.count)
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .onTapGesture {
            onRowTapped?()
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        // Empty state
        MealCardView(
            mealType: "Bữa sáng",
            icon: "sunrise.fill",
            meals: []
        )
        
        // With items
        let mealModel = MealModel(
            id: UUID(),
            date: Date(),
            mealType: "Bữa trưa",
            mealFoods: [
                MealFoodModel(
                    id: UUID(),
                    quantity: 1,
                    caloriesSnapshot: 450,
                    proteinSnapshot: 20,
                    carbsSnapshot: 50,
                    fatSnapshot: 15,
                    foodItem: FoodItemModel(id: UUID(), name: "Phở bò", calories: 450, protein: 20, carbs: 50, fat: 15, servingSize: 1, isCustom: false)
                )
            ]
        )
        
        MealCardView(
            mealType: "Bữa trưa",
            icon: "sun.max.fill",
            meals: [mealModel],
            onDelete: { _ in }
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
