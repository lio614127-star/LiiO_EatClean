import SwiftUI
import Charts

struct CalorieChartView: View {
    let data: [CalorieDailyTotal]
    let weeklyData: [WeeklyAggregate]
    let dailyTarget: Double
    let timeRange: TimeRange
    
    @State private var selectedDate: Date?
    
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
            Text("Lượng Calo nạp vào")
                .font(.headline)
            
            let currentCount = timeRange == .quarter ? weeklyData.count : data.filter { $0.total > 0 }.count
            let requiredCount = 1
            
            if currentCount < requiredCount {
                emptyState(currentCount: currentCount, requiredCount: requiredCount)
            } else {
                let maxVal = timeRange == .quarter 
                    ? (weeklyData.map { $0.averageCalories }.max() ?? 0)
                    : (data.map { $0.total }.max() ?? 0)
                    
                Chart {
                    if timeRange == .quarter {
                        ForEach(weeklyData) { item in
                            BarMark(
                                x: .value("Tuần", item.startDate, unit: .weekOfYear),
                                y: .value("Calo", item.averageCalories)
                            )
                            .foregroundStyle(item.averageCalories > dailyTarget ? Color.orange.gradient : Color.green.gradient)
                            .cornerRadius(4)
                            .annotation(position: .top) {
                                if let selected = selectedDate, Calendar.current.isDate(selected, inSameDayAs: item.startDate) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Tuần \(item.weekNumber)")
                                            .font(.caption2.bold())
                                        Text("TB: \(Int(item.averageCalories)) kcal")
                                            .font(.system(size: 8))
                                        Text("Tổng: \(Int(item.averageCalories * 7)) kcal")
                                            .font(.system(size: 8))
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(6)
                                    .shadow(color: .black.opacity(0.1), radius: 4)
                                }
                            }
                        }
                    } else {
                        ForEach(data) { item in
                            BarMark(
                                x: .value("Ngày", item.date, unit: .day),
                                y: .value("Calo", item.total)
                            )
                            .foregroundStyle(item.total > dailyTarget ? Color.orange.gradient : Color.green.gradient)
                            .cornerRadius(4)
                            .annotation(position: .top) {
                                if let selected = selectedDate, Calendar.current.isDate(selected, inSameDayAs: item.date) {
                                    Text("\(Int(item.total))")
                                        .font(.caption2.bold())
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color(.systemBackground))
                                        .cornerRadius(4)
                                        .shadow(radius: 2)
                                }
                            }
                        }
                    }
                    
                    RuleMark(y: .value("Mục tiêu", dailyTarget))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundStyle(.red.opacity(0.4))
                        .annotation(position: .overlay, alignment: .topTrailing) {
                            Text("\(Int(dailyTarget)) kcal")
                                .font(.system(size: 8))
                                .foregroundColor(.red.opacity(0.6))
                                .padding(.horizontal, 4)
                                .offset(y: -10)
                        }
                }
                .chartYScale(domain: 0...max(3000, max(dailyTarget * 1.2, maxVal * 1.1)))
                .chartXScale(domain: xAxisDomain)
                .chartScrollableAxes(.horizontal)
                .chartXVisibleDomain(length: timeRange == .week ? 7 * 86400 : (timeRange == .month ? 14 * 86400 : 7 * 604800))
                .chartXSelection(value: $selectedDate)
                .chartXAxis {
                    if timeRange == .quarter {
                        AxisMarks(values: .stride(by: .weekOfYear, count: 1)) { value in
                            if let date = value.as(Date.self), let week = weeklyData.first(where: { Calendar.current.isDate($0.startDate, equalTo: date, toGranularity: .weekOfYear) }) {
                                AxisValueLabel {
                                    Text("T\(week.weekNumber)")
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
                                    AxisGridLine()
                                }
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        if let count = value.as(Double.self) {
                            AxisValueLabel("\(Int(count))")
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
            Image(systemName: "chart.bar.xaxis")
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
