import SwiftUI

struct AICoachingCardView: View {
    let insight: CoachingInsight
    var onApply: ((GoalAdjustmentProposal) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                
                Text(insight.title)
                    .font(.headline)
                
                Spacer()
                
                severityBadge
            }
            
            Text(insight.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)
            
            if let proposal = insight.proposal, let label = insight.actionLabel {
                Button {
                    onApply?(proposal)
                } label: {
                    HStack {
                        Spacer()
                        Text(label)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    private var severityBadge: some View {
        let info = badgeInfo
        return Text(info.text)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(info.color.opacity(0.1))
            .foregroundColor(info.color)
            .clipShape(Capsule())
    }
    
    private var badgeInfo: (color: Color, text: String) {
        switch insight.severity {
        case .soft:
            return (.blue, "Dịu dàng")
        case .medium:
            return (.orange, "Cần thiết")
        case .hard:
            return (.red, "Khẩn cấp")
        case .recovery:
            return (.green, "Phục hồi")
        case .maintenance, .dietBreak:
            return (.gray, "Duy trì")
        }
    }
}

#Preview {
    VStack {
        AICoachingCardView(insight: CoachingInsight(
            title: "Cập nhật mục tiêu",
            message: "Cân nặng đã chững 14 ngày. Giảm nhẹ calo để phá vỡ thế bế tắc.",
            actionLabel: "Áp dụng mục tiêu mới",
            severity: .medium,
            proposal: nil
        ))
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
