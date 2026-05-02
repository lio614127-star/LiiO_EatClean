import SwiftUI

struct MacroBarView: View {
    let label: String
    let consumed: Double
    let target: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(consumed)) / \(Int(target))g")
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            
            ProgressView(value: target > 0 ? min(consumed / target, 1.0) : 0)
                .tint(color)
                .background(Color(.systemGray6))
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        MacroBarView(label: "Protein", consumed: 50, target: 120, color: .blue)
        MacroBarView(label: "Carbs", consumed: 150, target: 180, color: .orange)
        MacroBarView(label: "Fat", consumed: 70, target: 60, color: .pink)
    }
    .padding()
}
