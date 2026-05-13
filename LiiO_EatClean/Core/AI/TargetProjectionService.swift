import Foundation

struct DailyTargetProjection: Identifiable, Codable {
    var id: String { dateString }
    let date: Date
    let dateString: String
    let calorieTarget: Double
    let proteinTarget: Double
    let carbTarget: Double
    let fatTarget: Double
    let sourceGoalId: UUID
}

class TargetProjectionService {
    static let shared = TargetProjectionService()
    
    private var cache: [String: DailyTargetProjection] = [:]
    
    func getProjection(for date: Date) -> DailyTargetProjection? {
        let key = formatDate(date)
        return cache[key]
    }
    
    func generateProjection(history: [GoalHistoryModel], forDays: Int = 90) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        for i in 0..<forDays {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let key = formatDate(date)
            
            // Find the goal history entry that was active on this date
            // effectiveFrom <= date AND (effectiveTo == nil OR effectiveTo >= date)
            if let activeGoal = history.first(where: { goal in
                let start = calendar.startOfDay(for: goal.effectiveFrom)
                let end = goal.effectiveTo.map { calendar.startOfDay(for: $0) }
                
                return start <= date && (end == nil || end! >= date)
            }) {
                cache[key] = DailyTargetProjection(
                    date: date,
                    dateString: key,
                    calorieTarget: activeGoal.calorieTarget,
                    proteinTarget: activeGoal.proteinTarget,
                    carbTarget: activeGoal.carbTarget,
                    fatTarget: activeGoal.fatTarget,
                    sourceGoalId: activeGoal.id
                )
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    func clearCache() {
        cache.removeAll()
    }
}
