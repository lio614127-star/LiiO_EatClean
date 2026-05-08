import SwiftUI
import Charts

struct CalorieChartView: View {
    let data: [CalorieDailyTotal]
    let weeklyData: [WeeklyAggregate]
    let dailyTarget: Double
    let timeRange: TimeRange
    
    @State private var selectedDate: Date?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Lượng Calo nạp vào")
                .font(.headline)
            
            if data.isEmpty {
                emptyState
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
                                    Text("\(Int(item.averageCalories))")
                                        .font(.caption2.bold())
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color(.systemBackground))
                                        .cornerRadius(4)
                                        .shadow(radius: 2)
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
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                        .foregroundStyle(.red.opacity(0.5))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("Mục tiêu (\(Int(dailyTarget)))")
                                .font(.caption2)
                                .foregroundColor(.red.opacity(0.5))
                                .padding(.horizontal, 4)
                                .background(Color(.systemBackground).opacity(0.8))
                                .cornerRadius(4)
                        }
                }
                .chartYScale(domain: 0...max(3000, max(dailyTarget * 1.2, maxVal * 1.1)))
                .chartScrollableAxes(.horizontal)
                .chartXVisibleDomain(length: timeRange == .week ? 7 * 86400 : (timeRange == .month ? 7 * 86400 : 4 * 604800))
                .chartGesture { proxy in
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            if let date: Date = proxy.value(atX: value.location.x) {
                                if let snappedDate = data.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })?.date {
                                    if selectedDate == snappedDate {
                                        selectedDate = nil
                                    } else {
                                        selectedDate = snappedDate
                                    }
                                }
                            }
                        }
                }
                .chartXAxis {
                    if timeRange == .quarter {
                        AxisMarks(values: weeklyData.map { $0.startDate }) { value in
                            if let date = value.as(Date.self), let week = weeklyData.first(where: { $0.startDate == date }) {
                                AxisValueLabel {
                                    Text("W\(week.weekNumber)")
                                        .font(.system(size: 10))
                                }
                            }
                            AxisGridLine()
                        }
                    } else if timeRange == .week {
                        AxisMarks(values: data.map { $0.date }) { value in
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
                        AxisMarks(values: data.map { $0.date }) { value in
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
    
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis")
                .font(.largeTitle)
                .foregroundColor(Color(.systemGray3))
            
            let dataCount = timeRange == .quarter ? weeklyData.count : data.filter { $0.total > 0 }.count
            if dataCount == 0 {
                Text("Chưa có dữ liệu")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                let required = timeRange == .quarter ? 2 : 3
                if dataCount < required {
                    Text("Cần thêm \(required - dataCount) \(timeRange == .quarter ? "tuần" : "ngày") dữ liệu để hiển thị xu hướng")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                } else {
                    Text("Chưa có dữ liệu")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 250)
    }
}
