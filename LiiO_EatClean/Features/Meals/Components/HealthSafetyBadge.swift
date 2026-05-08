import SwiftUI

struct HealthSafetyBadge: View {
    let isHighSeverity: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isHighSeverity ? "exclamationmark.shield" : "checkmark.shield")
                .font(.caption2)
            
            Text(isHighSeverity 
                ? "Một số món đã bị loại bỏ để đảm bảo an toàn sức khỏe"
                : "Đã điều chỉnh phù hợp với kiêng cữ và sức khỏe của bạn")
                .font(.caption2)
        }
        .foregroundColor(isHighSeverity ? .orange : .green)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill((isHighSeverity ? Color.orange : Color.green).opacity(0.08))
        )
    }
}
