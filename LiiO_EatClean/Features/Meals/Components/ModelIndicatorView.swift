import SwiftUI

struct ModelIndicatorView: View {
    let activity: AIActivity
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.green.opacity(0.2), lineWidth: 2)
                    .frame(width: 32, height: 32)
                
                Image(systemName: "sparkles")
                    .foregroundColor(.green)
                    .font(.system(size: 14, weight: .bold))
                    .symbolEffect(.pulse, options: .repeating)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(activity.modelName) \(activity.keyTier == "PAID" ? "PRO" : "FLASH")")
                    .font(.caption2.bold())
                    .foregroundColor(.secondary)
                
                Text(activity.progressText)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            ProgressView()
                .scaleEffect(0.8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        )
        .overlay(
            Capsule()
                .stroke(Color.green.opacity(0.1), lineWidth: 1)
        )
    }
}
