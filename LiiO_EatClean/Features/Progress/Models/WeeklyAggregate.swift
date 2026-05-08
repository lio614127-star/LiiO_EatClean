import Foundation

struct WeeklyAggregate: Identifiable {
    let id = UUID()
    let weekNumber: Int
    let averageCalories: Double
    let lastWeight: Double?
    let startDate: Date
    let endDate: Date
}
