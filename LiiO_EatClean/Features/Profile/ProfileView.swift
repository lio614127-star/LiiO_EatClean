import SwiftUI

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()
    @State private var showingSaveAlert = false
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Personal Info
                Section {
                    HStack {
                        Label("Tên", systemImage: "person")
                        Spacer()
                        TextField("Họ và tên", text: $viewModel.name)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Tuổi", systemImage: "calendar")
                        Spacer()
                        TextField("VD: 25", text: $viewModel.age)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Chiều cao (cm)", systemImage: "ruler")
                        Spacer()
                        TextField("VD: 170", text: $viewModel.height)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Cân nặng (kg)", systemImage: "scalemass")
                        Spacer()
                        TextField("VD: 65.5", text: $viewModel.weight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Thông tin cá nhân")
                }
                
                // MARK: - Goals
                Section {
                    Picker("Mục tiêu", selection: $viewModel.goalType) {
                        ForEach(viewModel.goalOptions, id: \.self) { option in
                            Text(viewModel.goalLabel(for: option)).tag(option)
                        }
                    }
                    
                    HStack {
                        Label("Calo mục tiêu / ngày", systemImage: "flame")
                        Spacer()
                        TextField("VD: 2000", text: $viewModel.dailyCalorieTarget)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Mục tiêu")
                }
                
                // MARK: - Reminders
                Section {
                    Toggle("Bật nhắc nhở", isOn: $viewModel.remindersEnabled)
                        .onChange(of: viewModel.remindersEnabled) { _, _ in
                            Task { await viewModel.updateReminders() }
                        }
                    
                    if viewModel.remindersEnabled {
                        Stepper(value: $viewModel.reminderStartHour, in: 5...12) {
                            HStack {
                                Text("Bắt đầu")
                                Spacer()
                                Text("\(viewModel.reminderStartHour):00")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onChange(of: viewModel.reminderStartHour) { _, _ in
                            Task { await viewModel.updateReminders() }
                        }
                        
                        Stepper(value: $viewModel.reminderEndHour, in: 12...23) {
                            HStack {
                                Text("Kết thúc")
                                Spacer()
                                Text("\(viewModel.reminderEndHour):00")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onChange(of: viewModel.reminderEndHour) { _, _ in
                            Task { await viewModel.updateReminders() }
                        }
                        
                        Stepper(value: $viewModel.reminderIntervalHours, in: 1...6) {
                            HStack {
                                Text("Mỗi")
                                Spacer()
                                Text("\(viewModel.reminderIntervalHours) giờ")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onChange(of: viewModel.reminderIntervalHours) { _, _ in
                            Task { await viewModel.updateReminders() }
                        }
                    }
                } header: {
                    Text("Nhắc nhở")
                } footer: {
                    Text("Nhắc nhở uống nước và ghi lại bữa ăn tự động trong ngày.")
                        .font(.caption2)
                }
                
                // MARK: - API Keys
                Section {
                    // Gemini Key
                    if viewModel.hasGeminiKey {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text("Google Gemini")
                                    .font(.subheadline.bold())
                                Text(viewModel.maskedKey(for: "gemini"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button(role: .destructive) {
                                Task { await viewModel.deleteKey(provider: "gemini") }
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Google Gemini", systemImage: "sparkles")
                                .font(.subheadline.bold())
                            HStack {
                                TextField("Nhập Gemini API Key...", text: $viewModel.geminiKeyInput)
                                    .font(.caption)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .textContentType(.oneTimeCode)
                                    .keyboardType(.asciiCapable)
                                Button("Lưu") {
                                    Task { await viewModel.saveGeminiKey() }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                                .controlSize(.small)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // OpenAI Key
                    if viewModel.hasOpenAIKey {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text("OpenAI (Backup)")
                                    .font(.subheadline.bold())
                                Text(viewModel.maskedKey(for: "openai"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button(role: .destructive) {
                                Task { await viewModel.deleteKey(provider: "openai") }
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("OpenAI (Backup)", systemImage: "cpu")
                                .font(.subheadline.bold())
                            HStack {
                                TextField("Nhập OpenAI API Key...", text: $viewModel.openAIKeyInput)
                                    .font(.caption)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .textContentType(.oneTimeCode)
                                    .keyboardType(.asciiCapable)
                                Button("Lưu") {
                                    Task { await viewModel.saveOpenAIKey() }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.blue)
                                .controlSize(.small)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("AI API Keys")
                } footer: {
                    Text("Key được lưu mã hóa cục bộ trên thiết bị. Gemini được ưu tiên, OpenAI là backup tự động.")
                        .font(.caption2)
                }
            }
            .navigationTitle("Hồ sơ")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Lưu") {
                        Task {
                            await viewModel.saveProfile()
                            showingSaveAlert = true
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Đã lưu!", isPresented: $showingSaveAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Thông tin của bạn đã được cập nhật.")
            }
            .alert("Lỗi", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK", role: .cancel) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .task {
            await viewModel.loadData()
        }
    }
}

#Preview {
    ProfileView()
}
