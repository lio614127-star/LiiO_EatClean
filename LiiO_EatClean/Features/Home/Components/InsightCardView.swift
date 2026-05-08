import SwiftUI

struct InsightCardView: View {
    let insight: DailyInsight
    let onDismiss: () -> Void
    let onTapAction: (() -> Void)?
    
    private var severityColor: Color {
        switch insight.severity {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    private var severityIcon: String {
        switch insight.severity {
        case .low: return "arrow.triangle.2.circlepath"
        case .medium: return "exclamationmark.triangle"
        case .high: return "shield.slash"
        }
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            Image(systemName: severityIcon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(severityColor)
                .frame(width: 36, height: 36)
                .background(Circle().fill(severityColor.opacity(0.12)))
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.message)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(insight.suggestion)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Dismiss
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(UIColor.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(severityColor.opacity(0.3), lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTapAction?()
        }
    }
}
