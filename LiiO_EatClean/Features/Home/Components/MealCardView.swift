import SwiftUI

struct MealCardView: View {
    let mealType: String
    let icon: String
    let meals: [MealModel]
    var onAddTapped: (() -> Void)? = nil
    var onDelete: ((UUID) -> Void)? = nil
    
    // Calculate total calories for this meal type
    private var totalCalories: Double {
        meals.flatMap { $0.mealFoods }.reduce(0) { $0 + $1.caloriesSnapshot }
    }
    
    // Get all foods flattened across multiple meals of this type (if any)
    private var allFoods: [MealFoodModel] {
        meals.flatMap { $0.mealFoods }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.green)
                    .font(.title3)
                
                Text(mealType)
                    .font(.headline)
                
                Spacer()
                
                if !meals.isEmpty {
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
            if meals.isEmpty {
                // Empty state
                HStack {
                    Text("Chưa có bữa ăn")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.top, 4)
            } else {
                // Food list (Full list with inline delete instead of preview)
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(allFoods, id: \.id) { mealFood in
                        HStack {
                            Text(mealFood.foodItem?.name ?? "Món ăn")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text("\(Int(mealFood.caloriesSnapshot)) kcal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let onDelete = onDelete {
                                Button(action: {
                                    onDelete(mealFood.id)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(Color(.systemGray4))
                                        .font(.caption)
                                }
                            }
                        }
                        Divider()
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
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
