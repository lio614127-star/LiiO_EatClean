import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var navigateToSetup = false
    
    private let slides = [
        (icon: "flame.fill", title: "Theo dõi Calories", desc: "Log bữa ăn nhanh chóng, chính xác mỗi ngày"),
        (icon: "chart.bar.fill", title: "Xem tiến trình", desc: "Biểu đồ trực quan giúp bạn theo dõi mục tiêu"),
        (icon: "figure.walk", title: "Đạt body mong muốn", desc: "Thiết lập mục tiêu cá nhân và bắt đầu ngay")
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemBackground).ignoresSafeArea()
                
                VStack {
                    // Skip button
                    HStack {
                        Spacer()
                        Button("Bỏ qua") {
                            navigateToSetup = true
                        }
                        .foregroundColor(.secondary)
                        .padding(.trailing, 20)
                        .padding(.top, 8)
                    }
                    
                    // Slides
                    TabView(selection: $currentPage) {
                        ForEach(0..<slides.count, id: \.self) { index in
                            OnboardingSlide(
                                icon: slides[index].icon,
                                title: slides[index].title,
                                description: slides[index].desc
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .animation(.easeInOut, value: currentPage)
                    
                    // Continue / Get Started button
                    Button(action: {
                        if currentPage < slides.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            navigateToSetup = true
                        }
                    }) {
                        Text(currentPage < slides.count - 1 ? "Tiếp tục" : "Bắt đầu")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .navigationDestination(isPresented: $navigateToSetup) {
                GoalSetupView()
            }
        }
    }
}

#Preview {
    OnboardingView()
}
