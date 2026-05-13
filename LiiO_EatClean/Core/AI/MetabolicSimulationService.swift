import Foundation

enum MetabolicScenario {
    case perfectAdherencePlateau
    case poorAdherenceFakePlateau
    case waterRetentionSpike
    case rapidWeightLoss
    case cheatWeekendRecovery
    case muscleGainRecomp
}

struct SimulatedDay {
    let date: Date
    let caloriesIn: Double
    let weight: Double
    let adherence: Double
}

class MetabolicSimulationService {
    static let shared = MetabolicSimulationService()
    
    func generateScenario(_ scenario: MetabolicScenario, days: Int = 30) -> [SimulatedDay] {
        var daysData: [SimulatedDay] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var currentWeight = 80.0
        let targetCalories = 2000.0
        let maintenanceTDEE = 2500.0
        
        for i in 0..<days {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            var caloriesIn = targetCalories
            var weight = currentWeight
            var adherence = 1.0
            
            switch scenario {
            case .perfectAdherencePlateau:
                // User eats exactly at target, but weight stops moving after 14 days
                caloriesIn = targetCalories
                if i < 14 {
                    currentWeight += (caloriesIn - maintenanceTDEE) / 7700.0
                }
                weight = currentWeight
                adherence = 1.0
                
            case .poorAdherenceFakePlateau:
                // User eats over target, weight doesn't move, AI should detect poor adherence
                caloriesIn = targetCalories + 500
                weight = currentWeight
                adherence = 0.6
                
            case .waterRetentionSpike:
                // Random weight spikes despite good adherence
                caloriesIn = targetCalories
                let noise = Double.random(in: -0.5...1.5)
                weight = currentWeight + noise
                adherence = 1.0
                
            case .rapidWeightLoss:
                // Weight drops faster than expected
                caloriesIn = targetCalories - 300
                currentWeight -= 0.2
                weight = currentWeight
                adherence = 1.0
                
            case .cheatWeekendRecovery:
                // High cal weekend, low cal recovery
                let isWeekend = calendar.isDateInWeekend(date)
                caloriesIn = isWeekend ? targetCalories + 1200 : targetCalories - 200
                weight = currentWeight + (isWeekend ? 1.0 : -0.1)
                adherence = isWeekend ? 0.3 : 1.1
                
            case .muscleGainRecomp:
                // High protein, weight stable, calories at maintenance
                caloriesIn = maintenanceTDEE
                weight = currentWeight
                adherence = 1.0
            }
            
            daysData.append(SimulatedDay(date: date, caloriesIn: caloriesIn, weight: weight, adherence: adherence))
        }
        
        return daysData.reversed()
    }
}
