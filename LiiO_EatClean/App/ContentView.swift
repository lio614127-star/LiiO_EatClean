import SwiftUI
import CoreData
struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @AppStorage("selectedTab") private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
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
            
            // Global AI Activity Overlay
            AIActivityOverlay()
                .padding(.top, 60) // Offset for notch/status bar
                .ignoresSafeArea(.all, edges: .bottom)
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
