import Foundation

enum InterventionSeverity: String, Codable {
    case soft = "SOFT"
    case medium = "MEDIUM"
    case hard = "HARD"
    case recovery = "RECOVERY"
    case dietBreak = "DIET_BREAK"
    case maintenance = "MAINTENANCE"
}

enum MetabolicInterventionCategory: String, Codable {
    case plateauBreaker = "PLATEAU_BREAKER"
    case metabolicAdaptation = "METABOLIC_ADAPTATION"
    case adherenceRecovery = "ADHERENCE_RECOVERY"
    case aggressiveProgress = "AGGRESSIVE_PROGRESS"
    case maintenanceAnchor = "MAINTENANCE_ANCHOR"
}

struct MetabolicIntervention {
    let severity: InterventionSeverity
    let category: MetabolicInterventionCategory
    let adjustmentAmount: Double // This will now be calculated dynamically
    let reason: String
    let cooldownDays: Int
}

class InterventionSeveritySystem {
    
    static func determineIntervention(
        analysis: MetabolicAnalysis,
        plateau: PlateauAnalysis,
        adherence: AdherenceResult,
        currentTarget: Double
    ) -> MetabolicIntervention {
        
        // 1. Check for poor adherence (Safety first)
        if adherence.score < 0.6 {
            return MetabolicIntervention(
                severity: .recovery,
                category: .adherenceRecovery,
                adjustmentAmount: 0,
                reason: "Dữ liệu log không đầy đủ hoặc tính tuân thủ thấp. Hãy tập trung vào việc log món ăn chính xác trong 7 ngày tới.",
                cooldownDays: 7
            )
        }
        
        // Calculate the dynamic adjustment needed to maintain the current deficit
        // If TDEE dropped from 2500 to 2400, and target was 2000 (500 deficit),
        // new target should be 2400 - 500 = 1900. Adjustment = -100.
        let tdeeDelta = analysis.finalTDEE - analysis.baselineTDEE
        let suggestedAdjustment = tdeeDelta
        
        // 2. Check for Plateau (Aggressive adjustment)
        if plateau.status == .stagnant && analysis.adaptationScore < 0.99 {
            return MetabolicIntervention(
                severity: .medium,
                category: .plateauBreaker,
                adjustmentAmount: min(-50, suggestedAdjustment), // At least -50
                reason: "Cân nặng đã chững 14 ngày và chuyển hóa đang thích nghi. Điều chỉnh calo dựa trên tốc độ đốt cháy thực tế (\(Int(analysis.finalTDEE)) kcal).",
                cooldownDays: 14
            )
        }
        
        // 3. Normal Adaptation
        if analysis.adaptationScore < 0.98 {
            return MetabolicIntervention(
                severity: .soft,
                category: .metabolicAdaptation,
                adjustmentAmount: suggestedAdjustment,
                reason: "Cơ thể bạn đang thích nghi với mức calo hiện tại. Điều chỉnh nhẹ để duy trì tốc độ giảm.",
                cooldownDays: 10
            )
        }
        
        // 4. Maintenance
        return MetabolicIntervention(
            severity: .maintenance,
            category: .maintenanceAnchor,
            adjustmentAmount: 0,
            reason: "Mọi thứ đang diễn ra rất tốt. Hãy tiếp tục duy trì mức hiện tại.",
            cooldownDays: 7
        )
    }
}
