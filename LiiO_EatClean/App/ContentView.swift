import SwiftUI
import CoreData
struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(NetworkMonitor.self) private var networkMonitor
    
    @AppStorage("selectedTab") private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                OfflineBannerView(isConnected: networkMonitor.isConnected)
                
                TabView(selection: $selectedTab) {
                    HomeView()
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
                        .tag(0)
                    
                    MealsView()
                        .tabItem {
                            Label("Meals", systemImage: "fork.knife")
                        }
                        .tag(1)
                    
                    ProgressTabView()
                        .tabItem {
                            Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                        }
                        .tag(2)
                    
                    ProfileView()
                        .tabItem {
                            Label("Profile", systemImage: "person.fill")
                        }
                        .tag(3)
                        
                    ChatView()
                        .tabItem {
                            Label("AI Coach", systemImage: "message.badge.filled.fill")
                        }
                        .tag(4)
                }
                .tint(.green)
            }
            
            // Global AI Activity Overlay
            AIActivityOverlay()
                .padding(.top, 60) // Offset for notch/status bar
                .ignoresSafeArea(.all, edges: .bottom)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("navigateToJournal"))) { _ in
            selectedTab = 1
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AskAICoachAboutMeal"))) { _ in
            selectedTab = 4
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
