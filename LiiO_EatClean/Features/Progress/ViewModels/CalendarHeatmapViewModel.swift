import Foundation
import Observation

@Observable
class CalendarHeatmapViewModel {
    var currentMonth: Date
    var adherenceSnapshots: [Date: DailyAdherenceSnapshotModel] = [:]
    var isLoading = false
    
    private let snapshotService: DailyAdherenceSnapshotService
    private let calendar = Calendar.current
    
    init(
        currentMonth: Date = Date(),
        snapshotService: DailyAdherenceSnapshotService = .shared
    ) {
        self.currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) ?? Date()
        self.snapshotService = snapshotService
    }
    
    func loadMonthData() async {
        isLoading = true
        defer { isLoading = false }
        
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        let startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let endDate = calendar.date(byAdding: .day, value: range.count - 1, to: startDate)!
        
        do {
            let snapshots = try await snapshotService.fetchSnapshots(from: startDate, to: endDate)
            var newSnapshots: [Date: DailyAdherenceSnapshotModel] = [:]
            for snapshot in snapshots {
                let day = calendar.startOfDay(for: snapshot.date)
                newSnapshots[day] = snapshot
            }
            self.adherenceSnapshots = newSnapshots
        } catch {
            print("Error loading heatmap data: \(error)")
        }
    }
    
    func changeMonth(by value: Int) async {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            self.currentMonth = newMonth
            await loadMonthData()
        }
    }
    
    func resetToToday() async {
        let today = Date()
        self.currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today
        await loadMonthData()
    }
    
    func daysInMonth() -> [Date?] {
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let weekday = calendar.component(.weekday, from: firstDayOfMonth)
        
        var days: [Date?] = Array(repeating: nil, count: weekday - 1)
        
        for day in 1...range.count {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    func adherenceColor(for score: Double) -> String {
        switch score {
        case 90...100: return "Excellent"
        case 75..<90: return "Good"
        case 60..<75: return "Fair"
        case 40..<60: return "Poor"
        case 0.1..<40: return "Critical"
        default: return "NoData"
        }
    }
}
