import SwiftUI

struct MealItemRow: View {
    let mealFood: MealFoodModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(mealFood.foodItem?.name ?? "Unknown")
                    .font(.body)
                
                // Macro mini display
                HStack(spacing: 8) {
                    MacroMini(label: "P", value: mealFood.proteinSnapshot, color: .blue)
                    MacroMini(label: "C", value: mealFood.carbsSnapshot, color: .orange)
                    MacroMini(label: "F", value: mealFood.fatSnapshot, color: .pink)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(Int(mealFood.caloriesSnapshot)) kcal")
                    .font(.subheadline.bold())
                    .foregroundColor(.green)
                
                if mealFood.quantity != 1.0 {
                    Text("x\(String(format: "%.1f", mealFood.quantity))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct MacroMini: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 2) {
            Text("\(label):")
                .foregroundColor(color)
            Text("\(Int(value))g")
                .foregroundColor(.secondary)
        }
        .font(.caption2)
    }
}
