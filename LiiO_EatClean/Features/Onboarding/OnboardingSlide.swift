import SwiftUI

struct OnboardingSlide: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundColor(.green)
                .padding(.bottom, 8)
            
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingSlide(
        icon: "flame.fill",
        title: "Theo dõi Calories",
        description: "Log bữa ăn nhanh chóng, chính xác mỗi ngày"
    )
}
