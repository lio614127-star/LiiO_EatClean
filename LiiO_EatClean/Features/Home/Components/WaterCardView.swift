import SwiftUI

struct WaterCardView: View {
    let consumed: Double
    let target: Double
    let onAdd: (Double) -> Void
    let onReset: () -> Void
    
    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(consumed / target, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundColor(.blue)
                Text("Nước uống")
                    .font(.headline)
                
                Spacer()
                
                Text("\(Int(consumed)) / \(Int(target)) ml")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    HapticManager.interaction()
                    onReset()
                }) {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .foregroundColor(.gray.opacity(0.5))
                        .font(.title3)
                }
            }
            
            // Progress Bar with animation
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.6), Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress)
                        .animation(.easeInOut(duration: 0.5), value: progress)
                }
            }
            .frame(height: 14)
            
            // Quick Add Buttons
            HStack(spacing: 12) {
                quickButton(amount: 100)
                quickButton(amount: 250)
                quickButton(amount: 500)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private func quickButton(amount: Int) -> some View {
        Button(action: {
            HapticManager.interaction()
            onAdd(Double(amount))
        }) {
            Text("+\(amount)ml")
                .font(.subheadline.bold())
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue.opacity(0.1))
                )
        }
    }
}
