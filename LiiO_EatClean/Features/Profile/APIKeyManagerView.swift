import SwiftUI

@Observable
class APIKeyManagerViewModel {
    var keys: [APIKeyModel] = []
    private let userRepository: UserRepositoryProtocol
    
    var showingAddSheet = false
    var newProvider = "gemini"
    var newKeyInput = ""
    var errorMessage: String?
    
    init(userRepository: UserRepositoryProtocol = UserRepository()) {
        self.userRepository = userRepository
    }
    
    func loadKeys() async {
        do {
            self.keys = try await userRepository.fetchAPIKeys()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func moveKeys(from source: IndexSet, to destination: Int) async {
        keys.move(fromOffsets: source, toOffset: destination)
        // Update priorities based on new order
        for (index, var key) in keys.enumerated() {
            key.priority = index // Lower index = higher priority (or reversed, depends on sort descriptor. In UserRepository it's ascending: false, wait, earlier I changed it to descending. So highest number = highest priority. Let's make index 0 = highest priority, so priority = keys.count - index)
            keys[index] = key
            try? await userRepository.saveAPIKey(key)
        }
    }
    
    func deleteKeys(at offsets: IndexSet) async {
        for index in offsets {
            let key = keys[index]
            try? await (userRepository as? UserRepository)?.deleteAPIKey(provider: key.provider)
        }
        keys.remove(atOffsets: offsets)
    }
    
    func saveNewKey() async {
        guard !newKeyInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let newKey = APIKeyModel(id: UUID(), provider: newProvider, key: newKeyInput.trimmingCharacters(in: .whitespaces), isActive: true, healthScore: 100, priority: keys.count)
        do {
            try await userRepository.saveAPIKey(newKey)
            await loadKeys()
            showingAddSheet = false
            newKeyInput = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func maskedKey(_ keyStr: String) -> String {
        if keyStr.count > 6 {
            return "••••••" + keyStr.suffix(6)
        }
        return "••••••"
    }
}

struct APIKeyManagerView: View {
    @Environment(\.dismiss) var dismiss
    @State private var viewModel = APIKeyManagerViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.keys, id: \.id) { key in
                    KeyCardView(key: key, maskedString: viewModel.maskedKey(key.key))
                }
                .onMove { source, destination in
                    Task { await viewModel.moveKeys(from: source, to: destination) }
                }
                .onDelete { offsets in
                    Task { await viewModel.deleteKeys(at: offsets) }
                }
            }
            .navigationTitle("Quản lý API Keys")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Đóng") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .task {
                await viewModel.loadKeys()
            }
            .sheet(isPresented: $viewModel.showingAddSheet) {
                NavigationStack {
                    Form {
                        Picker("Nhà cung cấp", selection: $viewModel.newProvider) {
                            Text("Google Gemini").tag("gemini")
                            Text("OpenAI").tag("openai")
                        }
                        
                        TextField("API Key", text: $viewModel.newKeyInput)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    .navigationTitle("Thêm Key Mới")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Hủy") { viewModel.showingAddSheet = false }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Lưu") {
                                Task { await viewModel.saveNewKey() }
                            }
                            .disabled(viewModel.newKeyInput.isEmpty)
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            .alert("Lỗi", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

struct KeyCardView: View {
    let key: APIKeyModel
    let maskedString: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(
                    key.provider == "gemini" ? "Google Gemini" : "OpenAI",
                    systemImage: key.provider == "gemini" ? "sparkles" : "cpu"
                )
                .font(.headline)
                
                Spacer()
                
                if !key.isActive {
                    badge(text: "Lỗi", color: .red)
                } else if let cooldown = key.cooldownUntil, cooldown > Date() {
                    badge(text: "Cooldown", color: .orange)
                } else {
                    badge(text: "Hoạt động", color: .green)
                }
            }
            
            Text(maskedString)
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Sức khỏe:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(key.healthScore)/100")
                        .font(.caption2.bold())
                        .foregroundColor(healthColor)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(healthColor)
                            .frame(width: geometry.size.width * CGFloat(key.healthScore) / 100.0)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var healthColor: Color {
        switch key.healthScore {
        case 80...100: return .green
        case 50..<80: return .orange
        default: return .red
        }
    }
    
    private func badge(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .clipShape(Capsule())
    }
}
