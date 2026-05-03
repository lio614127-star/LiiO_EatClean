import SwiftUI

struct SplashView: View {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    @State private var isActive = false
    @State private var scale: CGFloat = 0.9
    @State private var opacity: Double = 0.0
    
    var body: some View {
        if isActive {
            if hasCompletedOnboarding {
                ContentView()
            } else {
                OnboardingView()
            }
        } else {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.green.opacity(0.08), Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Logo
                VStack(spacing: 20) {
                    Image("avatar_tool")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 160, height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 36))
                        .shadow(color: .green.opacity(0.3), radius: 25)
                    
                    Text("LiiO EatClean")
                        .font(.title3.bold())
                        .foregroundColor(.green)
                        .tracking(2)
                }
                .scaleEffect(scale)
                .opacity(opacity)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    scale = 1.0
                    opacity = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashView()
}
