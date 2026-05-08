import SwiftUI
import CoreData
@main
struct LiiO_EatCleanApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        print("🚀 App: Initializing...")
        Task {
            do {
                print("🚀 App: Seeding database if needed...")
                try await FoodRepository().seedDatabaseIfNeeded()
                print("🚀 App: Database ready.")
                
                await Self.performAIMemoryMigration()
            } catch {
                print("❌ Failed to seed database: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
    
    private static func performAIMemoryMigration() async {
        let key = "com.liio.EatClean.userMemory"
        guard let data = UserDefaults.standard.data(forKey: key) else { return }
        
        struct OldHealthCondition: Codable {
            var id: UUID
            var name: String
            var avoidFoods: [String]
            var dietaryNotes: String
        }
        
        struct OldUserProfileMemory: Codable {
            var healthConditions: [OldHealthCondition] = []
            var likes: [String] = []
            var dislikes: [String] = []
            var dietaryNotes: [String] = []
        }
        
        do {
            let decoder = JSONDecoder()
            let oldMemory = try decoder.decode(OldUserProfileMemory.self, from: data)
            
            var newMemory = UserProfileMemory()
            newMemory.likes = oldMemory.likes
            newMemory.dislikes = oldMemory.dislikes
            newMemory.dietaryNotes = oldMemory.dietaryNotes
            
            var allAvoid = [String]()
            for hc in oldMemory.healthConditions {
                newMemory.healthConditions.append(HealthConditionModel(id: hc.id, name: hc.name, dietaryNotes: hc.dietaryNotes))
                allAvoid.append(contentsOf: hc.avoidFoods)
            }
            newMemory.avoidFoods = allAvoid
            
            try await AIMemoryRepository.shared.saveMemory(newMemory)
            
            UserDefaults.standard.removeObject(forKey: key)
            print("🚀 App: AI Memory migrated successfully.")
        } catch {
            print("❌ App: Failed to migrate AI memory - \(error)")
        }
    }
}
