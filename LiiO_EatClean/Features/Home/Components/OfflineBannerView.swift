import SwiftUI

struct OfflineBannerView: View {
    var isConnected: Bool
    @State private var showRecoveryBanner = false
    @State private var wasDisconnected = false
    
    var body: some View {
        VStack(spacing: 0) {
            if !isConnected {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .font(.caption)
                    Text("Không có kết nối mạng")
                        .font(.caption.bold())
                    Spacer()
                    Text("Một số tính năng AI tạm ngưng")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.9))
                .transition(.move(edge: .top).combined(with: .opacity))
            } else if showRecoveryBanner {
                HStack(spacing: 8) {
                    Image(systemName: "wifi")
                        .font(.caption)
                    Text("Đã kết nối lại")
                        .font(.caption.bold())
                    Spacer()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.9))
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.4), value: isConnected)
        .animation(.spring(duration: 0.4), value: showRecoveryBanner)
        .onChange(of: isConnected) { oldValue, newValue in
            if !newValue {
                wasDisconnected = true
            } else if wasDisconnected {
                showRecoveryBanner = true
                wasDisconnected = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { showRecoveryBanner = false }
                }
            }
        }
    }
}
