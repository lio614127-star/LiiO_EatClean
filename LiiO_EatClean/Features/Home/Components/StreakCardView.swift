import SwiftUI

struct StreakCardView: View {
    let streak: StreakModel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.interaction()
            onTap()
        }) {
            VStack(spacing: 12) {
                // Header
                HStack {
                    HStack(spacing: 6) {
                        Text("🔥")
                            .font(.title2)
                        Text("\(streak.currentStreak) ngày liên tiếp")
                            .font(.headline)
                            .contentTransition(.numericText())
                    }
                    
                    Spacer()
                    
                    if streak.currentStreak >= 7 {
                        Text("🌿")
                            .font(streak.currentStreak >= 30 ? .title : .title3)
                            .shadow(color: .green.opacity(0.5), radius: 4, x: 0, y: 2)
                    }
                    
                    Text("🏆 Kỷ lục: \(streak.longestStreak)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .contentTransition(.numericText())
                }
                
                // Indicators
                HStack(spacing: 16) {
                    ConditionIndicator(title: "Bữa ăn", isMet: streak.mealConditionMet)
                    ConditionIndicator(title: "Calo", isMet: streak.calorieConditionMet)
                    ConditionIndicator(title: "Nước", isMet: streak.waterConditionMet)
                    Spacer()
                }
                
                // Message
                HStack {
                    if streak.conditionsMet == 3 {
                        Text("Bạn đang duy trì rất tốt!")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    } else {
                        Text("Gần đạt streak (\(streak.conditionsMet)/3 điều kiện)")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                    Spacer()
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct ConditionIndicator: View {
    let title: String
    let isMet: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isMet ? Color.green : Color.gray.opacity(0.3))
                .frame(width: 8, height: 8)
            Text(title)
                .font(.caption)
                .foregroundColor(isMet ? .primary : .secondary)
        }
    }
}
