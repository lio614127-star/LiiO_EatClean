import SwiftUI
import CoreData
@main
struct LiiO_EatCleanApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        Task {
            do {
                try await FoodRepository().seedDatabaseIfNeeded()
            } catch {
                print("Failed to seed database: \(error)")
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
