import SwiftUI
import CoreData
struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(NetworkMonitor.self) private var networkMonitor
    
    @AppStorage("selectedTab") private var selectedTab = 4 // Default to AI Coach for testing or persistent storage
    
    @Environment(GlobalVoiceAssistantManager.self) var voiceManager
    
    var shouldShowVoiceOverlay: Bool {
        // Only show overlay when actively interacting or when wake is detected
        [.wakeDetected, .commandListening, .processing, .speaking, .error].contains(voiceManager.state)
    }
    
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
        .overlay {
            SiriStyleVoiceOverlayV4(target: .contentView)
        }
        .animation(.spring(response: 0.4), value: voiceManager.state)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name.appSwitchTab)) { notification in
            if let tabRaw = notification.object as? Int {
                print("[AppAction Router] Intercepted switchTab -> \(tabRaw)")
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    selectedTab = tabRaw
                }
            }
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
