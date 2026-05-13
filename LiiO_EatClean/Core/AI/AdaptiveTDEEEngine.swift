import Foundation

struct MetabolicAnalysis {
    let baselineTDEE: Double // The TDEE at the start of the analysis
    let finalTDEE: Double    // The new calculated TDEE
    let adaptationScore: Double // 1.0 = baseline, < 1.0 = slowed, > 1.0 = faster
    let confidence: Double
}

class AdaptiveTDEEEngine {
    
    /// Calculate Adaptive TDEE based on intake and weight trend.
    /// Formula: TDEE = Avg Calories In + (Weight Change * 7700 / Days)
    static func calculateAdaptiveTDEE(
        currentTDEE: Double,
        logs: [SimulatedDay], // Using SimulatedDay for now
        weightTrend: Double, // kg change per week (negative = loss)
        adherenceScore: Double
    ) -> MetabolicAnalysis {
        guard logs.count >= 7 else {
            return MetabolicAnalysis(baselineTDEE: currentTDEE, finalTDEE: currentTDEE, adaptationScore: 1.0, confidence: 0.2)
        }
        
        let avgCaloriesIn = logs.map { $0.caloriesIn }.reduce(0, +) / Double(logs.count)
        
        // Convert weekly weight change to daily calorie surplus/deficit
        // 1kg fat ≈ 7700 kcal
        let dailyWeightBurn = (weightTrend * 7700.0) / 7.0
        
        // Estimated TDEE = What you ate - What you stored (or + What you burned from body)
        // If weightTrend is negative (loss), dailyWeightBurn is negative, meaning you burned extra from body.
        // TDEE = Intake - Deficit_from_weight_change
        let estimatedTDEE = avgCaloriesIn - dailyWeightBurn
        
        // EMA Smoothing (max ±40 kcal/day adjustment to prevent noise spikes)
        let alpha = 0.2 // Smoothing factor
        let smoothedTDEE = (estimatedTDEE * alpha) + (currentTDEE * (1.0 - alpha))
        
        // Limit the delta
        let delta = smoothedTDEE - currentTDEE
        let limitedDelta = max(-40.0, min(40.0, delta))
        let finalTDEE = currentTDEE + limitedDelta
        
        let adaptationScore = finalTDEE / currentTDEE
        
        return MetabolicAnalysis(
            baselineTDEE: currentTDEE,
            finalTDEE: finalTDEE,
            adaptationScore: adaptationScore,
            confidence: adherenceScore * (Double(logs.count) / 14.0)
        )
    }
}
