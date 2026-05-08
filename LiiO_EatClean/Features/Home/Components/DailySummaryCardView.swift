import SwiftUI

struct DailySummaryCardView: View {
    let summary: DailySummary?
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            if let summary = summary {
                // Header (Compact State)
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack {
                        Text("📊")
                            .font(.system(size: 20))
                        
                        Text("Hôm nay: ")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("\(Int(summary.totalCalories)) / \(Int(summary.targetCalories)) kcal")
                            .font(.headline)
                            .foregroundColor(summary.isGoalMet ? .green : .orange)
                        
                        Spacer()
                        
                        if summary.isGoalMet {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                        }
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                    .padding()
                }
                .buttonStyle(PlainButtonStyle())
                
                // Expanded State
                if isExpanded {
                    VStack(alignment: .leading, spacing: 16) {
                        Divider()
                        
                        // Macros
                        HStack(spacing: 12) {
                            MacroMiniBar(title: "P", value: summary.protein, target: (summary.targetCalories * 0.3) / 4, color: .blue)
                            MacroMiniBar(title: "C", value: summary.carbs, target: (summary.targetCalories * 0.4) / 4, color: .purple)
                            MacroMiniBar(title: "F", value: summary.fat, target: (summary.targetCalories * 0.3) / 9, color: .orange)
                        }
                        
                        // Insights
                        if !summary.insights.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(summary.insights) { insight in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: icon(for: insight.severity))
                                            .foregroundColor(color(for: insight.severity))
                                            .font(.caption)
                                            .padding(.top, 2)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(insight.message)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            
                                            Text(insight.suggestion)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                            .padding(.top, 4)
                        }
                        
                        // AI Summary
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.purple)
                                    .font(.caption)
                                Text("AI Nhận Xét")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.purple)
                            }
                            
                            Text(summary.aiComment)
                                .font(.subheadline)
                                .italic()
                                .foregroundColor(.primary)
                            
                            HStack(alignment: .top, spacing: 6) {
                                Text("👉")
                                    .font(.caption)
                                Text(summary.aiSuggestion)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                            .padding(.top, 4)
                        }
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            } else {
                // Skeleton
                HStack {
                    Text("📊 Hôm nay: ... kcal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    ProgressView()
                }
                .padding()
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        // Auto expand when insights arrive (summary loads async in background)
        .onChange(of: summary?.insights.count ?? 0) { oldValue, newValue in
            if newValue > 0 && !isExpanded {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded = true
                }
            }
        }
        .onAppear {
            if let sum = summary, !sum.insights.isEmpty {
                isExpanded = true
            }
        }
    }
    
    private func icon(for severity: DailyInsight.InsightSeverity) -> String {
        return severity == .high ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill"
    }
    
    private func color(for severity: DailyInsight.InsightSeverity) -> Color {
        switch severity {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
}

struct MacroMiniBar: View {
    let title: String
    let value: Double
    let target: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemGray5))
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: min(CGFloat(value / max(target, 1)) * geo.size.width, geo.size.width))
                }
            }
            .frame(height: 4)
            
            Text("\(Int(value))g")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
