import SwiftUI
import Charts

struct WeightChartView: View {
    let data: [WeightEntryModel]
    let weeklyData: [WeeklyAggregate]
    let timeRange: TimeRange
    
    // Calculate Y-axis domain dynamically to avoid chart starting at 0
    private var yAxisDomain: ClosedRange<Double> {
        let weights = timeRange == .quarter 
            ? weeklyData.compactMap { $0.lastWeight }
            : data.map { $0.weight }
            
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
        let daysToSubtract: Int
        switch timeRange {
        case .week: daysToSubtract = 6
        case .month: daysToSubtract = 29
        case .quarter: daysToSubtract = 89
        }
        let start = calendar.date(byAdding: .day, value: -daysToSubtract, to: today) ?? today
        let end = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        return start...end
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Xu hướng cân nặng")
                .font(.headline)
            
            let currentCount = timeRange == .quarter ? weeklyData.filter { $0.lastWeight != nil }.count : data.count
            let requiredCount = 1
            
            if currentCount < requiredCount {
                emptyState(currentCount: currentCount, requiredCount: requiredCount)
            } else {
                Chart {
                    if timeRange == .quarter {
                        ForEach(weeklyData) { entry in
                            if let weight = entry.lastWeight {
                                AreaMark(
                                    x: .value("Tuần", entry.startDate, unit: .weekOfYear),
                                    yStart: .value("Min", yAxisDomain.lowerBound),
                                    yEnd: .value("Cân nặng", weight)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(LinearGradient(colors: [.cyan.opacity(0.3), .teal.opacity(0.0)], startPoint: .top, endPoint: .bottom))
                                
                                LineMark(
                                    x: .value("Tuần", entry.startDate, unit: .weekOfYear),
                                    y: .value("Cân nặng", weight)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(LinearGradient(colors: [.cyan, .teal], startPoint: .top, endPoint: .bottom))
                                .lineStyle(StrokeStyle(lineWidth: 2))
                            }
                        }
                    } else {
                        ForEach(data) { entry in
                            let alignedDate = Calendar.current.startOfDay(for: entry.date)
                            AreaMark(
                                x: .value("Ngày", alignedDate, unit: .day),
                                yStart: .value("Min", yAxisDomain.lowerBound),
                                yEnd: .value("Cân nặng", entry.weight)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(LinearGradient(colors: [.cyan.opacity(0.3), .teal.opacity(0.0)], startPoint: .top, endPoint: .bottom))
                            
                            LineMark(
                                x: .value("Ngày", alignedDate, unit: .day),
                                y: .value("Cân nặng", entry.weight)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(LinearGradient(colors: [.cyan, .teal], startPoint: .top, endPoint: .bottom))
                            .lineStyle(StrokeStyle(lineWidth: timeRange == .week ? 3 : 2))
                            
                            if timeRange == .week {
                                PointMark(
                                    x: .value("Ngày", alignedDate, unit: .day),
                                    y: .value("Cân nặng", entry.weight)
                                )
                                .foregroundStyle(Color.cyan)
                                .symbolSize(40)
                            }
                        }
                    }
                }
                .chartYScale(domain: yAxisDomain)
                .chartXScale(domain: xAxisDomain)
                .chartScrollableAxes(.horizontal)
                .chartXVisibleDomain(length: timeRange == .week ? 7 * 86400 : (timeRange == .month ? 30 * 86400 : 13 * 604800))
                .chartXAxis {
                    if timeRange == .quarter {
                        AxisMarks(values: .stride(by: .weekOfYear, count: 1)) { value in
                            if let date = value.as(Date.self), let week = weeklyData.first(where: { Calendar.current.isDate($0.startDate, equalTo: date, toGranularity: .weekOfYear) }) {
                                AxisValueLabel {
                                    Text("W\(week.weekNumber)")
                                        .font(.system(size: 10))
                                }
                            }
                            AxisGridLine()
                        }
                    } else if timeRange == .week {
                        AxisMarks(values: .stride(by: .day, count: 1)) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    let weekday = Calendar.current.component(.weekday, from: date)
                                    let label = weekday == 1 ? "CN" : "T\(weekday)"
                                    Text(label)
                                        .font(.system(size: 10))
                                }
                            }
                            AxisGridLine()
                        }
                    } else {
                        // Month mode: Smart skipping
                        AxisMarks(values: .stride(by: .day, count: 1)) { value in
                            if let date = value.as(Date.self) {
                                let day = Calendar.current.component(.day, from: date)
                                if [1, 5, 10, 15, 20, 25, 30].contains(day) {
                                    AxisValueLabel {
                                        Text("\(day)")
                                            .font(.system(size: 10))
                                    }
                                }
                            }
                            AxisGridLine()
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
    
    private func emptyState(currentCount: Int, requiredCount: Int) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.largeTitle)
                .foregroundColor(Color(.systemGray3))
            
            if currentCount == 0 {
                Text("Chưa có dữ liệu")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("Cần thêm \(requiredCount - currentCount) \(timeRange == .quarter ? "tuần" : "ngày") dữ liệu để hiển thị xu hướng")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 250)
    }
}
