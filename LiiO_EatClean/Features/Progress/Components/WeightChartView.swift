import SwiftUI
import Charts

struct WeightChartView: View {
    let data: [WeightEntryModel]
    let weeklyData: [WeeklyAggregate]
    let monthlyData: [MonthlyAggregate]
    let timeRange: TimeRange
    let startDate: Date
    let endDate: Date
    
    @State private var selectedDate: Date?
    
    // Calculate Y-axis domain dynamically to avoid chart starting at 0
    private var yAxisDomain: ClosedRange<Double> {
        let weights = !monthlyData.isEmpty
            ? monthlyData.compactMap { $0.lastWeight }
            : (!weeklyData.isEmpty ? weeklyData.compactMap { $0.lastWeight } : data.map { $0.weight })
            
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
        return startDate...endDate
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if selectedDate == nil {
                HStack(alignment: .firstTextBaseline) {
                    Text("Xu hướng cân nặng")
                        .font(.headline)
                    
                    Spacer()
                    
                    let trend = trendInfo
                    HStack(spacing: 4) {
                        Image(systemName: trend.icon)
                        Text("\(trend.text) / \(timeRangeLabel)")
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(trend.color)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                Color.clear.frame(height: 24)
            }
            
            let hasData = !monthlyData.isEmpty || !weeklyData.isEmpty || !data.isEmpty
            
            ZStack {
                Chart {
                    chartMarks
                }
                .chartYScale(domain: yAxisDomain)
                .chartXScale(domain: xAxisDomain)
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        ZStack(alignment: .top) {
                            // Interaction Area
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture { location in
                                    updateSelection(at: location, proxy: proxy, isTap: true)
                                }
                                .gesture(
                                    // 👆 Long Press (0.5s) to start selecting/dragging
                                    LongPressGesture(minimumDuration: 0.5)
                                        .sequenced(before: DragGesture(minimumDistance: 0))
                                        .onChanged { value in
                                            switch value {
                                            case .second(true, let drag):
                                                if let drag = drag {
                                                    updateSelection(at: drag.location, proxy: proxy, isTap: false)
                                                }
                                            default: break
                                            }
                                        }
                                )
                            
                            // 🌟 Smart Tooltip & Indicator
                            if let selected = selectedDate {
                                let selectionData = getSelectionData(for: selected)
                                if let xPos = proxy.position(forX: selected) {
                                    let chartWidth = geometry.size.width
                                    let tooltipWidth: CGFloat = 110
                                    
                                    // 🎯 Calculate Offset dynamically using the next unit's position
                                    let cellWidth: CGFloat = {
                                        let calendar = Calendar.current
                                        let nextUnit: Calendar.Component = !monthlyData.isEmpty ? .month : (!weeklyData.isEmpty ? .weekOfYear : .day)
                                        if let nextDate = calendar.date(byAdding: nextUnit, value: 1, to: selected),
                                           let nextX = proxy.position(forX: nextDate) {
                                            return nextX - xPos
                                        }
                                        // Fallback if next unit is off-chart
                                        if let prevDate = calendar.date(byAdding: nextUnit, value: -1, to: selected),
                                           let prevX = proxy.position(forX: prevDate) {
                                            return xPos - prevX
                                        }
                                        return chartWidth / CGFloat(max(1, !monthlyData.isEmpty ? monthlyData.count : (!weeklyData.isEmpty ? weeklyData.count : 7)))
                                    }()
                                    let centeredX = xPos + (cellWidth / 2)
                                    
                                    // Calculate clamped Tooltip X
                                    let halfWidth = tooltipWidth / 2
                                    let clampedX = max(halfWidth, min(chartWidth - halfWidth, centeredX))
                                    
                                    // Vertical Indicator Line (centered on point)
                                    if let yPos = proxy.position(forY: selectionData.value) {
                                        Path { path in
                                            path.move(to: CGPoint(x: centeredX, y: 0))
                                            path.addLine(to: CGPoint(x: centeredX, y: yPos))
                                        }
                                        .stroke(Color.green.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                                        
                                        // Header Tooltip Box
                                        VStack(spacing: 0) {
                                            VStack(spacing: 2) {
                                                Text(selectionData.dateString)
                                                    .font(.system(size: 10, weight: .medium))
                                                    .foregroundColor(.secondary)
                                                Text(String(format: "%.1f kg", selectionData.value))
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(.primary)
                                            }
                                            .frame(width: tooltipWidth)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color(.systemBackground))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(Color.green, lineWidth: 1.5)
                                                    )
                                                    .shadow(color: .black.opacity(0.12), radius: 6)
                                            )
                                        }
                                        .position(x: clampedX, y: -25)
                                    }
                                }
                            }
                        }
                    }
                }
                .chartXAxis {
                    if !monthlyData.isEmpty {
                        AxisMarks(values: .stride(by: .month, count: 1)) { value in
                            AxisValueLabel(format: .dateTime.month(.abbreviated).year(.twoDigits))
                            AxisGridLine()
                        }
                    } else if !weeklyData.isEmpty {
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
                        AxisMarks(values: .stride(by: .day, count: 1)) { value in
                            if let date = value.as(Date.self) {
                                let day = Calendar.current.component(.day, from: date)
                                let month = Calendar.current.component(.month, from: date)
                                let year = Calendar.current.component(.year, from: date) % 100
                                
                                if day == 1 {
                                    AxisValueLabel(verticalSpacing: 4) {
                                        VStack(alignment: .center, spacing: 2) {
                                            Text("\(day)")
                                                .font(.system(size: 10))
                                            Text("\(month)/\(year)")
                                                .font(.system(size: 8, weight: .semibold))
                                                .foregroundColor(.green)
                                        }
                                    }
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                                        .foregroundStyle(.secondary.opacity(0.3))
                                } else if [5, 10, 15, 20, 25, 30].contains(day) {
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
                    AxisMarks(position: .trailing) { value in
                        AxisGridLine()
                        if let count = value.as(Double.self) {
                            AxisValueLabel(String(format: "%.0f", count))
                        }
                    }
                }
                .frame(height: 220)
                .opacity(hasData ? 1.0 : 0.3)
                
                if !hasData {
                    Text("Chưa có dữ liệu")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color(.systemBackground)).shadow(radius: 2))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    @ChartContentBuilder
    private var chartMarks: some ChartContent {
        if !monthlyData.isEmpty {
            ForEach(monthlyData) { entry in
                if let weight = entry.lastWeight {
                    AreaMark(
                        x: .value("Tháng", entry.startDate, unit: .month),
                        yStart: .value("Min", yAxisDomain.lowerBound),
                        yEnd: .value("Cân nặng", weight)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(LinearGradient(colors: [.cyan.opacity(0.3), .teal.opacity(0.0)], startPoint: .top, endPoint: .bottom))
                    
                    LineMark(
                        x: .value("Tháng", entry.startDate, unit: .month),
                        y: .value("Cân nặng", weight)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(LinearGradient(colors: [.cyan, .teal], startPoint: .top, endPoint: .bottom))
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
            }
        } else if !weeklyData.isEmpty {
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
            }
        }
    }
    
    private var trendInfo: (delta: Double, text: String, color: Color, icon: String) {
        let weights = !monthlyData.isEmpty 
            ? monthlyData.compactMap { $0.lastWeight }
            : (!weeklyData.isEmpty ? weeklyData.compactMap { $0.lastWeight } : data.map { $0.weight })
        
        guard let first = weights.first, let last = weights.last else {
            return (0, "--", .secondary, "minus")
        }
        
        let delta = last - first
        let text = String(format: "%.1fkg", abs(delta))
        let color: Color = delta < 0 ? .green : (delta > 0 ? .red : .secondary)
        let icon = delta < 0 ? "arrow.down.right" : (delta > 0 ? "arrow.up.right" : "minus")
        
        return (delta, text, color, icon)
    }
    
    private var timeRangeLabel: String {
        switch timeRange {
        case .week: return "7N"
        case .month: return "30N"
        case .quarter: return "3T"
        case .custom:
            let days = Calendar.current.dateComponents([.day], from: xAxisDomain.lowerBound, to: xAxisDomain.upperBound).day ?? 0
            return "\(days)N"
        }
    }
    
    private func updateSelection(at location: CGPoint, proxy: ChartProxy, isTap: Bool) {
        if let date: Date = proxy.value(atX: location.x) {
            let calendar = Calendar.current
            let matchedDate: Date?
            if !monthlyData.isEmpty {
                matchedDate = monthlyData.first { calendar.isDate($0.startDate, equalTo: date, toGranularity: .month) }?.startDate
            } else if !weeklyData.isEmpty {
                matchedDate = weeklyData.first { calendar.isDate($0.startDate, equalTo: date, toGranularity: .weekOfYear) }?.startDate
            } else {
                matchedDate = data.first { calendar.isDate($0.date, inSameDayAs: date) }?.date
            }
            
            if let matched = matchedDate {
                withAnimation(.easeInOut(duration: 0.15)) {
                    if isTap && selectedDate != nil && calendar.isDate(selectedDate!, inSameDayAs: matched) {
                        selectedDate = nil
                    } else {
                        selectedDate = matched
                    }
                }
            }
        }
    }
    
    private func getSelectionData(for date: Date) -> (value: Double, dateString: String) {
        let calendar = Calendar.current
        if !monthlyData.isEmpty, let item = monthlyData.first(where: { calendar.isDate($0.startDate, equalTo: date, toGranularity: .month) }) {
            return (item.lastWeight ?? 0, item.startDate.formatted(.dateTime.month().year()))
        } else if !weeklyData.isEmpty, let item = weeklyData.first(where: { calendar.isDate($0.startDate, equalTo: date, toGranularity: .weekOfYear) }) {
            return (item.lastWeight ?? 0, "Tuần \(item.weekNumber)")
        } else if let item = data.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "vi_VN")
            formatter.dateFormat = "EEEE, d/M"
            return (item.weight, formatter.string(from: item.date))
        }
        return (0, "")
    }
}
