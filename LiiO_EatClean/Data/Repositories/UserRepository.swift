import Foundation
import CoreData

class UserRepository: UserRepositoryProtocol {
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }
    
    func fetchUser() async throws -> UserModel? {
        try await context.perform {
            let request: NSFetchRequest<User> = User.fetchRequest()
            request.fetchLimit = 1
            guard let user = try self.context.fetch(request).first else { return nil }
            return UserModel(
                id: user.id ?? UUID(),
                name: user.name ?? "",
                age: user.age,
                gender: user.gender ?? "male",
                height: user.height,
                weight: user.weight,
                goalType: user.goalType ?? "",
                dailyCalorieTarget: user.dailyCalorieTarget
            )
        }
    }
    
    func saveUser(_ user: UserModel) async throws {
        try await context.perform {
            let request: NSFetchRequest<User> = User.fetchRequest()
            let results = try self.context.fetch(request)
            
            let coreDataUser = results.first ?? User(context: self.context)
            coreDataUser.id = user.id
            coreDataUser.name = user.name
            coreDataUser.age = user.age
            coreDataUser.gender = user.gender
            coreDataUser.height = user.height
            coreDataUser.weight = user.weight
            coreDataUser.goalType = user.goalType
            coreDataUser.dailyCalorieTarget = user.dailyCalorieTarget
            
            try self.context.save()
        }
    }
    
    func fetchWeightEntries() async throws -> [WeightEntryModel] {
        try await context.perform {
            let request: NSFetchRequest<WeightEntry> = WeightEntry.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \WeightEntry.date, ascending: true)]
            let results = try self.context.fetch(request)
            
            return results.map { entry in
                WeightEntryModel(
                    id: entry.id ?? UUID(),
                    date: entry.date ?? Date(),
                    weight: entry.weight
                )
            }
        }
    }
    
    func saveWeightEntry(_ entry: WeightEntryModel) async throws {
        try await context.perform {
            // Check if entry for this date already exists
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: entry.date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
            
            let request: NSFetchRequest<WeightEntry> = WeightEntry.fetchRequest()
            request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as CVarArg, endOfDay as CVarArg)
            
            let existingEntries = try self.context.fetch(request)
            let coreDataEntry: WeightEntry
            
            if let first = existingEntries.first {
                coreDataEntry = first
                coreDataEntry.weight = entry.weight
            } else {
                coreDataEntry = WeightEntry(context: self.context)
                coreDataEntry.id = entry.id
                coreDataEntry.date = entry.date
                coreDataEntry.weight = entry.weight
            }
            
            // Also update User's current weight
            let userRequest: NSFetchRequest<User> = User.fetchRequest()
            userRequest.fetchLimit = 1
            if let user = try self.context.fetch(userRequest).first {
                user.weight = entry.weight
            }
            
            try self.context.save()
        }
    }
    
    func fetchAPIKeys() async throws -> [APIKeyModel] {
        try await context.perform {
            let request: NSFetchRequest<APIKey> = APIKey.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \APIKey.priority, ascending: false)]
            let results = try self.context.fetch(request)
            return results.map { key in
                let attributes = key.entity.attributesByName.keys
                return APIKeyModel(
                    id: key.id ?? UUID(),
                    name: attributes.contains("name") ? key.value(forKey: "name") as? String : nil,
                    provider: key.provider ?? "",
                    key: key.key ?? "",
                    isActive: key.isActive,
                    lastUsed: key.lastUsed,
                    healthScore: Int(key.healthScore),
                    priority: Int(key.priority),
                    cooldownUntil: key.cooldownUntil,
                    apiVersion: attributes.contains("apiVersion") ? key.value(forKey: "apiVersion") as? String : nil,
                    isPaid: attributes.contains("isPaid") ? key.value(forKey: "isPaid") as? Bool : nil
                )
            }
        }
    }
    
    func saveAPIKey(_ apiKey: APIKeyModel) async throws {
        try await context.perform {
            // Check if key with this id exists
            let request: NSFetchRequest<APIKey> = APIKey.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", apiKey.id as CVarArg)
            let existing = try self.context.fetch(request)
            
            let coreDataKey: APIKey
            if let first = existing.first {
                coreDataKey = first
            } else {
                coreDataKey = APIKey(context: self.context)
                coreDataKey.id = apiKey.id
            }
            coreDataKey.provider = apiKey.provider
            coreDataKey.key = apiKey.key
            coreDataKey.isActive = apiKey.isActive
            coreDataKey.lastUsed = apiKey.lastUsed
            coreDataKey.healthScore = Int16(apiKey.healthScore)
            coreDataKey.priority = Int16(apiKey.priority)
            coreDataKey.cooldownUntil = apiKey.cooldownUntil
            
            // Safely map new fields if they exist in the CoreData entity
            if coreDataKey.entity.attributesByName.keys.contains("name") {
                coreDataKey.setValue(apiKey.name, forKey: "name")
            }
            if coreDataKey.entity.attributesByName.keys.contains("apiVersion") {
                coreDataKey.setValue(apiKey.apiVersion, forKey: "apiVersion")
            }
            if coreDataKey.entity.attributesByName.keys.contains("isPaid") {
                coreDataKey.setValue(apiKey.isPaid, forKey: "isPaid")
            }
            
            try self.context.save()
        }
    }
    
    func deleteAPIKey(id: UUID) async throws {
        try await context.perform {
            let request: NSFetchRequest<APIKey> = APIKey.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            let results = try self.context.fetch(request)
            results.forEach { self.context.delete($0) }
            try self.context.save()
        }
    }
    
    func deleteAPIKey(provider: String) async throws {
        try await context.perform {
            let request: NSFetchRequest<APIKey> = APIKey.fetchRequest()
            request.predicate = NSPredicate(format: "provider == %@", provider)
            let results = try self.context.fetch(request)
            results.forEach { self.context.delete($0) }
            try self.context.save()
        }
    }
    
    func fetchWaterLog(for date: Date) async throws -> Double {
        try await context.perform {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return 0 }
            
            let request: NSFetchRequest<DailyLog> = DailyLog.fetchRequest()
            request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as CVarArg, endOfDay as CVarArg)
            
            let results = try self.context.fetch(request)
            return results.first?.waterIntake ?? 0.0
        }
    }
    
    func addWater(amount: Double, for date: Date) async throws {
        try await context.perform {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
            
            let request: NSFetchRequest<DailyLog> = DailyLog.fetchRequest()
            request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as CVarArg, endOfDay as CVarArg)
            
            let existing = try self.context.fetch(request)
            let log: DailyLog
            
            if let first = existing.first {
                log = first
            } else {
                log = DailyLog(context: self.context)
                log.id = UUID()
                log.date = date
            }
            
            log.waterIntake += amount
            try self.context.save()
        }
    }
    
    func resetWater(for date: Date) async throws {
        try await context.perform {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
            
            let request: NSFetchRequest<DailyLog> = DailyLog.fetchRequest()
            request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as CVarArg, endOfDay as CVarArg)
            
            if let log = try self.context.fetch(request).first {
                log.waterIntake = 0
                try self.context.save()
            }
        }
    }
    
    func resetAllData() async throws {
        try await context.perform {
            let weightRequest: NSFetchRequest<NSFetchRequestResult> = WeightEntry.fetchRequest()
            let deleteWeight = NSBatchDeleteRequest(fetchRequest: weightRequest)
            try self.context.execute(deleteWeight)
            
            let logRequest: NSFetchRequest<NSFetchRequestResult> = DailyLog.fetchRequest()
            let deleteLog = NSBatchDeleteRequest(fetchRequest: logRequest)
            try self.context.execute(deleteLog)
            
            try self.context.save()
        }
    }
    
    func fetchStreak() async throws -> StreakModel? {
        try await context.perform {
            let request: NSFetchRequest<StreakRecord> = StreakRecord.fetchRequest()
            request.fetchLimit = 1
            guard let record = try self.context.fetch(request).first else { return nil }
            return StreakModel(
                id: record.id ?? UUID(),
                currentStreak: Int(record.currentStreak),
                longestStreak: Int(record.longestStreak),
                lastActiveDate: record.lastActiveDate ?? Date(),
                mealConditionMet: record.mealConditionMet,
                calorieConditionMet: record.calorieConditionMet,
                waterConditionMet: record.waterConditionMet
            )
        }
    }
    
    func saveStreak(_ streak: StreakModel) async throws {
        try await context.perform {
            let request: NSFetchRequest<StreakRecord> = StreakRecord.fetchRequest()
            let results = try self.context.fetch(request)
            
            let record = results.first ?? StreakRecord(context: self.context)
            record.id = streak.id
            record.currentStreak = Int32(streak.currentStreak)
            record.longestStreak = Int32(streak.longestStreak)
            record.lastActiveDate = streak.lastActiveDate
            record.mealConditionMet = streak.mealConditionMet
            record.calorieConditionMet = streak.calorieConditionMet
            record.waterConditionMet = streak.waterConditionMet
            
            try self.context.save()
        }
    }
}
