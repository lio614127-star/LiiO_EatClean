import SwiftUI

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()
    @State private var showingSaveAlert = false
    @State private var showingResetConfirmation = false
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
                    Text("Nhắc nhở uống nước, ghi bữa ăn, và tổng kết dinh dưỡng cuối ngày (20:00).")
                        .font(.caption2)
                }
                
                // MARK: - API Keys
                Section {
                    Button(action: {
                        viewModel.showingKeyManager = true
                    }) {
                        HStack {
                            Label("Quản lý API Keys", systemImage: "key.fill")
                            Spacer()
                            Text("\(viewModel.apiKeysCount) keys")
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.primary)
                } header: {
                    Text("AI API Keys")
                } footer: {
                    Text("Cấu hình nhiều API keys để hệ thống tự động fallback khi gặp lỗi.")
                        .font(.caption2)
                }
                
                // MARK: - Danger Zone
                Section {
                    Button(role: .destructive) {
                        showingResetConfirmation = true
                    } label: {
                        HStack {
                            Label("Xóa sạch dữ liệu", systemImage: "trash.fill")
                            Spacer()
                            Text("Reset app")
                                .font(.caption)
                        }
                    }
                } header: {
                    Text("Vùng nguy hiểm")
                } footer: {
                    Text("Hành động này sẽ xóa vĩnh viễn toàn bộ lịch sử ăn uống, cân nặng và nước uống. Không thể hoàn tác.")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Hồ sơ")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Lưu") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
            .alert("Xác nhận xóa?", isPresented: $showingResetConfirmation) {
                Button("Xóa tất cả", role: .destructive) {
                    Task { await viewModel.resetAllData() }
                }
                Button("Hủy", role: .cancel) {}
            } message: {
                Text("Bạn có chắc chắn muốn xóa sạch toàn bộ lịch sử? Hành động này không thể hoàn tác.")
            }
        }
        .fullScreenCover(isPresented: $viewModel.showingKeyManager) {
            APIKeyManagerView()
        }
        .onAppear {
            Task {
                await viewModel.loadData()
            }
        }
    }
}

#Preview {
    ProfileView()
}
