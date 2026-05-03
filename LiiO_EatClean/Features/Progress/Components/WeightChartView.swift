import SwiftUI
import Charts

struct WeightChartView: View {
    let data: [WeightEntryModel]
    let timeRange: TimeRange
    
    // Calculate Y-axis domain dynamically to avoid chart starting at 0
    private var yAxisDomain: ClosedRange<Double> {
        let weights = data.map { $0.weight }
        guard let min = weights.min(), let max = weights.max() else {
            return 40.0...100.0 // Default fallback
        }
        
        let padding = (max - min) * 0.2
        let lower = Swift.max(0, min - (padding == 0 ? 5 : padding))
        let upper = max + (padding == 0 ? 5 : padding)
        return lower...upper
    }
    
    // Calculate X-axis domain based on timeRange
    private var xAxisDomain: ClosedRange<Date> {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let daysToSubtract = timeRange == .week ? 6 : 29
        let start = calendar.date(byAdding: .day, value: -daysToSubtract, to: today) ?? today
        // Add 1 day of padding to the end to avoid clipping annotations
        let end = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        return start...end
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Xu hướng cân nặng")
                .font(.headline)
            
            if data.isEmpty {
                emptyState
            } else {
                Chart {
                    ForEach(data) { entry in
                        LineMark(
                            x: .value("Ngày", entry.date, unit: .day),
                            y: .value("Cân nặng", entry.weight)
                        )
                        .foregroundStyle(Color.blue.gradient)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        
                        PointMark(
                            x: .value("Ngày", entry.date, unit: .day),
                            y: .value("Cân nặng", entry.weight)
                        )
                        .foregroundStyle(Color.blue)
                        .symbolSize(100)
                        .annotation(position: .top) {
                            Text(String(format: "%.1f", entry.weight))
                                .font(.caption2.bold())
                                .foregroundColor(.blue)
                        }
                    }
                }
                .chartYScale(domain: yAxisDomain)
                .chartXScale(domain: xAxisDomain)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: timeRange == .week ? 1 : 7)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date, format: .dateTime.day().month(.defaultDigits))
                                    .font(.caption2)
                            }
                            AxisGridLine()
                            AxisTick()
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing) { value in
                        AxisGridLine()
                        if let count = value.as(Double.self) {
                            AxisValueLabel(String(format: "%.0f", count))
                        }
                    }
                }
                .frame(height: 250)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.largeTitle)
                .foregroundColor(Color(.systemGray3))
            
            Text("Chưa có dữ liệu")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 250)
    }
}
