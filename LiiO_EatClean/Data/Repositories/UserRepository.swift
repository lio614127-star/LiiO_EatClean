import Foundation
import CoreData

class UserRepository: UserRepositoryProtocol {
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }
    
    func fetchUser() async throws -> UserModel? {
        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "User")
            request.fetchLimit = 1
            guard let user = try self.context.fetch(request).first else { return nil }
            return UserModel(
                id: user.value(forKey: "id") as? UUID ?? UUID(),
                name: user.value(forKey: "name") as? String ?? "",
                age: user.value(forKey: "age") as? Double ?? 0.0,
                gender: user.value(forKey: "gender") as? String ?? "male",
                height: user.value(forKey: "height") as? Double ?? 0.0,
                weight: user.value(forKey: "weight") as? Double ?? 0.0,
                goalType: user.value(forKey: "goalType") as? String ?? "",
                dailyCalorieTarget: user.value(forKey: "dailyCalorieTarget") as? Double ?? 2000.0
            )
        }
    }
    
    func saveUser(_ user: UserModel) async throws {
        try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "User")
            let results = try self.context.fetch(request)
            
            let coreDataUser = results.first ?? NSEntityDescription.insertNewObject(forEntityName: "User", into: self.context)
            coreDataUser.setValue(user.id, forKey: "id")
            coreDataUser.setValue(user.name, forKey: "name")
            coreDataUser.setValue(user.age, forKey: "age")
            coreDataUser.setValue(user.gender, forKey: "gender")
            coreDataUser.setValue(user.height, forKey: "height")
            coreDataUser.setValue(user.weight, forKey: "weight")
            coreDataUser.setValue(user.goalType, forKey: "goalType")
            coreDataUser.setValue(user.dailyCalorieTarget, forKey: "dailyCalorieTarget")
            
            NotificationCenter.default.post(name: NSNotification.Name("userProfileDidUpdate"), object: nil)
            try self.context.save()
        }
    }
    
    func fetchWeightEntries() async throws -> [WeightEntryModel] {
        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "WeightEntry")
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
            let results = try self.context.fetch(request)
            
            let mappedResults: [WeightEntryModel] = results.map { entry in
                WeightEntryModel(
                    id: entry.value(forKey: "id") as? UUID ?? UUID(),
                    date: entry.value(forKey: "date") as? Date ?? Date(),
                    weight: entry.value(forKey: "weight") as? Double ?? 0.0
                )
            }
            return mappedResults
        }
    }
    
    func saveWeightEntry(_ entry: WeightEntryModel) async throws {
        try await context.perform {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: entry.date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
            
            let request = NSFetchRequest<NSManagedObject>(entityName: "WeightEntry")
            request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as CVarArg, endOfDay as CVarArg)
            
            let existingEntries = try self.context.fetch(request)
            let coreDataEntry: NSManagedObject
            
            if let first = existingEntries.first {
                coreDataEntry = first
                coreDataEntry.setValue(entry.weight, forKey: "weight")
            } else {
                coreDataEntry = NSEntityDescription.insertNewObject(forEntityName: "WeightEntry", into: self.context)
                coreDataEntry.setValue(entry.id, forKey: "id")
                coreDataEntry.setValue(entry.date, forKey: "date")
                coreDataEntry.setValue(entry.weight, forKey: "weight")
            }
            
            let userRequest = NSFetchRequest<NSManagedObject>(entityName: "User")
            userRequest.fetchLimit = 1
            if let user = try self.context.fetch(userRequest).first {
                user.setValue(entry.weight, forKey: "weight")
                
                let age = user.value(forKey: "age") as? Double ?? 0.0
                let height = user.value(forKey: "height") as? Double ?? 0.0
                let gender = user.value(forKey: "gender") as? String ?? "male"
                let goalType = user.value(forKey: "goalType") as? String ?? "maintain"
                
                let newTarget = CalorieCalculator.calculateDailyCalories(
                    weight: entry.weight,
                    height: height,
                    age: age,
                    gender: gender,
                    goal: goalType
                )
                user.setValue(newTarget, forKey: "dailyCalorieTarget")
            }
            
            NotificationCenter.default.post(name: NSNotification.Name("weightDidUpdate"), object: nil)
            try self.context.save()
        }
    }
    
    func fetchAPIKeys() async throws -> [APIKeyModel] {
        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "APIKey")
            request.sortDescriptors = [NSSortDescriptor(key: "priority", ascending: false)]
            let results = try self.context.fetch(request)
            let mappedResults: [APIKeyModel] = results.map { key in
                let attributes = key.entity.attributesByName.keys
                return APIKeyModel(
                    id: key.value(forKey: "id") as? UUID ?? UUID(),
                    name: attributes.contains("name") ? key.value(forKey: "name") as? String : nil,
                    provider: key.value(forKey: "provider") as? String ?? "",
                    key: key.value(forKey: "key") as? String ?? "",
                    isActive: key.value(forKey: "isActive") as? Bool ?? false,
                    lastUsed: key.value(forKey: "lastUsed") as? Date,
                    healthScore: Int(key.value(forKey: "healthScore") as? Int16 ?? 100),
                    priority: Int(key.value(forKey: "priority") as? Int16 ?? 0),
                    cooldownUntil: key.value(forKey: "cooldownUntil") as? Date,
                    apiVersion: attributes.contains("apiVersion") ? key.value(forKey: "apiVersion") as? String : nil,
                    isPaid: attributes.contains("isPaid") ? key.value(forKey: "isPaid") as? Bool : nil
                )
            }
            return mappedResults
        }
    }
    
    func saveAPIKey(_ apiKey: APIKeyModel) async throws {
        try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "APIKey")
            request.predicate = NSPredicate(format: "id == %@", apiKey.id as CVarArg)
            let existing = try self.context.fetch(request)
            
            let coreDataKey: NSManagedObject
            if let first = existing.first {
                coreDataKey = first
            } else {
                coreDataKey = NSEntityDescription.insertNewObject(forEntityName: "APIKey", into: self.context)
                coreDataKey.setValue(apiKey.id, forKey: "id")
            }
            coreDataKey.setValue(apiKey.provider, forKey: "provider")
            coreDataKey.setValue(apiKey.key, forKey: "key")
            coreDataKey.setValue(apiKey.isActive, forKey: "isActive")
            coreDataKey.setValue(apiKey.lastUsed, forKey: "lastUsed")
            coreDataKey.setValue(Int16(apiKey.healthScore), forKey: "healthScore")
            coreDataKey.setValue(Int16(apiKey.priority), forKey: "priority")
            coreDataKey.setValue(apiKey.cooldownUntil, forKey: "cooldownUntil")
            
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
            let request = NSFetchRequest<NSManagedObject>(entityName: "APIKey")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            let results = try self.context.fetch(request)
            results.forEach { self.context.delete($0) }
            try self.context.save()
        }
    }
    
    func deleteAPIKey(provider: String) async throws {
        try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "APIKey")
            request.predicate = NSPredicate(format: "provider == %@", provider)
            let results = try self.context.fetch(request)
            results.forEach { self.context.delete($0) }
            try self.context.save()
        }
    }
    
    func fetchWaterLog(for date: Date) async throws -> Double {
        return try await context.perform {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return 0 }
            
            let request = NSFetchRequest<NSManagedObject>(entityName: "DailyLog")
            request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as CVarArg, endOfDay as CVarArg)
            
            let results = try self.context.fetch(request)
            return results.first?.value(forKey: "waterIntake") as? Double ?? 0.0
        }
    }
    
    func addWater(amount: Double, for date: Date) async throws {
        try await context.perform {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
            
            let request = NSFetchRequest<NSManagedObject>(entityName: "DailyLog")
            request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as CVarArg, endOfDay as CVarArg)
            
            let existing = try self.context.fetch(request)
            let log: NSManagedObject
            
            if let first = existing.first {
                log = first
            } else {
                log = NSEntityDescription.insertNewObject(forEntityName: "DailyLog", into: self.context)
                log.setValue(UUID(), forKey: "id")
                log.setValue(date, forKey: "date")
            }
            
            let currentWater = log.value(forKey: "waterIntake") as? Double ?? 0.0
            log.setValue(currentWater + amount, forKey: "waterIntake")
            try self.context.save()
        }
    }
    
    func resetWater(for date: Date) async throws {
        try await context.perform {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
            
            let request = NSFetchRequest<NSManagedObject>(entityName: "DailyLog")
            request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as CVarArg, endOfDay as CVarArg)
            
            if let log = try self.context.fetch(request).first {
                log.setValue(0.0, forKey: "waterIntake")
                try self.context.save()
            }
        }
    }
    
    func resetAllData() async throws {
        try await context.perform {
            let weightRequest = NSFetchRequest<NSManagedObject>(entityName: "WeightEntry")
            let weights = try self.context.fetch(weightRequest)
            weights.forEach { self.context.delete($0) }
            
            let logRequest = NSFetchRequest<NSManagedObject>(entityName: "DailyLog")
            let logs = try self.context.fetch(logRequest)
            logs.forEach { self.context.delete($0) }
            
            try self.context.save()
        }
    }
    
    func fetchStreak() async throws -> StreakModel? {
        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "StreakRecord")
            request.fetchLimit = 1
            guard let record = try self.context.fetch(request).first else { return nil }
            return StreakModel(
                id: record.value(forKey: "id") as? UUID ?? UUID(),
                currentStreak: Int(record.value(forKey: "currentStreak") as? Int32 ?? 0),
                longestStreak: Int(record.value(forKey: "longestStreak") as? Int32 ?? 0),
                lastActiveDate: record.value(forKey: "lastActiveDate") as? Date ?? Date(),
                mealConditionMet: record.value(forKey: "mealConditionMet") as? Bool ?? false,
                calorieConditionMet: record.value(forKey: "calorieConditionMet") as? Bool ?? false,
                waterConditionMet: record.value(forKey: "waterConditionMet") as? Bool ?? false
            )
        }
    }
    
    func saveStreak(_ streak: StreakModel) async throws {
        try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "StreakRecord")
            let results = try self.context.fetch(request)
            
            let record = results.first ?? NSEntityDescription.insertNewObject(forEntityName: "StreakRecord", into: self.context)
            record.setValue(streak.id, forKey: "id")
            record.setValue(Int32(streak.currentStreak), forKey: "currentStreak")
            record.setValue(Int32(streak.longestStreak), forKey: "longestStreak")
            record.setValue(streak.lastActiveDate, forKey: "lastActiveDate")
            record.setValue(streak.mealConditionMet, forKey: "mealConditionMet")
            record.setValue(streak.calorieConditionMet, forKey: "calorieConditionMet")
            record.setValue(streak.waterConditionMet, forKey: "waterConditionMet")
            
            try self.context.save()
        }
    }
}
