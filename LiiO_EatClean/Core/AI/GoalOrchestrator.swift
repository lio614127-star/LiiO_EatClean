import Foundation

struct GoalAdjustmentProposal {
    let newCalorieTarget: Double
    let newProteinTarget: Double
    let intervention: MetabolicIntervention
    let confidence: Double
}

class GoalOrchestrator {
    private let metabolicRepo: MetabolicRepositoryProtocol
    
    init(metabolicRepo: MetabolicRepositoryProtocol = MetabolicRepository()) {
        self.metabolicRepo = metabolicRepo
    }
    
    func generateProposal() async throws -> GoalAdjustmentProposal? {
        // 1. Fetch latest data
        guard let profile = try await metabolicRepo.fetchMetabolicProfile(),
              let latestGoal = try await metabolicRepo.fetchLatestGoal() else {
            return nil
        }
        
        // 2. Check Cooldown: If last goal was set recently, don't propose new one
        let calendar = Calendar.current
        let lastAppliedDate = latestGoal.effectiveFrom
        let daysSinceLastGoal = calendar.dateComponents([.day], from: lastAppliedDate, to: Date()).day ?? 0
        
        // Minimum 7 days between any AI-driven change
        if daysSinceLastGoal < 7 && latestGoal.source == "aiSuggestion" {
            return nil
        }
        
        // 3. Mock data for simulation (In real app, fetch from logs/weight entries)
        let simulation = MetabolicSimulationService.shared.generateScenario(.perfectAdherencePlateau, days: 30)
        
        // 3. Run Analysis Engines
        let adherence = AdherenceEngine.calculateAdherence(logs: simulation, calorieTarget: latestGoal.calorieTarget)
        
        let reliability = DataReliabilityAnalyzer.analyzeCalorieReliability(logs: simulation)
        
        let plateau = PlateauEngine.analyzePlateau(weightEntries: [], reliabilityScore: reliability.score)
        
        let metabolicAnalysis = AdaptiveTDEEEngine.calculateAdaptiveTDEE(
            currentTDEE: profile.adaptiveTDEE,
            logs: simulation,
            weightTrend: plateau.weeklyRate,
            adherenceScore: adherence.score
        )
        
        // 4. Determine Intervention
        let intervention = InterventionSeveritySystem.determineIntervention(
            analysis: metabolicAnalysis,
            plateau: plateau,
            adherence: adherence,
            currentTarget: latestGoal.calorieTarget
        )
        
        // 5. Finalize Proposal with Safety Floor (1200 kcal)
        let newCalorieTarget = max(1200, latestGoal.calorieTarget + intervention.adjustmentAmount)
        let newProteinTarget = newCalorieTarget * 0.3 / 4.0 // Maintain 30% Protein
        
        return GoalAdjustmentProposal(
            newCalorieTarget: newCalorieTarget,
            newProteinTarget: newProteinTarget,
            intervention: intervention,
            confidence: metabolicAnalysis.confidence
        )
    }
}
