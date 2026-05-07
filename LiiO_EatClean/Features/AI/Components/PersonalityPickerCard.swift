import SwiftUI

struct PersonalityPickerCard: View {
    @Binding var currentTone: AIPersonalityTone
    var onToneSelected: (AIPersonalityTone) -> Void
    
    @State private var showingPreview: Bool = false
    @State private var previewText: String = ""
    
    private let tones = AIPersonalityTone.allCases
    private let haptic = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        MemoryCard(title: "Tính cách AI", icon: "brain.head.profile", color: .green) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Chọn phong cách giao tiếp bạn muốn AI sử dụng:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 8) {
                    ForEach(tones, id: \.self) { tone in
                        Button(action: {
                            selectTone(tone)
                        }) {
                            HStack {
                                Text(tone.rawValue)
                                    .font(.subheadline)
                                Spacer()
                                if currentTone == tone {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                            .padding()
                            .background(currentTone == tone ? Color.green.opacity(0.1) : Color(.tertiarySystemGroupedBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(currentTone == tone ? Color.green.opacity(0.5) : Color.clear, lineWidth: 1)
                            )
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                if showingPreview {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.green)
                            Text("Xem trước phong cách:")
                                .font(.caption.bold())
                                .foregroundColor(.green)
                        }
                        
                        Text(previewText)
                            .font(.subheadline)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentTone)
        .animation(.easeInOut(duration: 0.2), value: showingPreview)
    }
    
    private func selectTone(_ tone: AIPersonalityTone) {
        haptic.impactOccurred()
        currentTone = tone
        onToneSelected(tone)
        
        // Show preview
        switch tone {
        case .friendly:
            previewText = "Hôm nay bạn làm khá tốt rồi đó 👏 Chỉ cần thêm chút protein nữa là đẹp!"
        case .expert:
            previewText = "Lượng protein hiện chưa đủ. Bạn nên tăng thêm khoảng 20-25g protein/ngày."
        case .disciplined:
            previewText = "Bạn đã vượt target 3 ngày. Ngày mai cần siết lại đồ ngọt."
        case .chill:
            previewText = "Không sao đâu 😄 Một bữa ăn chưa hoàn hảo không phá hỏng cả hành trình."
        case .humorous:
            previewText = "Phở bò lần thứ 5 tuần này detected 🚨😂"
        }
        
        showingPreview = true
        
        // Auto-hide preview after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if currentTone == tone { // Only hide if they haven't tapped another one
                showingPreview = false
            }
        }
    }
}
