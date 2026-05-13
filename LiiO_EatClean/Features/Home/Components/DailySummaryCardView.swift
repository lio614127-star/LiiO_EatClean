import SwiftUI

// MARK: - Status Enum

enum DailySummaryStatus {
    case underTarget      // < 80%
    case onTrack          // 80–95%
    case achieved         // 95–105%
    case slightlyOver     // 105–115%
    case overTarget       // > 115%
    
    init(actual: Double, target: Double) {
        guard target > 0 else { self = .underTarget; return }
        let ratio = actual / target
        switch ratio {
        case ..<0.80: self = .underTarget
        case 0.80..<0.95: self = .onTrack
        case 0.95..<1.05: self = .achieved
        case 1.05..<1.15: self = .slightlyOver
        default: self = .overTarget
        }
    }
    
    var accentColor: Color {
        switch self {
        case .underTarget: return .blue
        case .onTrack: return Color(red: 0.2, green: 0.78, blue: 0.6) // mint
        case .achieved: return .green
        case .slightlyOver: return .orange
        case .overTarget: return Color(red: 0.9, green: 0.4, blue: 0.3)
        }
    }
    
    var pillColor: Color {
        accentColor.opacity(0.12)
    }
    
    func statusText(delta: Double) -> String {
        switch self {
        case .underTarget: return "Còn thiếu \(Int(abs(delta))) kcal"
        case .onTrack: return "Đang đi đúng kế hoạch"
        case .achieved: return "Đạt mục tiêu 🎉"
        case .slightlyOver: return "Vượt nhẹ \(Int(delta)) kcal"
        case .overTarget: return "Vượt \(Int(delta)) kcal"
        }
    }
    
    var pillText: String {
        switch self {
        case .underTarget: return "Chưa đủ"
        case .onTrack: return "Đúng hướng"
        case .achieved: return "Đạt mục tiêu"
        case .slightlyOver: return "Vượt nhẹ"
        case .overTarget: return "Vượt mục tiêu"
        }
    }
}

// MARK: - Premium Daily Summary Card

struct DailySummaryCardView: View {
    let summary: DailySummary?
    let isLoading: Bool
    @AppStorage("isDailySummaryExpanded") private var isExpanded: Bool = false
    
    var body: some View {
        if let summary = summary {
            let delta = summary.totalCalories - summary.targetCalories
            let status = DailySummaryStatus(actual: summary.totalCalories, target: summary.targetCalories)
            let progress = min(summary.totalCalories / max(summary.targetCalories, 1), 1.5)
            
            VStack(spacing: 0) {
                // MARK: Collapsed — Always Visible
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        isExpanded.toggle()
                    }
                }) {
                    VStack(alignment: .leading, spacing: 12) {
                        // Row 1: Title + Status Pill + Chevron
                        HStack(alignment: .center) {
                            Text("Hôm nay")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .padding(.leading, 4)
                            }
                            
                            Spacer()
                            
                            Text(status.pillText)
                                .font(.system(size: 11, weight: .semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(status.pillColor)
                                .foregroundColor(status.accentColor)
                                .cornerRadius(6)
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                                .padding(.leading, 2)
                        }
                        
                        // Row 2: Status subtitle
                        Text(status.statusText(delta: delta))
                            .font(.subheadline)
                            .foregroundColor(status.accentColor)
                        
                        // Row 3: Hero calories
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(formattedNumber(summary.totalCalories))")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(status.accentColor)
                            
                            Text("kcal")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(status.accentColor.opacity(0.7))
                        }
                        
                        Text("Mục tiêu \(formattedNumber(summary.targetCalories)) kcal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // Row 4: Progress Bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.systemGray5))
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [status.accentColor.opacity(0.7), status.accentColor],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: min(CGFloat(progress) * geo.size.width, geo.size.width))
                            }
                        }
                        .frame(height: 6)
                        
                        // Overflow indicator
                        if progress > 1.0 {
                            Text("Vượt \(Int(delta)) kcal · \(Int(progress * 100))%")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(status.accentColor.opacity(0.8))
                        }
                    }
                    .padding(16)
                }
                .buttonStyle(PlainButtonStyle())
                
                // MARK: Expanded — Detail Sections
                if isExpanded {
                    VStack(alignment: .leading, spacing: 0) {
                        sectionDivider
                        
                        // Section 1: Macro Overview
                        macroSection(summary: summary)
                        
                        // Section 2: Plan Comparison
                        if summary.plannedCalories != nil {
                            sectionDivider
                            planComparisonSection(summary: summary)
                        }
                        
                        // Section 3: Insights
                        if !summary.insights.isEmpty {
                            sectionDivider
                            insightSection(insights: summary.insights)
                        }
                        
                        // Section 4: AI Comment
                        if !summary.aiComment.isEmpty {
                            sectionDivider
                            aiCommentSection(comment: summary.aiComment, suggestion: summary.aiSuggestion)
                        }
                    }
                    .padding(.bottom, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        } else {
            // Skeleton loading state
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Hôm nay")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Đang tải...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                ProgressView()
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        }
    }
    
    // MARK: - Section Components
    
    private var sectionDivider: some View {
        Rectangle()
            .fill(Color(.separator).opacity(0.3))
            .frame(height: 0.5)
            .padding(.horizontal, 16)
    }
    
    private func macroSection(summary: DailySummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dinh dưỡng")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            VStack(spacing: 10) {
                MacroRow(
                    label: "Protein",
                    value: summary.protein,
                    target: summary.plannedProtein ?? (summary.targetCalories * 0.3) / 4,
                    color: .blue
                )
                MacroRow(
                    label: "Carbs",
                    value: summary.carbs,
                    target: (summary.targetCalories * 0.4) / 4,
                    color: Color(red: 0.55, green: 0.4, blue: 0.9)
                )
                MacroRow(
                    label: "Fat",
                    value: summary.fat,
                    target: (summary.targetCalories * 0.3) / 9,
                    color: .orange
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    private func planComparisonSection(summary: DailySummary) -> some View {
        let planned = summary.plannedCalories ?? summary.targetCalories
        let diff = summary.totalCalories - planned
        
        return VStack(alignment: .leading, spacing: 10) {
            Text("So với kế hoạch")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            VStack(spacing: 6) {
                comparisonRow(label: "Đã ăn", value: summary.totalCalories, color: .primary)
                comparisonRow(label: "Kế hoạch", value: planned, color: .secondary)
                
                Rectangle()
                    .fill(Color(.separator).opacity(0.2))
                    .frame(height: 0.5)
                
                HStack {
                    Text("Chênh lệch")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(diff >= 0 ? "+" : "")\(formattedNumber(diff)) kcal")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(abs(diff) <= planned * 0.05 ? .green : (diff > 0 ? .orange : .blue))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    private func comparisonRow(label: String, value: Double, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            Spacer()
            Text("\(formattedNumber(value)) kcal")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(color)
        }
    }
    
    private func insightSection(insights: [DailyInsight]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Nhận xét")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            // Show max 2 insights to keep compact
            ForEach(Array(insights.prefix(2))) { insight in
                DailyInsightRow(insight: insight)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    private func aiCommentSection(comment: String, suggestion: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11))
                    .foregroundColor(.purple.opacity(0.8))
                Text("AI Nhận Xét")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.purple.opacity(0.8))
            }
            
            Text(comment)
                .font(.system(size: 13))
                .foregroundColor(.primary.opacity(0.85))
                .lineLimit(4)
            
            if !suggestion.isEmpty {
                HStack(alignment: .top, spacing: 5) {
                    Text("💡")
                        .font(.system(size: 11))
                    Text(suggestion)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                .padding(.top, 2)
            }
        }
        .padding(14)
        .background(Color.purple.opacity(0.04))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    // MARK: - Helpers
    
    private func formattedNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }
}

// MARK: - Macro Row Component

private struct MacroRow: View {
    let label: String
    let value: Double
    let target: Double
    let color: Color
    
    private var ratio: Double {
        min(value / max(target, 1), 1.5)
    }
    
    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .frame(width: 52, alignment: .leading)
            
            Text("\(Int(value))")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .frame(width: 36, alignment: .trailing)
            
            Text("/ \(Int(target))g")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .frame(width: 48, alignment: .leading)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray5))
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color.opacity(0.75))
                        .frame(width: min(CGFloat(ratio) * geo.size.width, geo.size.width))
                }
            }
            .frame(height: 5)
        }
    }
}

// MARK: - Insight Row

struct DailyInsightRow: View {
    let insight: DailyInsight
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(severityColor)
                .frame(width: 6, height: 6)
                .padding(.top, 5)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(insight.message)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(insight.suggestion)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
    }
    
    private var severityColor: Color {
        switch insight.severity {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
}
