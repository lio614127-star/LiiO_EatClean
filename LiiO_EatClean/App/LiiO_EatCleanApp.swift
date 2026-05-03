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
}
