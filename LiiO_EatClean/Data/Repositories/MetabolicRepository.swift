import Foundation
import CoreData

protocol MetabolicRepositoryProtocol {
    func fetchMetabolicProfile() async throws -> MetabolicProfileModel?
    func saveMetabolicProfile(_ profile: MetabolicProfileModel) async throws
    func fetchGoalHistory() async throws -> [GoalHistoryModel]
    func saveGoalHistory(_ entry: GoalHistoryModel) async throws
    func closePreviousGoalVersion(at date: Date) async throws
    func fetchLatestGoal() async throws -> GoalHistoryModel?
    func bootstrapMetabolicData(for user: UserModel) async throws
}

class MetabolicRepository: MetabolicRepositoryProtocol {
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }
    
    func fetchMetabolicProfile() async throws -> MetabolicProfileModel? {
        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "MetabolicProfile")
            request.fetchLimit = 1
            guard let profile = try self.context.fetch(request).first else { return nil }
            
            return MetabolicProfileModel(
                id: profile.value(forKey: "id") as? UUID ?? UUID(),
                estimatedBMR: profile.value(forKey: "estimatedBMR") as? Double ?? 0,
                estimatedTDEE: profile.value(forKey: "estimatedTDEE") as? Double ?? 0,
                adaptiveTDEE: profile.value(forKey: "adaptiveTDEE") as? Double ?? 0,
                metabolicAdaptationScore: profile.value(forKey: "metabolicAdaptationScore") as? Double ?? 0,
                lastCalculatedAt: profile.value(forKey: "lastCalculatedAt") as? Date ?? Date(),
                confidenceScore: profile.value(forKey: "confidenceScore") as? Double ?? 0,
                onboardingSource: profile.value(forKey: "onboardingSource") as? String ?? "manual",
                calculationVersion: Int(profile.value(forKey: "calculationVersion") as? Int32 ?? 1)
            )
        }
    }
    
    func saveMetabolicProfile(_ profile: MetabolicProfileModel) async throws {
        try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "MetabolicProfile")
            let existing = try self.context.fetch(request).first
            
            let coreDataProfile = existing ?? NSEntityDescription.insertNewObject(forEntityName: "MetabolicProfile", into: self.context)
            coreDataProfile.setValue(profile.id, forKey: "id")
            coreDataProfile.setValue(profile.estimatedBMR, forKey: "estimatedBMR")
            coreDataProfile.setValue(profile.estimatedTDEE, forKey: "estimatedTDEE")
            coreDataProfile.setValue(profile.adaptiveTDEE, forKey: "adaptiveTDEE")
            coreDataProfile.setValue(profile.metabolicAdaptationScore, forKey: "metabolicAdaptationScore")
            coreDataProfile.setValue(profile.lastCalculatedAt, forKey: "lastCalculatedAt")
            coreDataProfile.setValue(profile.confidenceScore, forKey: "confidenceScore")
            coreDataProfile.setValue(profile.onboardingSource, forKey: "onboardingSource")
            coreDataProfile.setValue(Int32(profile.calculationVersion), forKey: "calculationVersion")
            
            // Link to user if not already linked
            if coreDataProfile.value(forKey: "user") == nil {
                let userRequest = NSFetchRequest<NSManagedObject>(entityName: "User")
                userRequest.fetchLimit = 1
                if let user = try self.context.fetch(userRequest).first {
                    coreDataProfile.setValue(user, forKey: "user")
                }
            }
            
            try self.context.save()
        }
    }
    
    func fetchGoalHistory() async throws -> [GoalHistoryModel] {
        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "GoalHistory")
            request.sortDescriptors = [NSSortDescriptor(key: "effectiveFrom", ascending: false)]
            let results = try self.context.fetch(request)
            
            let mappedResults: [GoalHistoryModel] = results.map { entry in
                GoalHistoryModel(
                    id: entry.value(forKey: "id") as? UUID ?? UUID(),
                    createdAt: entry.value(forKey: "createdAt") as? Date ?? Date(),
                    calorieTarget: entry.value(forKey: "calorieTarget") as? Double ?? 0,
                    proteinTarget: entry.value(forKey: "proteinTarget") as? Double ?? 0,
                    carbTarget: entry.value(forKey: "carbTarget") as? Double ?? 0,
                    fatTarget: entry.value(forKey: "fatTarget") as? Double ?? 0,
                    weight: entry.value(forKey: "weight") as? Double ?? 0,
                    rollingWeightAvg7d: entry.value(forKey: "rollingWeightAvg7d") as? Double ?? 0,
                    rollingWeightAvg14d: entry.value(forKey: "rollingWeightAvg14d") as? Double ?? 0,
                    estimatedTDEE: entry.value(forKey: "estimatedTDEE") as? Double ?? 0,
                    adaptiveTDEE: entry.value(forKey: "adaptiveTDEE") as? Double ?? 0,
                    adherenceScore: entry.value(forKey: "adherenceScore") as? Double ?? 0,
                    confidenceScore: entry.value(forKey: "confidenceScore") as? Double ?? 0,
                    interventionType: entry.value(forKey: "interventionType") as? String ?? "MAINTENANCE",
                    interventionCategory: entry.value(forKey: "interventionCategory") as? String ?? "MAINTENANCE",
                    reason: entry.value(forKey: "reason") as? String ?? "",
                    source: entry.value(forKey: "source") as? String ?? "manual",
                    effectiveFrom: entry.value(forKey: "effectiveFrom") as? Date ?? Date(),
                    effectiveTo: entry.value(forKey: "effectiveTo") as? Date,
                    version: Int(entry.value(forKey: "version") as? Int32 ?? 1)
                )
            }
            return mappedResults
        }
    }
    
    func saveGoalHistory(_ entry: GoalHistoryModel) async throws {
        try await context.perform {
            let coreDataEntry = NSEntityDescription.insertNewObject(forEntityName: "GoalHistory", into: self.context)
            coreDataEntry.setValue(entry.id, forKey: "id")
            coreDataEntry.setValue(entry.createdAt, forKey: "createdAt")
            coreDataEntry.setValue(entry.calorieTarget, forKey: "calorieTarget")
            coreDataEntry.setValue(entry.proteinTarget, forKey: "proteinTarget")
            coreDataEntry.setValue(entry.carbTarget, forKey: "carbTarget")
            coreDataEntry.setValue(entry.fatTarget, forKey: "fatTarget")
            coreDataEntry.setValue(entry.weight, forKey: "weight")
            coreDataEntry.setValue(entry.rollingWeightAvg7d, forKey: "rollingWeightAvg7d")
            coreDataEntry.setValue(entry.rollingWeightAvg14d, forKey: "rollingWeightAvg14d")
            coreDataEntry.setValue(entry.estimatedTDEE, forKey: "estimatedTDEE")
            coreDataEntry.setValue(entry.adaptiveTDEE, forKey: "adaptiveTDEE")
            coreDataEntry.setValue(entry.adherenceScore, forKey: "adherenceScore")
            coreDataEntry.setValue(entry.confidenceScore, forKey: "confidenceScore")
            coreDataEntry.setValue(entry.interventionType, forKey: "interventionType")
            coreDataEntry.setValue(entry.interventionCategory, forKey: "interventionCategory")
            coreDataEntry.setValue(entry.reason, forKey: "reason")
            coreDataEntry.setValue(entry.source, forKey: "source")
            coreDataEntry.setValue(entry.effectiveFrom, forKey: "effectiveFrom")
            coreDataEntry.setValue(entry.effectiveTo, forKey: "effectiveTo")
            coreDataEntry.setValue(Int32(entry.version), forKey: "version")
            
            // Link to profile
            let profileRequest = NSFetchRequest<NSManagedObject>(entityName: "MetabolicProfile")
            if let profile = try self.context.fetch(profileRequest).first {
                coreDataEntry.setValue(profile, forKey: "metabolicProfile")
            }
            
            try self.context.save()
        }
    }
    
    func closePreviousGoalVersion(at date: Date) async throws {
        try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "GoalHistory")
            request.predicate = NSPredicate(format: "effectiveTo == nil")
            request.sortDescriptors = [NSSortDescriptor(key: "effectiveFrom", ascending: false)]
            
            if let latest = try self.context.fetch(request).first {
                latest.setValue(date, forKey: "effectiveTo")
                try self.context.save()
            }
        }
    }
    
    func fetchLatestGoal() async throws -> GoalHistoryModel? {
        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "GoalHistory")
            request.predicate = NSPredicate(format: "effectiveTo == nil")
            request.fetchLimit = 1
            
            guard let entry = try self.context.fetch(request).first else { return nil }
            
            return GoalHistoryModel(
                id: entry.value(forKey: "id") as? UUID ?? UUID(),
                createdAt: entry.value(forKey: "createdAt") as? Date ?? Date(),
                calorieTarget: entry.value(forKey: "calorieTarget") as? Double ?? 0,
                proteinTarget: entry.value(forKey: "proteinTarget") as? Double ?? 0,
                carbTarget: entry.value(forKey: "carbTarget") as? Double ?? 0,
                fatTarget: entry.value(forKey: "fatTarget") as? Double ?? 0,
                weight: entry.value(forKey: "weight") as? Double ?? 0,
                rollingWeightAvg7d: entry.value(forKey: "rollingWeightAvg7d") as? Double ?? 0,
                rollingWeightAvg14d: entry.value(forKey: "rollingWeightAvg14d") as? Double ?? 0,
                estimatedTDEE: entry.value(forKey: "estimatedTDEE") as? Double ?? 0,
                adaptiveTDEE: entry.value(forKey: "adaptiveTDEE") as? Double ?? 0,
                adherenceScore: entry.value(forKey: "adherenceScore") as? Double ?? 0,
                confidenceScore: entry.value(forKey: "confidenceScore") as? Double ?? 0,
                interventionType: entry.value(forKey: "interventionType") as? String ?? "MAINTENANCE",
                interventionCategory: entry.value(forKey: "interventionCategory") as? String ?? "MAINTENANCE",
                reason: entry.value(forKey: "reason") as? String ?? "",
                source: entry.value(forKey: "source") as? String ?? "manual",
                effectiveFrom: entry.value(forKey: "effectiveFrom") as? Date ?? Date(),
                effectiveTo: entry.value(forKey: "effectiveTo") as? Date,
                version: Int(entry.value(forKey: "version") as? Int32 ?? 1)
            )
        }
    }
    
    func bootstrapMetabolicData(for user: UserModel) async throws {
        try await context.perform {
            let profileRequest = NSFetchRequest<NSManagedObject>(entityName: "MetabolicProfile")
            if let _ = try self.context.fetch(profileRequest).first {
                return // Already bootstrapped
            }
            
            // 1. Create Profile
            let profile = NSEntityDescription.insertNewObject(forEntityName: "MetabolicProfile", into: self.context)
            profile.setValue(UUID(), forKey: "id")
            profile.setValue(user.dailyCalorieTarget + 500, forKey: "estimatedTDEE")
            profile.setValue(user.dailyCalorieTarget + 500, forKey: "adaptiveTDEE")
            profile.setValue(Date(), forKey: "lastCalculatedAt")
            profile.setValue("migration", forKey: "onboardingSource")
            profile.setValue(Int32(1), forKey: "calculationVersion")
            
            // Link to user
            let userRequest = NSFetchRequest<NSManagedObject>(entityName: "User")
            if let coreDataUser = try self.context.fetch(userRequest).first {
                profile.setValue(coreDataUser, forKey: "user")
            }
            
            // 2. Create Initial Goal History
            let history = NSEntityDescription.insertNewObject(forEntityName: "GoalHistory", into: self.context)
            history.setValue(UUID(), forKey: "id")
            history.setValue(Date(), forKey: "createdAt")
            history.setValue(user.dailyCalorieTarget, forKey: "calorieTarget")
            history.setValue(user.dailyCalorieTarget * 0.3 / 4.0, forKey: "proteinTarget")
            history.setValue(user.dailyCalorieTarget * 0.4 / 4.0, forKey: "carbTarget")
            history.setValue(user.dailyCalorieTarget * 0.3 / 9.0, forKey: "fatTarget")
            history.setValue(user.weight, forKey: "weight")
            history.setValue("onboarding", forKey: "source")
            history.setValue(Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date(), forKey: "effectiveFrom")
            history.setValue(Int32(1), forKey: "version")
            history.setValue(profile, forKey: "metabolicProfile")
            
            try self.context.save()
        }
    }
}
