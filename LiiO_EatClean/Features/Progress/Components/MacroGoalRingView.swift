import SwiftUI

struct MacroGoalRingsRow: View {
    let aggregate: MacroAggregate
    let target: MacroTarget
    
    var body: some View {
        HStack(spacing: 0) {
            MacroGoalRing(
                label: "Protein",
                current: aggregate.avgDailyProtein,
                target: target.proteinGrams,
                color: .blue
            )
            MacroGoalRing(
                label: "Carbs",
                current: aggregate.avgDailyCarbs,
                target: target.carbsGrams,
                color: .purple
            )
            MacroGoalRing(
                label: "Fat",
                current: aggregate.avgDailyFat,
                target: target.fatGrams,
                color: .orange
            )
        }
    }
}

struct MacroGoalRing: View {
    let label: String
    let current: Double
    let target: Double
    let color: Color
    
    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(current / target, 1.0)
    }
    
    private var percentage: Int {
        guard target > 0 else { return 0 }
        return Int((current / target) * 100)
    }
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 5)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6), value: progress)
                
                // Center text
                Text("\(percentage)%")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }
            .frame(width: 48, height: 48)
            
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            
            Text("\(Int(current))g")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
    }
}
