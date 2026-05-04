import SwiftUI

struct MemorySummaryCard: View {
    @State private var memory = MemoryManager.shared.fetchMemory()
    
    var body: some View {
        Group {
            if memory.hasContent {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.green)
                        Text("AI nhớ về bạn")
                            .font(.subheadline.bold())
                        Spacer()
                        NavigationLink(destination: MemoryEditorView()) {
                            Text("Chỉnh sửa")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(memory.healthConditions) { condition in
                                TagView(text: condition.name, color: .red.opacity(0.1), textColor: .red)
                            }
                            ForEach(memory.likes.prefix(3), id: \.self) { like in
                                TagView(text: "❤️ " + like, color: .green.opacity(0.1), textColor: .green)
                            }
                            ForEach(memory.dislikes.prefix(3), id: \.self) { dislike in
                                TagView(text: "✗ " + dislike, color: .gray.opacity(0.1), textColor: .gray)
                            }
                        }
                    }
                }
                .padding(12)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(12)
            }
        }
        .onAppear {
            memory = MemoryManager.shared.fetchMemory()
        }
    }
}

struct TagView: View {
    let text: String
    let color: Color
    let textColor: Color
    
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .foregroundColor(textColor)
            .cornerRadius(8)
    }
}
