import SwiftUI

struct ActionableMessageView: View {
    let message: ChatMessage
    let onLogMeal: (AISuggestedFood) -> Void
    
    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
            // Main Text Bubble
            if !message.text.isEmpty {
                Text(LocalizedStringKey(message.text))
                    .padding(12)
                    .background(message.isUser ? Color.green : Color(UIColor.secondarySystemBackground))
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(16)
                    .clipShape(BubbleShape(isUser: message.isUser))
            }
            
            // Actionable JSON Cards
            if let foods = message.suggestedFoods, !foods.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Gợi ý cho bạn:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                    
                    ForEach(foods) { food in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(food.name)
                                    .font(.headline)
                                Spacer()
                                Text("\(Int(food.calories)) kcal")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.green)
                            }
                            
                            HStack(spacing: 12) {
                                MacroLabel(title: "P", value: food.protein, color: .red)
                                MacroLabel(title: "C", value: food.carbs, color: .blue)
                                MacroLabel(title: "F", value: food.fat, color: .orange)
                            }
                            
                            Button(action: {
                                onLogMeal(food)
                            }) {
                                Text("Log Ngay")
                                    .font(.subheadline.bold())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.green.opacity(0.15))
                                    .foregroundColor(.green)
                                    .cornerRadius(8)
                            }
                            .padding(.top, 4)
                        }
                        .padding(12)
                        .background(Color(UIColor.tertiarySystemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
                .frame(maxWidth: 280) // Limit width for cards
            }
        }
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

private struct MacroLabel: View {
    let title: String
    let value: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 2) {
            Text(title)
                .font(.caption2.bold())
                .foregroundColor(color)
            Text("\(Int(value))g")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// Custom Shape for Chat Bubbles
struct BubbleShape: Shape {
    var isUser: Bool
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [
                .topLeft,
                .topRight,
                isUser ? .bottomLeft : .bottomRight
            ],
            cornerRadii: CGSize(width: 16, height: 16)
        )
        return Path(path.cgPath)
    }
}
