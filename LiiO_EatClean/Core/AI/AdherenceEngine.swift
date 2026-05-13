import Foundation

struct AdherenceResult {
    let score: Double // 0.0 to 1.0
    let calorieAdherence: Double
    let proteinAdherence: Double
    let consistencyScore: Double
    let summary: String
}

class AdherenceEngine {
    
    static func calculateAdherence(
        logs: [SimulatedDay],
        calorieTarget: Double,
        proteinTarget: Double? = nil
    ) -> AdherenceResult {
        guard !logs.isEmpty else {
            return AdherenceResult(score: 0, calorieAdherence: 0, proteinAdherence: 0, consistencyScore: 0, summary: "Không có dữ liệu")
        }
        
        // 1. Calorie Adherence (Tolerance-based)
        // ±100 kcal or ±5% is considered perfect (1.0)
        let calAdherences = logs.map { day -> Double in
            let diff = abs(day.caloriesIn - calorieTarget)
            let tolerance = max(100.0, calorieTarget * 0.05)
            if diff <= tolerance { return 1.0 }
            let penalty = (diff - tolerance) / calorieTarget
            return max(0.0, 1.0 - (penalty * 2.0))
        }
        let avgCalAdherence = calAdherences.reduce(0, +) / Double(logs.count)
        
        // 2. Consistency Score (Logging density)
        let loggedDays = logs.filter { $0.caloriesIn > 0 }.count
        let consistency = Double(loggedDays) / Double(logs.count)
        
        // 3. Protein Adherence (If provided)
        // Placeholder for now
        let avgProteinAdherence = 1.0
        
        // Weighted Total
        let totalScore = (avgCalAdherence * 0.4) + (consistency * 0.4) + (avgProteinAdherence * 0.2)
        
        let summary: String
        if totalScore > 0.85 {
            summary = "Tính tuân thủ tuyệt vời. Dữ liệu rất đáng tin cậy."
        } else if totalScore > 0.7 {
            summary = "Tính tuân thủ khá tốt. Có thể thực hiện điều chỉnh mục tiêu."
        } else {
            summary = "Tính tuân thủ thấp. Cần tập trung vào việc log đầy đủ trước khi đổi mục tiêu."
        }
        
        return AdherenceResult(
            score: totalScore,
            calorieAdherence: avgCalAdherence,
            proteinAdherence: avgProteinAdherence,
            consistencyScore: consistency,
            summary: summary
        )
    }
}
