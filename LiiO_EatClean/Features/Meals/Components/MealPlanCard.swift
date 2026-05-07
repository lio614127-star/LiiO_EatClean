import SwiftUI

struct MealPlanCard: View {
    let mealType: String
    let foods: [AISuggestedFood]
    let isLogged: Bool
    var isViewOnly: Bool = false
    let onLog: () -> Void
    
    private var icon: String {
        MealPlanViewModel.mealIcons[mealType] ?? "🍽"
    }
    
    private var totalCalories: Double {
        foods.reduce(0) { $0 + $1.calories }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: icon + meal type + total kcal
            HStack {
                Text(icon)
                    .font(.title2)
                Text(mealType)
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text("\(Int(totalCalories)) kcal")
                    .font(.headline)
                    .foregroundColor(isLogged ? .gray : .green)
                
                if isLogged {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            
            // Food items list
            ForEach(foods) { food in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(food.name)
                            .font(.subheadline)
                            .foregroundColor(isLogged ? .secondary : .primary)
                        HStack(spacing: 12) {
                            MacroMini(label: "P", value: food.protein, color: .blue)
                            MacroMini(label: "C", value: food.carbs, color: .orange)
                            MacroMini(label: "F", value: food.fat, color: .pink)
                        }
                    }
                    Spacer()
                    Text("\(Int(food.calories)) kcal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            // CTA: "Log bữa này" — hidden when already logged or in view-only mode
            if !isViewOnly && !isLogged {
                Button(action: onLog) {
                    Text("Log bữa này")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .opacity(isLogged ? 0.6 : 1.0)
        )
        .shadow(color: .black.opacity(isLogged ? 0.02 : 0.05), radius: 8, y: 4)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isLogged)
    }
}
