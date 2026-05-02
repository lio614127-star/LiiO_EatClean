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
                VStack(spacing: 4) {
                    Text("LiiO")
                        .font(.system(size: 40, weight: .bold, design: .default))
                        .foregroundColor(.green)
                    
                    Text("EatClean")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundColor(Color(.systemGray))
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
