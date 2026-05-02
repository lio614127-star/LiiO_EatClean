import SwiftUI
import Charts

struct CalorieChartView: View {
    let data: [CalorieDailyTotal]
    let dailyTarget: Double
    let timeRange: TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Lượng Calo nạp vào")
                .font(.headline)
            
            if data.isEmpty {
                emptyState
            } else {
                Chart {
                    ForEach(data) { item in
                        BarMark(
                            x: .value("Ngày", item.date, unit: .day),
                            y: .value("Calo", item.total)
                        )
                        .foregroundStyle(item.total > dailyTarget ? Color.orange.gradient : Color.green.gradient)
                        .cornerRadius(4)
                    }
                    
                    RuleMark(y: .value("Mục tiêu", dailyTarget))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                        .foregroundStyle(.red)
                        .annotation(position: .top, alignment: .trailing) {
                            Text("Mục tiêu (\(Int(dailyTarget)))")
                                .font(.caption2)
                                .foregroundColor(.red)
                                .padding(.horizontal, 4)
                                .background(Color(.systemBackground).opacity(0.8))
                                .cornerRadius(4)
                        }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: timeRange == .week ? 1 : 5)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel(format: .dateTime.day().month(.defaultDigits))
                        }
                        AxisGridLine()
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
            
            Text("Chưa có dữ liệu")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 250)
    }
}
