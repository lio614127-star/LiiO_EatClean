import Foundation

enum PlateauStatus {
    case moving
    case stalling
    case stagnant
    case rapid
}

struct PlateauAnalysis {
    let status: PlateauStatus
    let weeklyRate: Double // kg per week
    let confidence: Double
    let message: String
}

class PlateauEngine {
    
    static func analyzePlateau(
        weightEntries: [WeightEntryModel],
        reliabilityScore: Double
    ) -> PlateauAnalysis {
        guard weightEntries.count >= 7 else {
            return PlateauAnalysis(status: .moving, weeklyRate: 0, confidence: 0.1, message: "Cần thêm dữ liệu cân nặng để phân tích xu hướng.")
        }
        
        // Calculate 7-day rolling averages
        let sortedEntries = weightEntries.sorted(by: { $0.date < $1.date })
        let last7Days = Array(sortedEntries.suffix(7))
        let previous7Days = Array(sortedEntries.dropLast(7).suffix(7))
        
        guard previous7Days.count >= 3 else {
            return PlateauAnalysis(status: .moving, weeklyRate: 0, confidence: 0.2, message: "Đang thu thập dữ liệu cơ sở.")
        }
        
        let currentAvg = last7Days.map { $0.weight }.reduce(0, +) / Double(last7Days.count)
        let prevAvg = previous7Days.map { $0.weight }.reduce(0, +) / Double(previous7Days.count)
        
        let weeklyRate = currentAvg - prevAvg
        
        let status: PlateauStatus
        let message: String
        
        if abs(weeklyRate) < 0.1 {
            status = .stagnant
            message = "Cân nặng chững hoàn toàn trong tuần qua."
        } else if abs(weeklyRate) < 0.3 {
            status = .stalling
            message = "Cân nặng đang có dấu hiệu chững lại."
        } else if weeklyRate < -1.0 {
            status = .rapid
            message = "Cân nặng đang giảm rất nhanh."
        } else {
            status = .moving
            message = "Cân nặng đang thay đổi đúng theo nhịp độ."
        }
        
        return PlateauAnalysis(
            status: status,
            weeklyRate: weeklyRate,
            confidence: reliabilityScore,
            message: message
        )
    }
}
