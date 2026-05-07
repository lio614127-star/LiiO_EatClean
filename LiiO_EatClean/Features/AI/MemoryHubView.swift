import SwiftUI

struct MemoryHubView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = MemoryHubViewModel()
    
    var body: some View {
        NavigationStack {
            Group {
                if !viewModel.hasMemoryData {
                    emptyStateView
                } else {
                    memoryContentView
                }
            }
            .navigationTitle("AI Memory Hub")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $viewModel.showGuidedSetup) {
                GuidedSetupView(onComplete: { memory in
                    Task {
                        try? await viewModel.memoryRepository.saveMemory(memory)
                        await viewModel.loadData()
                    }
                })
            }
            .task {
                await viewModel.loadData()
            }
        }
    }
    
    // MARK: - Views
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "brain.head.profile")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.green)
                .padding()
                .background(Circle().fill(Color.green.opacity(0.1)))
            
            Text("AI chưa hiểu rõ về bạn")
                .font(.title2.bold())
            
            Text("Thêm bệnh lý, món yêu thích và các lưu ý để AI tư vấn chính xác và cá nhân hóa hơn.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                viewModel.showGuidedSetup = true
            }) {
                Text("Bắt đầu thiết lập AI Memory")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 32)
            .padding(.top, 16)
        }
        .padding()
    }
    
    private var memoryContentView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Profile Card
                if let profile = viewModel.userProfile {
                    ProfileCard(profile: profile)
                }
                
                // Health Conditions
                if !viewModel.currentMemory.healthConditions.isEmpty {
                    MemoryCard(title: "Bệnh lý & Sức khỏe", icon: "heart.text.square.fill") {
                        ForEach(viewModel.currentMemory.healthConditions) { hc in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(hc.name).font(.subheadline.bold())
                                if !hc.dietaryNotes.isEmpty {
                                    Text(hc.dietaryNotes).font(.caption).foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                
                // Avoid Foods
                if !viewModel.currentMemory.avoidFoods.isEmpty {
                    MemoryCard(title: "Kiêng cữ", icon: "exclamationmark.triangle.fill", color: .red) {
                        FlowLayout(spacing: 8) {
                            ForEach(viewModel.currentMemory.avoidFoods, id: \.self) { food in
                                ChipView(text: food, color: .red)
                            }
                        }
                    }
                }
                
                // Preferences
                if !viewModel.currentMemory.likes.isEmpty || !viewModel.currentMemory.dislikes.isEmpty {
                    MemoryCard(title: "Sở thích", icon: "star.fill") {
                        if !viewModel.currentMemory.likes.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Thích:").font(.caption).foregroundColor(.secondary)
                                FlowLayout(spacing: 8) {
                                    ForEach(viewModel.currentMemory.likes, id: \.self) { food in
                                        ChipView(text: food, color: .green)
                                    }
                                }
                            }
                        }
                        if !viewModel.currentMemory.dislikes.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Không thích:").font(.caption).foregroundColor(.secondary)
                                FlowLayout(spacing: 8) {
                                    ForEach(viewModel.currentMemory.dislikes, id: \.self) { food in
                                        ChipView(text: food, color: .orange)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Notes
                if !viewModel.currentMemory.dietaryNotes.isEmpty {
                    MemoryCard(title: "Ghi chú", icon: "note.text") {
                        ForEach(viewModel.currentMemory.dietaryNotes, id: \.self) { note in
                            Text("• \(note)").font(.subheadline)
                        }
                    }
                }
                
                // Personality Picker
                PersonalityPickerCard(
                    currentTone: $viewModel.currentMemory.personalityTone,
                    onToneSelected: { newTone in
                        Task {
                            try? await viewModel.memoryRepository.updatePersonalityTone(newTone)
                        }
                    }
                )
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Components

struct ProfileCard: View {
    let profile: UserModel
    var body: some View {
        MemoryCard(title: "Hồ sơ của bạn", icon: "person.crop.circle.fill") {
            HStack(spacing: 24) {
                VStack(alignment: .leading) {
                    Text("Chiều cao").font(.caption).foregroundColor(.secondary)
                    Text("\(Int(profile.height)) cm").font(.headline)
                }
                VStack(alignment: .leading) {
                    Text("Cân nặng").font(.caption).foregroundColor(.secondary)
                    Text("\(profile.weight, specifier: "%.1f") kg").font(.headline)
                }
                VStack(alignment: .leading) {
                    Text("Mục tiêu").font(.caption).foregroundColor(.secondary)
                    Text(profile.goalType).font(.headline)
                }
                Spacer()
            }
            Divider()
            HStack {
                Text("Target Calories:")
                Spacer()
                Text("\(Int(profile.dailyCalorieTarget)) kcal")
                    .font(.headline)
                    .foregroundColor(.green)
            }
        }
    }
}

struct MemoryCard<Content: View>: View {
    let title: String
    let icon: String
    var color: Color = .green
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                Spacer()
            }
            
            content
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct ChipView: View {
    let text: String
    var color: Color = .green
    
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var height: CGFloat = 0
        var x: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for view in subviews {
            let viewSize = view.sizeThatFits(.unspecified)
            if x + viewSize.width > width {
                x = 0
                height += rowHeight + spacing
                rowHeight = 0
            }
            x += viewSize.width + spacing
            rowHeight = max(rowHeight, viewSize.height)
        }
        height += rowHeight
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        
        for view in subviews {
            let viewSize = view.sizeThatFits(.unspecified)
            if x + viewSize.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += viewSize.width + spacing
            rowHeight = max(rowHeight, viewSize.height)
        }
    }
}
