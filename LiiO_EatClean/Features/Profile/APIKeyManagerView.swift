import SwiftUI

@Observable
class APIKeyManagerViewModel {
    var keys: [APIKeyModel] = []
    private let userRepository: UserRepositoryProtocol
    
    var showingAddSheet = false
    var isTesting = false
    var newProvider = "gemini"
    var newKeyName = ""
    var newKeyInput = ""
    var newIsPaid = false
    var errorMessage: String?
    
    init(userRepository: UserRepositoryProtocol = UserRepository()) {
        self.userRepository = userRepository
    }
    
    var freeGeminiKeys: [APIKeyModel] {
        keys.filter { $0.provider == "gemini" && $0.isPaid != true }
    }
    
    var paidGeminiKeys: [APIKeyModel] {
        keys.filter { $0.provider == "gemini" && $0.isPaid == true }
    }
    
    var openAIKeys: [APIKeyModel] {
        keys.filter { $0.provider == "openai" }
    }
    
    func loadKeys() async {
        do {
            self.keys = try await userRepository.fetchAPIKeys()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func moveKeys(from source: IndexSet, to destination: Int, in group: String) async {
        var providerKeys: [APIKeyModel]
        if group == "paid-gemini" {
            providerKeys = paidGeminiKeys
        } else if group == "free-gemini" {
            providerKeys = freeGeminiKeys
        } else {
            providerKeys = openAIKeys
        }
        
        providerKeys.move(fromOffsets: source, toOffset: destination)
        
        // Combine back and update priorities
        let currentGroupIDs = Set(providerKeys.map { $0.id })
        let otherKeys = keys.filter { !currentGroupIDs.contains($0.id) }
        let updatedKeys = (providerKeys + otherKeys)
        
        for (index, var key) in updatedKeys.enumerated() {
            key.priority = updatedKeys.count - index
            try? await userRepository.saveAPIKey(key)
        }
        await loadKeys()
    }
    
    func deleteKey(_ key: APIKeyModel) async {
        try? await userRepository.deleteAPIKey(id: key.id)
        await loadKeys()
    }
    
    func saveNewKey() async {
        guard !newKeyInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        isTesting = true
        defer { isTesting = false }
        
        var apiVersion: String? = nil
        var isPaid: Bool = newIsPaid
        
        // Test the key before saving
        do {
            if newProvider == "gemini" {
                let result = try await AIService.shared.testGeminiKey(newKeyInput.trimmingCharacters(in: .whitespaces))
                apiVersion = result.version
                isPaid = result.isPaid // Use auto-detected status
            } else {
                _ = try await AIService.shared.testOpenAIKey(newKeyInput.trimmingCharacters(in: .whitespaces))
            }
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        let newKey = APIKeyModel(
            id: UUID(), 
            name: newKeyName.isEmpty ? nil : newKeyName,
            provider: newProvider, 
            key: newKeyInput.trimmingCharacters(in: .whitespaces), 
            isActive: true, 
            healthScore: 100, 
            priority: keys.count,
            apiVersion: apiVersion,
            isPaid: isPaid
        )
        
        do {
            try await userRepository.saveAPIKey(newKey)
            await loadKeys()
            showingAddSheet = false
            newKeyInput = ""
            newKeyName = ""
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
                if !viewModel.paidGeminiKeys.isEmpty {
                    Section("Google Gemini (PAID)") {
                        ForEach(viewModel.paidGeminiKeys) { key in
                            KeyCardView(key: key, maskedString: viewModel.maskedKey(key.key))
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                let key = viewModel.paidGeminiKeys[index]
                                Task { await viewModel.deleteKey(key) }
                            }
                        }
                    }
                }
                
                if !viewModel.freeGeminiKeys.isEmpty {
                    Section("Google Gemini (FREE)") {
                        ForEach(viewModel.freeGeminiKeys) { key in
                            KeyCardView(key: key, maskedString: viewModel.maskedKey(key.key))
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                let key = viewModel.freeGeminiKeys[index]
                                Task { await viewModel.deleteKey(key) }
                            }
                        }
                    }
                }
                
                if !viewModel.openAIKeys.isEmpty {
                    Section("OpenAI") {
                        ForEach(viewModel.openAIKeys) { key in
                            KeyCardView(key: key, maskedString: viewModel.maskedKey(key.key))
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                let key = viewModel.openAIKeys[index]
                                Task { await viewModel.deleteKey(key) }
                            }
                        }
                    }
                }
                
                if viewModel.keys.isEmpty {
                    ContentUnavailableView("Chưa có API Key", systemImage: "key.fill", description: Text("Thêm key để sử dụng các tính năng AI."))
                }
            }
            .navigationTitle("Quản lý API Keys")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Đóng") { dismiss() }
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
                        Section("Thông tin Key") {
                            Picker("Nhà cung cấp", selection: $viewModel.newProvider) {
                                Text("Google Gemini").tag("gemini")
                                Text("OpenAI").tag("openai")
                            }
                            
                            TextField("Tên gợi nhớ (không bắt buộc)", text: $viewModel.newKeyName)
                            
                            TextField("API Key", text: $viewModel.newKeyInput)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            
                            if viewModel.newProvider == "gemini" {
                                Text("Tự động kiểm tra loại Key (Free/Paid) khi lưu")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .navigationTitle("Thêm Key Mới")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Hủy") { viewModel.showingAddSheet = false }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            if viewModel.isTesting {
                                ProgressView()
                            } else {
                                Button("Lưu") {
                                    Task { await viewModel.saveNewKey() }
                                }
                                .disabled(viewModel.newKeyInput.isEmpty)
                            }
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
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName)
                        .font(.headline)
                    
                    if let version = key.apiVersion {
                        Text(version)
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                
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
    
    private var displayName: String {
        let name = key.name ?? (key.provider == "gemini" ? "Gemini Key" : "OpenAI Key")
        if key.provider == "gemini" {
            let status = key.isPaid == true ? "Paid" : "Free"
            return "\(name) - \(status)"
        }
        return name
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
