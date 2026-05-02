import SwiftUI

struct GoalSelectionStepView: View {
    @Binding var selectedGoal: String
    let weight: Double
    let height: Double
    let age: Double
    let gender: String
    
    private let goals = [
        (id: "lose", title: "Giảm cân", subtitle: "Giảm cân từ từ và an toàn", icon: "arrow.down.circle.fill"),
        (id: "maintain", title: "Giữ cân", subtitle: "Duy trì cân nặng hiện tại", icon: "equal.circle.fill"),
        (id: "gain", title: "Tăng cân", subtitle: "Tăng cân lành mạnh", icon: "arrow.up.circle.fill")
    ]
    
    private var calculatedCalories: Double {
        CalorieCalculator.calculateDailyCalories(
            weight: weight,
            height: height,
            age: age,
            gender: gender,
            goal: selectedGoal
        )
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Mục tiêu của bạn")
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Goal cards
            ForEach(goals, id: \.id) { goal in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedGoal = goal.id
                    }
                }) {
                    HStack(spacing: 14) {
                        Image(systemName: goal.icon)
                            .font(.title2)
                            .foregroundColor(selectedGoal == goal.id ? .white : .green)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(goal.title)
                                .font(.headline)
                                .foregroundColor(selectedGoal == goal.id ? .white : .primary)
                            Text(goal.subtitle)
                                .font(.caption)
                                .foregroundColor(selectedGoal == goal.id ? .white.opacity(0.8) : .secondary)
                        }
                        
                        Spacer()
                        
                        if selectedGoal == goal.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(selectedGoal == goal.id ? Color.green : Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(selectedGoal == goal.id ? Color.green : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
            
            // Calorie preview
            if !selectedGoal.isEmpty {
                VStack(spacing: 6) {
                    Text("🔥 Your daily calories")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(calculatedCalories))")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.green)
                        .contentTransition(.numericText())
                        .animation(.easeInOut, value: calculatedCalories)
                    
                    Text("kcal")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Based on your profile & goal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 12)
                .transition(.opacity.combined(with: .scale))
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
}

#Preview {
    GoalSelectionStepView(
        selectedGoal: .constant("lose"),
        weight: 65, height: 165, age: 25, gender: "male"
    )
}
