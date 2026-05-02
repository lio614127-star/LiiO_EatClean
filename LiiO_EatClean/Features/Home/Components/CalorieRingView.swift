import SwiftUI

struct CalorieRingView: View {
    let consumed: Double
    let target: Double
    
    private var progress: Double {
        if target > 0 {
            return min(consumed / target, 1.5) // Cap at 150% visually
        }
        return 0
    }
    
    private var isOverTarget: Bool {
        target > 0 && consumed > target
    }
    
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 16)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress > 1.0 ? 1.0 : animatedProgress) // Max 1.0 for the circle itself
                .stroke(
                    isOverTarget ? Color.orange : Color.green,
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            // Over-target extra ring (if we want to show it winding further)
            if animatedProgress > 1.0 {
                Circle()
                    .trim(from: 0, to: animatedProgress - 1.0)
                    .stroke(
                        Color.orange.opacity(0.5),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
            }
            
            // Center text
            VStack(spacing: 4) {
                Text("\(Int(consumed))")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(isOverTarget ? .orange : .primary)
                    .contentTransition(.numericText())
                
                Text("/ \(Int(target)) kcal")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { oldValue, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = newValue
            }
        }
    }
}

#Preview {
    VStack {
        CalorieRingView(consumed: 1250, target: 1800)
            .frame(width: 200, height: 200)
        CalorieRingView(consumed: 1950, target: 1800)
            .frame(width: 200, height: 200)
    }
}
