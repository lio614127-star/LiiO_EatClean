import SwiftUI

struct PendingPlannedMealCard: View {
    let plannedMeal: PlannedMealModel
    var onMarkAsEaten: () -> Void
    var onSkip: () -> Void
    var onReplace: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(plannedMeal.type)
                    .font(.headline)
                
                Spacer()
                
                Text("Kế hoạch")
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(plannedMeal.foodItems.map { $0.name }.joined(separator: " & "))
                    .font(.subheadline)
                    .lineLimit(2)
                
                Text("\(Int(plannedMeal.totalCalories)) kcal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 12) {
                Button(action: onMarkAsEaten) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Đã ăn")
                    }
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button(action: onSkip) {
                    Text("Bỏ qua")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
                
                Button(action: onReplace) {
                    Text("Đổi")
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
