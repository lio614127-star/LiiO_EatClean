import SwiftUI

struct MacroInsightsView: View {
    let aggregate: MacroAggregate
    let target: MacroTarget
    let trend: MacroTrend?
    let timeRange: TimeRange
    
    private var insights: [MacroInsight] {
        var result: [MacroInsight] = []
        
        // Protein check
        let proteinGoalPct = target.proteinGrams > 0 ? (aggregate.avgDailyProtein / target.proteinGrams) * 100 : 0
        if proteinGoalPct < 70 {
            result.append(MacroInsight(icon: "🔴", message: "Protein thấp (\(Int(proteinGoalPct))% mục tiêu)", suggestion: "Tăng thịt, cá, trứng, đậu phụ trong bữa ăn"))
        } else if proteinGoalPct < 90 {
            result.append(MacroInsight(icon: "🟡", message: "Protein hơi thấp (\(Int(proteinGoalPct))% mục tiêu)", suggestion: "Thêm 1 phần protein mỗi bữa chính"))
        } else if proteinGoalPct >= 95 {
            result.append(MacroInsight(icon: "🟢", message: "Protein đạt mục tiêu (\(Int(proteinGoalPct))%)", suggestion: "Tiếp tục duy trì nhé!"))
        }
        
        // Fat check
        let fatGoalPct = target.fatGrams > 0 ? (aggregate.avgDailyFat / target.fatGrams) * 100 : 0
        if fatGoalPct > 130 {
            result.append(MacroInsight(icon: "🔴", message: "Chất béo vượt mục tiêu (\(Int(fatGoalPct))%)", suggestion: "Giảm đồ chiên, chuyển sang luộc/hấp"))
        } else if fatGoalPct > 110 {
            result.append(MacroInsight(icon: "🟡", message: "Chất béo hơi cao (\(Int(fatGoalPct))% mục tiêu)", suggestion: "Ưu tiên nấu ít dầu mỡ hơn"))
        } else {
            result.append(MacroInsight(icon: "🟢", message: "Chất béo ổn định (\(Int(fatGoalPct))%)", suggestion: "Cân bằng tốt!"))
        }
        
        // Trend insights (only for 30N/3T)
        if let trend = trend {
            if trend.proteinTrend == .up {
                result.append(MacroInsight(icon: "📈", message: "Protein đang tăng", suggestion: "Xu hướng tốt, tiếp tục phát huy!"))
            } else if trend.proteinTrend == .down {
                result.append(MacroInsight(icon: "📉", message: "Protein đang giảm", suggestion: "Cần chú ý bổ sung thêm protein"))
            }
            
            if trend.fatTrend == .up {
                result.append(MacroInsight(icon: "📈", message: "Chất béo đang tăng", suggestion: "Kiểm tra lại lượng dầu mỡ trong bữa ăn"))
            }
        }
        
        return result
    }
    
    var body: some View {
        if !insights.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text("Nhận xét")
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                }
                
                ForEach(Array(insights.prefix(3).enumerated()), id: \.offset) { _, insight in
                    HStack(alignment: .top, spacing: 8) {
                        Text(insight.icon)
                            .font(.caption)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(insight.message)
                                .font(.caption)
                                .fontWeight(.medium)
                            Text(insight.suggestion)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }
}

private struct MacroInsight {
    let icon: String
    let message: String
    let suggestion: String
}
