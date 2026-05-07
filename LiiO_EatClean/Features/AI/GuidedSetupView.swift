import SwiftUI

struct GuidedSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 1
    
    // Dependencies
    var onComplete: (UserProfileMemory) -> Void
    @State private var memory = UserProfileMemory()
    
    // Form States
    @State private var conditionName = ""
    @State private var conditionNotes = ""
    @State private var avoidFoodText = ""
    @State private var likeFoodText = ""
    @State private var dislikeFoodText = ""
    @State private var noteText = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Stepper
                ProgressView(value: Double(currentStep), total: 5.0)
                    .tint(.green)
                    .padding()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        switch currentStep {
                        case 1: step1HealthConditions
                        case 2: step2AvoidFoods
                        case 3: step3Likes
                        case 4: step4Dislikes
                        case 5: step5DietaryNotes
                        default: EmptyView()
                        }
                    }
                    .padding()
                }
                
                Spacer()
                
                HStack {
                    if currentStep > 1 {
                        Button("Quay lại") {
                            withAnimation { currentStep -= 1 }
                        }
                        .buttonStyle(.bordered)
                        .tint(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(currentStep < 5 ? "Tiếp tục" : "Hoàn tất") {
                        if currentStep < 5 {
                            saveCurrentStep()
                            withAnimation { currentStep += 1 }
                        } else {
                            saveCurrentStep()
                            onComplete(memory)
                            dismiss()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
                .padding()
                .background(Color(.systemBackground).shadow(radius: 2, y: -2))
            }
            .navigationTitle("Thiết lập AI Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Bỏ qua") {
                        dismiss()
                    }
                    .tint(.secondary)
                }
            }
        }
    }
    
    private func saveCurrentStep() {
        if currentStep == 1 && !conditionName.isEmpty {
            memory.healthConditions.append(HealthConditionModel(name: conditionName, dietaryNotes: conditionNotes))
            conditionName = ""
            conditionNotes = ""
        } else if currentStep == 2 && !avoidFoodText.isEmpty {
            memory.avoidFoods.append(contentsOf: avoidFoodText.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
            avoidFoodText = ""
        } else if currentStep == 3 && !likeFoodText.isEmpty {
            memory.likes.append(contentsOf: likeFoodText.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
            likeFoodText = ""
        } else if currentStep == 4 && !dislikeFoodText.isEmpty {
            memory.dislikes.append(contentsOf: dislikeFoodText.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
            dislikeFoodText = ""
        } else if currentStep == 5 && !noteText.isEmpty {
            memory.dietaryNotes.append(noteText)
            noteText = ""
        }
    }
    
    // MARK: - Steps Views
    
    private var step1HealthConditions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Bước 1: Bệnh lý")
                .font(.title2.bold())
            Text("Bạn có đang mắc bệnh lý nào cần AI lưu ý không? (vd: Tiểu đường, Cao huyết áp...)")
                .foregroundColor(.secondary)
            
            TextField("Tên bệnh lý...", text: $conditionName)
                .textFieldStyle(.roundedBorder)
            
            if !conditionName.isEmpty {
                TextField("Lưu ý cho bệnh này (tùy chọn)...", text: $conditionNotes)
                    .textFieldStyle(.roundedBorder)
            }
            
            if !memory.healthConditions.isEmpty {
                Text("Đã thêm:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                ForEach(memory.healthConditions) { hc in
                    Text("• \(hc.name)")
                }
            }
        }
    }
    
    private var step2AvoidFoods: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Bước 2: Kiêng cữ")
                .font(.title2.bold())
            Text("Có món nào bạn tuyệt đối không được ăn vì lý do sức khoẻ hoặc dị ứng không? (Cách nhau bằng dấu phẩy)")
                .foregroundColor(.secondary)
            
            TextField("Đậu phộng, hải sản, đồ sống...", text: $avoidFoodText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...5)
        }
    }
    
    private var step3Likes: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Bước 3: Sở thích")
                .font(.title2.bold())
            Text("Món ăn yêu thích của bạn là gì? AI sẽ ưu tiên gợi ý các món này. (Cách nhau bằng dấu phẩy)")
                .foregroundColor(.secondary)
            
            TextField("Phở bò, bún chả, salad...", text: $likeFoodText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...5)
        }
    }
    
    private var step4Dislikes: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Bước 4: Không thích")
                .font(.title2.bold())
            Text("Món nào bạn không muốn ăn nhưng không phải do dị ứng? (Cách nhau bằng dấu phẩy)")
                .foregroundColor(.secondary)
            
            TextField("Hành lá, rau mùi, đồ chiên dầu mỡ...", text: $dislikeFoodText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...5)
        }
    }
    
    private var step5DietaryNotes: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Bước 5: Ghi chú khác")
                .font(.title2.bold())
            Text("Còn lưu ý đặc biệt nào về chế độ ăn của bạn không? (vd: Đang theo Keto, ăn chay trường, nhịn ăn gián đoạn...)")
                .foregroundColor(.secondary)
            
            TextField("Chế độ ăn, thói quen...", text: $noteText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...5)
        }
    }
}
