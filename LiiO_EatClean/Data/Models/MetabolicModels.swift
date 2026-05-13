import Foundation

struct MetabolicProfileModel: Identifiable, Codable {
    let id: UUID
    var estimatedBMR: Double
    var estimatedTDEE: Double
    var adaptiveTDEE: Double
    var metabolicAdaptationScore: Double
    var lastCalculatedAt: Date
    var confidenceScore: Double
    var onboardingSource: String
    var calculationVersion: Int
    
    init(
        id: UUID = UUID(),
        estimatedBMR: Double = 0.0,
        estimatedTDEE: Double = 0.0,
        adaptiveTDEE: Double = 0.0,
        metabolicAdaptationScore: Double = 0.0,
        lastCalculatedAt: Date = Date(),
        confidenceScore: Double = 0.0,
        onboardingSource: String = "manual",
        calculationVersion: Int = 1
    ) {
        self.id = id
        self.estimatedBMR = estimatedBMR
        self.estimatedTDEE = estimatedTDEE
        self.adaptiveTDEE = adaptiveTDEE
        self.metabolicAdaptationScore = metabolicAdaptationScore
        self.lastCalculatedAt = lastCalculatedAt
        self.confidenceScore = confidenceScore
        self.onboardingSource = onboardingSource
        self.calculationVersion = calculationVersion
    }
}

struct GoalHistoryModel: Identifiable, Codable {
    let id: UUID
    var createdAt: Date
    var calorieTarget: Double
    var proteinTarget: Double
    var carbTarget: Double
    var fatTarget: Double
    var weight: Double
    var rollingWeightAvg7d: Double
    var rollingWeightAvg14d: Double
    var estimatedTDEE: Double
    var adaptiveTDEE: Double
    var adherenceScore: Double
    var confidenceScore: Double
    var interventionType: String // SOFT, MEDIUM, HARD, RECOVERY, DIET_BREAK, MAINTENANCE
    var interventionCategory: String // ADAPTATION, RECOVERY, MAINTENANCE, etc.
    var reason: String
    var source: String // onboarding, manual, aiSuggestion, aiAutoAdjust
    var effectiveFrom: Date
    var effectiveTo: Date?
    var version: Int
    
    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        calorieTarget: Double = 0.0,
        proteinTarget: Double = 0.0,
        carbTarget: Double = 0.0,
        fatTarget: Double = 0.0,
        weight: Double = 0.0,
        rollingWeightAvg7d: Double = 0.0,
        rollingWeightAvg14d: Double = 0.0,
        estimatedTDEE: Double = 0.0,
        adaptiveTDEE: Double = 0.0,
        adherenceScore: Double = 0.0,
        confidenceScore: Double = 0.0,
        interventionType: String = "MAINTENANCE",
        interventionCategory: String = "MAINTENANCE",
        reason: String = "",
        source: String = "manual",
        effectiveFrom: Date = Date(),
        effectiveTo: Date? = nil,
        version: Int = 1
    ) {
        self.id = id
        self.createdAt = createdAt
        self.calorieTarget = calorieTarget
        self.proteinTarget = proteinTarget
        self.carbTarget = carbTarget
        self.fatTarget = fatTarget
        self.weight = weight
        self.rollingWeightAvg7d = rollingWeightAvg7d
        self.rollingWeightAvg14d = rollingWeightAvg14d
        self.estimatedTDEE = estimatedTDEE
        self.adaptiveTDEE = adaptiveTDEE
        self.adherenceScore = adherenceScore
        self.confidenceScore = confidenceScore
        self.interventionType = interventionType
        self.interventionCategory = interventionCategory
        self.reason = reason
        self.source = source
        self.effectiveFrom = effectiveFrom
        self.effectiveTo = effectiveTo
        self.version = version
    }
}
