import SwiftUI

struct MacroInsightsView: View {
    let aggregate: MacroAggregate
    let target: MacroTarget
    let trend: MacroTrend?
    let timeRange: TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nhận xét từ AI Coach")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 10) {
                if let trend = trend {
                    insightRow(
                        icon: "bolt.fill",
                        color: .blue,
                        text: proteinInsight(trend: trend.proteinTrend)
                    )
                    
                    insightRow(
                        icon: "leaf.fill",
                        color: .purple,
                        text: carbsInsight(trend: trend.carbsTrend)
                    )
                } else {
                    insightRow(
                        icon: "info.circle.fill",
                        color: .green,
                        text: "Hãy tiếp tục duy trì việc ghi chép để AI có thể phân tích xu hướng dinh dưỡng của bạn."
                    )
                }
            }
            .padding()
            .background(Color(.systemGray6).opacity(0.5))
            .cornerRadius(12)
        }
        .padding(.top, 8)
    }
    
    private func insightRow(icon: String, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 14))
                .frame(width: 20, height: 20)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.primary.opacity(0.8))
                .lineLimit(3)
        }
    }
    
    private func proteinInsight(trend: MacroTrend.TrendDirection) -> String {
        switch trend {
        case .up:
            return "Lượng Protein đang có xu hướng tăng. Rất tốt cho việc duy trì cơ bắp!"
        case .down:
            return "Protein đang giảm nhẹ. Hãy thử thêm trứng hoặc ức gà vào bữa trưa nhé."
        case .stable:
            return "Lượng Protein ổn định. Bạn đang kiểm soát thực đơn rất tốt."
        }
    }
    
    private func carbsInsight(trend: MacroTrend.TrendDirection) -> String {
        switch trend {
        case .up:
            return "Carbs đang tăng cao. Hãy chú ý giảm bớt đồ ngọt hoặc tinh bột tinh luyện."
        case .down:
            return "Carbs đang giảm. Đây là dấu hiệu tốt nếu bạn đang trong giai đoạn siết mỡ."
        case .stable:
            return "Lượng tinh bột đang ở mức cân bằng."
        }
    }
}
