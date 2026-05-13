import SwiftUI

struct MacroDashboardView: View {
    let aggregate: MacroAggregate
    let target: MacroTarget
    let timeRange: TimeRange
    let trend: MacroTrend?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(.green)
                    .font(.subheadline)
                Text("Tỉ lệ Dinh dưỡng")
                    .font(.headline)
                Spacer()
                Text(timeRangeLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .cornerRadius(6)
            }
            
            // Macro Bars
            VStack(spacing: 12) {
                MacroProgressBar(
                    label: "Protein",
                    shortLabel: "P",
                    currentGrams: aggregate.avgDailyProtein,
                    targetGrams: target.proteinGrams,
                    percentage: aggregate.proteinPercentage,
                    color: .blue
                )
                
                MacroProgressBar(
                    label: "Carbs",
                    shortLabel: "C",
                    currentGrams: aggregate.avgDailyCarbs,
                    targetGrams: target.carbsGrams,
                    percentage: aggregate.carbsPercentage,
                    color: .purple
                )
                
                MacroProgressBar(
                    label: "Fat",
                    shortLabel: "F",
                    currentGrams: aggregate.avgDailyFat,
                    targetGrams: target.fatGrams,
                    percentage: aggregate.fatPercentage,
                    color: .orange
                )
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // Goal Rings
            MacroGoalRingsRow(aggregate: aggregate, target: target)
            
            // Trend badges (30N/3T only)
            if let trend = trend {
                HStack(spacing: 16) {
                    TrendBadge(label: "P", direction: trend.proteinTrend, color: .blue)
                    TrendBadge(label: "C", direction: trend.carbsTrend, color: .purple)
                    TrendBadge(label: "F", direction: trend.fatTrend, color: .orange)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private var timeRangeLabel: String {
        switch timeRange {
        case .week: return "TB 7 ngày"
        case .month: return "TB 30 ngày"
        case .quarter: return "TB 3 tháng"
        case .custom: return "Tùy chọn"
        }
    }
}

struct MacroProgressBar: View {
    let label: String
    let shortLabel: String
    let currentGrams: Double
    let targetGrams: Double
    let percentage: Double
    let color: Color
    
    private var progress: Double {
        guard targetGrams > 0 else { return 0 }
        return min(currentGrams / targetGrams, 1.5) // Cap at 150% for display
    }
    
    var body: some View {
        HStack(spacing: 10) {
            // Label
            Text(shortLabel)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .frame(width: 18)
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.7), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: min(CGFloat(progress) * geo.size.width, geo.size.width))
                        .animation(.spring(response: 0.5), value: progress)
                }
            }
            .frame(height: 8)
            
            // Values
            HStack(spacing: 4) {
                Text("\(Int(currentGrams))g")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                Text("/ \(Int(targetGrams))g")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .frame(width: 80, alignment: .trailing)
            
            // Percentage badge
            Text("\(Int(percentage))%")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .frame(width: 32)
        }
    }
}

struct TrendBadge: View {
    let label: String
    let direction: MacroTrend.TrendDirection
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption2.bold())
                .foregroundColor(color)
            Image(systemName: direction.icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(color)
            Text(direction.rawValueVN)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct MacroGoalRingsRow: View {
    let aggregate: MacroAggregate
    let target: MacroTarget
    
    var body: some View {
        HStack(spacing: 20) {
            MacroRing(
                progress: aggregate.avgDailyProtein / max(target.proteinGrams, 1),
                color: .blue,
                label: "Protein"
            )
            MacroRing(
                progress: aggregate.avgDailyCarbs / max(target.carbsGrams, 1),
                color: .purple,
                label: "Carbs"
            )
            MacroRing(
                progress: aggregate.avgDailyFat / max(target.fatGrams, 1),
                color: .orange,
                label: "Fat"
            )
        }
        .frame(maxWidth: .infinity)
    }
}

struct MacroRing: View {
    let progress: Double
    let color: Color
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 6)
                
                Circle()
                    .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                    .stroke(
                        AngularGradient(
                            colors: [color.opacity(0.8), color],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                Text(String(format: "%.1f%%", progress * 100).replacingOccurrences(of: ".0", with: ""))
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .padding(.horizontal, 4)
            }
            .frame(width: 50, height: 50)
            
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}
