import SwiftUI

struct MilestonePopupView: View {
    let milestone: Int
    @Binding var isPresented: Bool
    
    @State private var isVisible = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .opacity(isVisible ? 1 : 0)
                .onTapGesture {
                    dismiss()
                }
            
            VStack(spacing: 24) {
                Text("🌿")
                    .font(.system(size: milestone >= 30 ? 60 : 40))
                    .shadow(color: .green.opacity(0.5), radius: 10, x: 0, y: 5)
                
                VStack(spacing: 8) {
                    Text("🎉 Tuyệt vời!")
                        .font(.title2.bold())
                    
                    Text("\(milestone) ngày liên tiếp!")
                        .font(.title3.bold())
                        .foregroundColor(.green)
                    
                    Text(subtext)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
                
                Button(action: dismiss) {
                    Text("Tiếp tục")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding(.top, 8)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
            )
            .padding(40)
            .scaleEffect(isVisible ? 1.0 : 0.5)
            .opacity(isVisible ? 1.0 : 0.0)
        }
        .onAppear {
            HapticManager.milestone()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isVisible = true
            }
            
            // Auto dismiss after 4 seconds
            Task {
                try? await Task.sleep(nanoseconds: 4_000_000_000)
                if isVisible {
                    dismiss()
                }
            }
        }
    }
    
    private var subtext: String {
        switch milestone {
        case 7..<14:
            return "Bạn đang xây dựng thói quen tốt!"
        case 14..<30:
            return "Thói quen đang trở nên bền vững!"
        case 30...:
            return "Bạn là người kiên trì nhất! 🏆"
        default:
            return "Cố gắng duy trì nhé!"
        }
    }
    
    private func dismiss() {
        withAnimation(.easeIn(duration: 0.2)) {
            isVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isPresented = false
        }
    }
}
