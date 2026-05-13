import Foundation

struct ReliabilityScore {
    let score: Double // 0.0 to 1.0
    let reasons: [String]
}

class DataReliabilityAnalyzer {
    
    static func analyzeWeightReliability(
        entry: WeightEntryModel,
        previousEntries: [WeightEntryModel]
    ) -> ReliabilityScore {
        var score = 1.0
        var reasons: [String] = []
        
        // 1. Time of day check (Consistency is key)
        let hour = Calendar.current.component(.hour, from: entry.date)
        if hour < 5 || hour > 10 {
            score -= 0.3
            reasons.append("Cân nặng không được đo vào buổi sáng sớm (5am-10am)")
        }
        
        // 2. Variance spike check
        if let last = previousEntries.last {
            let diff = abs(entry.weight - last.weight)
            if diff > 2.0 {
                score -= 0.5
                reasons.append("Cân nặng thay đổi đột ngột (>2kg) trong thời gian ngắn")
            }
        }
        
        // 3. Frequency check
        let recent = previousEntries.filter { 
            Calendar.current.dateComponents([.day], from: $0.date, to: entry.date).day ?? 0 <= 7 
        }
        if recent.count < 3 {
            score -= 0.2
            reasons.append("Dữ liệu cân nặng trong tuần quá thưa thớt")
        }
        
        return ReliabilityScore(score: max(0.0, score), reasons: reasons)
    }
    
    static func analyzeCalorieReliability(
        logs: [SimulatedDay] // Using SimulatedDay for now, but will use real logs later
    ) -> ReliabilityScore {
        var score = 1.0
        var reasons: [String] = []
        
        // 1. Logging consistency
        let missingDays = logs.filter { $0.caloriesIn == 0 }.count
        if missingDays > 0 {
            score -= Double(missingDays) * 0.2
            reasons.append("Thiếu dữ liệu log món ăn trong \(missingDays) ngày")
        }
        
        // 2. Adherence variance
        let adherenceAvg = logs.map { $0.adherence }.reduce(0, +) / Double(logs.count)
        if adherenceAvg < 0.7 {
            score -= 0.4
            reasons.append("Tính tuân thủ trung bình thấp (\(Int(adherenceAvg * 100))%)")
        }
        
        return ReliabilityScore(score: max(0.0, score), reasons: reasons)
    }
}
