import Foundation
import CoreData
import Combine

class DailyAdherenceSnapshotService {
    static let shared = DailyAdherenceSnapshotService()
    
    private let context: NSManagedObjectContext
    private let mealRepo: MealRepository
    private let planRepo: DailyPlanRepository
    private var cancellables = Set<AnyCancellable>()
    
    private let currentDataVersion: Int16 = 1
    
    private init(
        context: NSManagedObjectContext = PersistenceController.shared.container.viewContext,
        mealRepo: MealRepository = MealRepository(),
        planRepo: DailyPlanRepository = DailyPlanRepository()
    ) {
        self.context = context
        self.mealRepo = mealRepo
        self.planRepo = planRepo
        
        setupObservers()
    }
    
    private func setupObservers() {
        NotificationCenter.default.publisher(for: NSNotification.Name("mealLogDidUpdate"))
            .sink { [weak self] _ in
                Task { [weak self] in
                    try? await self?.recalculateSnapshot(for: Date())
                }
            }
            .store(in: &cancellables)
            
        NotificationCenter.default.publisher(for: NSNotification.Name("mealPlanDidUpdate"))
            .sink { [weak self] _ in
                Task { [weak self] in
                    try? await self?.recalculateSnapshot(for: Date())
                }
            }
            .store(in: &cancellables)
    }
    
    func recalculateSnapshot(for date: Date) async throws {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        // 1. Fetch data
        let actualMeals = try await mealRepo.fetchMeals(by: startOfDay)
        let dailyPlan = try await planRepo.fetchPlan(for: startOfDay)
        
        let targetCalories = dailyPlan?.targetCalories ?? 0
        let targetProtein = dailyPlan?.targetProtein ?? 0
        let plannedMeals = dailyPlan?.plannedMeals ?? []
        
        // 2. Calculate score
        let result = MealAdherenceCalculator.shared.calculate(
            actualMeals: actualMeals,
            plannedMeals: plannedMeals,
            targetCalories: targetCalories,
            targetProtein: targetProtein
        )
        
        // 3. Persist snapshot
        try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "DailyAdherenceSnapshot")
            request.predicate = NSPredicate(format: "date == %@", startOfDay as CVarArg)
            
            let existing = try self.context.fetch(request).first
            let snapshot = existing ?? NSEntityDescription.insertNewObject(forEntityName: "DailyAdherenceSnapshot", into: self.context)
            
            if existing == nil {
                snapshot.setValue(UUID(), forKey: "id")
                snapshot.setValue(startOfDay, forKey: "date")
            }
            
            snapshot.setValue(result.totalScore, forKey: "adherenceScore")
            snapshot.setValue(targetCalories, forKey: "targetCalories")
            snapshot.setValue(targetProtein, forKey: "targetProtein")
            snapshot.setValue(actualMeals.reduce(0) { $0 + $1.totalCalories }, forKey: "totalCalories")
            snapshot.setValue(actualMeals.reduce(0) { sum, meal in 
                sum + meal.mealFoods.reduce(0) { $0 + ($1.proteinSnapshot * $1.quantity) }
            }, forKey: "totalProtein")
            snapshot.setValue(Int16(actualMeals.count), forKey: "mealCount")
            snapshot.setValue(Int16(plannedMeals.count), forKey: "plannedMealCount")
            snapshot.setValue(self.currentDataVersion, forKey: "dataVersion")
            
            try self.context.save()
        }
    }
    
    func fetchSnapshots(from startDate: Date, to endDate: Date) async throws -> [DailyAdherenceSnapshotModel] {
        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "DailyAdherenceSnapshot")
            request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as CVarArg, endDate as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
            
            let results = try self.context.fetch(request)
            return results.map { self.mapSnapshot($0) }
        }
    }
    
    func rebuildAllSnapshots() async throws {
        let snapshots = try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "DailyAdherenceSnapshot")
            request.predicate = NSPredicate(format: "dataVersion < %d", self.currentDataVersion)
            return try self.context.fetch(request)
        }
        
        for entity in snapshots {
            if let date = entity.value(forKey: "date") as? Date {
                try await recalculateSnapshot(for: date)
            }
        }
    }
    
    private func mapSnapshot(_ entity: NSManagedObject) -> DailyAdherenceSnapshotModel {
        return DailyAdherenceSnapshotModel(
            id: entity.value(forKey: "id") as? UUID ?? UUID(),
            date: entity.value(forKey: "date") as? Date ?? Date(),
            adherenceScore: entity.value(forKey: "adherenceScore") as? Double ?? 0,
            totalCalories: entity.value(forKey: "totalCalories") as? Double ?? 0,
            totalProtein: entity.value(forKey: "totalProtein") as? Double ?? 0,
            targetCalories: entity.value(forKey: "targetCalories") as? Double ?? 0,
            targetProtein: entity.value(forKey: "targetProtein") as? Double ?? 0,
            mealCount: Int(entity.value(forKey: "mealCount") as? Int16 ?? 0),
            plannedMealCount: Int(entity.value(forKey: "plannedMealCount") as? Int16 ?? 0),
            dataVersion: Int(entity.value(forKey: "dataVersion") as? Int16 ?? 1)
        )
    }
}

struct DailyAdherenceSnapshotModel: Identifiable {
    let id: UUID
    let date: Date
    let adherenceScore: Double
    let totalCalories: Double
    let totalProtein: Double
    let targetCalories: Double
    let targetProtein: Double
    let mealCount: Int
    let plannedMealCount: Int
    let dataVersion: Int
}
