import SwiftUI

struct VoiceAssistantSettingsView: View {
    @Environment(AssistantVoiceSettings.self) var settings
    @Environment(GlobalVoiceAssistantManager.self) var voiceManager
    @Environment(\.dismiss) var dismiss
    
    @State private var showAddCustomResponse = false
    @State private var newResponseText = ""
    @State private var permissionMessage: String? = nil
    
    // UI State
    @State private var isWakeResponseSectionExpanded: Bool = false
    @State private var showDiagnostics: Bool = false
    
    var body: some View {
        @Bindable var settings = settings
        
        List {
            // MARK: - Activation
            Section {
                Toggle("Gọi AI bằng giọng nói trong app", isOn: wakeToggleBinding)
                    .tint(.green)
                
                if let permissionMessage {
                    Text(permissionMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            } header: {
                Text("Kích hoạt")
            } footer: {
                if settings.globalWakeEnabled {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Trợ lý sẽ lắng nghe khi app đang mở.")
                        Text("Thử nói: \"\(settings.assistantName) ơi\" hoặc \"Hey \(settings.assistantName)\"")
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                } else {
                    Text("Cho phép bạn gọi trợ lý rảnh tay mà không cần nhấn nút.")
                }
            }
            
            // MARK: - Assistant Profile
            Section {
                HStack {
                    Text("Tên trợ lý")
                    Spacer()
                    TextField("Tên hiển thị", text: $settings.assistantName)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.secondary)
                        .autocorrectionDisabled()
                }
                
                HStack {
                    Text("Cách đọc tên")
                    Spacer()
                    TextField("Phiên âm (optional)", text: $settings.assistantNamePronunciation)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.secondary)
                        .autocorrectionDisabled()
                }
                
                if settings.assistantName.count < 2 {
                    Text("Tên quá ngắn có thể gây nhầm lẫn khi nhận diện.")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            } header: {
                Text("Hồ sơ trợ lý")
            } footer: {
                Text("Dùng 'Cách đọc tên' nếu AI phát âm sai tên riêng (VD: LiiO -> Li ô).")
            }
            
            // MARK: - Wake Response Style
            Section {
                DisclosureGroup(isExpanded: $isWakeResponseSectionExpanded) {
                    VStack(spacing: 16) {
                        Picker("Chế độ phản hồi", selection: $settings.wakeResponseMode) {
                            Text("Cố định").tag("fixed")
                            Text("Ngẫu nhiên").tag("random")
                        }
                        .pickerStyle(.segmented)
                        .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(settings.allWakeResponses) { option in
                                Button(action: {
                                    handleResponseSelection(option)
                                }) {
                                    HStack {
                                        Text(option.text)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        if isSelected(option) {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.green)
                                                .font(.system(size: 14, weight: .bold))
                                        }
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 12)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                
                                if option.id != settings.allWakeResponses.last?.id {
                                    Divider().padding(.horizontal, 12)
                                }
                            }
                        }
                        .background(Color(UIColor.secondarySystemBackground).opacity(0.5))
                        .cornerRadius(12)
                        .padding(.top, 4)
                        
                        Button(action: { showAddCustomResponse = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Thêm câu trả lời riêng")
                            }
                            .foregroundColor(.green)
                            .padding(.vertical, 4)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Button("Test câu phản hồi") {
                        voiceManager.startTestWakeResponse()
                    }
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.top, 4)
                } label: {
                    HStack {
                        Text("Câu trả lời khi được gọi")
                        Spacer()
                        Text(responseSubtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            } header: {
                Text("Phản hồi kích hoạt")
            }
            
            // MARK: - AI Voice Selection
            Section {
                Picker("Giọng đọc AI", selection: $settings.selectedTTSVoice) {
                    VStack(alignment: .leading) {
                        Text("Hoài My (Nữ)")
                        Text("vi-VN-HoaiMyNeural · Microsoft Neural").font(.caption2).foregroundColor(.secondary)
                    }.tag("vi-VN-HoaiMyNeural")
                    
                    VStack(alignment: .leading) {
                        Text("Nam Minh (Nam)")
                        Text("vi-VN-NamMinhNeural · Microsoft Neural").font(.caption2).foregroundColor(.secondary)
                    }.tag("vi-VN-NamMinhNeural")
                }
                .pickerStyle(.navigationLink)
                
                Picker("Chế độ giọng nói", selection: $settings.ttsEngineMode) {
                    ForEach(TTSEngineMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode.rawValue)
                    }
                }
            } footer: {
                Text("Azure Neural cung cấp giọng đọc tự nhiên nhất nhưng cần kết nối mạng.")
            }
            
            // MARK: - Voice Tuning
            Section {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Tốc độ")
                        Spacer()
                        Text(rateLabel(settings.ttsRate))
                            .font(.caption).foregroundColor(.secondary)
                    }
                    Slider(value: $settings.ttsRate, in: 0.85...1.15, step: 0.15)
                }
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Cao độ")
                        Spacer()
                        Text(pitchLabel(settings.ttsPitch))
                            .font(.caption).foregroundColor(.secondary)
                    }
                    Slider(value: $settings.ttsPitch, in: 0.9...1.1, step: 0.1)
                }
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Âm lượng")
                        Spacer()
                        Text("\(Int(settings.ttsVolume * 100))%")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    Slider(value: $settings.ttsVolume, in: 0.5...1.0, step: 0.1)
                }
            } header: {
                Text("Tuỳ chỉnh giọng đọc")
            }
            
            // MARK: - AI Response Behavior
            Section {
                Picker("Phong cách mặc định", selection: $settings.defaultResponseStyle) {
                    ForEach(AssistantResponseStyle.allCases, id: \.self) { style in
                        Text(style.displayName).tag(style.rawValue)
                    }
                }
                
                NavigationLink(destination: IntentResponseStylesListView()) {
                    HStack {
                        Text("Cách trả lời theo tình huống")
                        Spacer()
                        Text("\(settings.intentResponseStyles.count) tùy chỉnh")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Picker("Độ dài phản hồi", selection: $settings.voiceResponseLength) {
                    ForEach(VoiceResponseLength.allCases, id: \.self) { length in
                        Text(length.displayName).tag(length.rawValue)
                    }
                }
            } header: {
                Text("Cấu hình phản hồi AI")
            }
            
            // MARK: - Audio Settings
            Section {
                Toggle("Tự động gửi sau khi nói", isOn: $settings.autoSendAfterSpeech)
                Toggle("Trả lời bằng giọng nói (TTS)", isOn: $settings.voiceReplyEnabled)
            } header: {
                Text("Âm thanh & Điều khiển")
            }
            
            // MARK: - Diagnostics (Senior Debug)
            #if DEBUG
            Section {
                Toggle("Hiện chẩn đoán Voice", isOn: $showDiagnostics)
                
                if showDiagnostics {
                    Group {
                        DiagnosticRow(label: "AI Name", value: settings.assistantName)
                        DiagnosticRow(label: "Audio Engine", value: voiceManager.audioEngineRunning ? "Running" : "Stopped", color: voiceManager.audioEngineRunning ? .green : .red)
                        DiagnosticRow(label: "Current State", value: "\(voiceManager.state)")
                        DiagnosticRow(label: "Audio Level", value: String(format: "%.4f", voiceManager.audioLevel))
                        DiagnosticRow(label: "TTS Engine", value: voiceManager.activeTTSEngineName)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Assistant Aliases:").font(.caption).bold()
                            Text(voiceManager.activeAliases.joined(separator: ", "))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text("Stable Wake Phrases:").font(.caption).bold()
                            Text(voiceManager.activeWakePhrases.joined(separator: ", "))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        
                        Divider()
                        
                        DiagnosticRow(label: "Raw Transcript", value: voiceManager.lastRawTranscript.isEmpty ? "None" : voiceManager.lastRawTranscript)
                        DiagnosticRow(label: "Norm Transcript", value: voiceManager.lastNormalizedTranscript.isEmpty ? "None" : voiceManager.lastNormalizedTranscript)
                        DiagnosticRow(label: "Match Result", value: voiceManager.lastWakeMatch ? "MATCHED" : "No Match", color: voiceManager.lastWakeMatch ? .green : .orange)
                        DiagnosticRow(label: "Matched By", value: voiceManager.lastMatchedBy)
                    }
                    
                    VStack(spacing: 12) {
                        HStack {
                            Button("Test Micro (Real Gate)") {
                                voiceManager.startListening()
                            }
                            .buttonStyle(.bordered)
                            .frame(maxWidth: .infinity)
                            
                            Button("Test Speech") {
                                voiceManager.startSpeechTest()
                            }
                            .buttonStyle(.bordered)
                            .frame(maxWidth: .infinity)
                        }
                        
                        HStack {
                            Button("Test Wake") {
                                voiceManager.startWakeTest()
                            }
                            .buttonStyle(.bordered)
                            .frame(maxWidth: .infinity)
                            
                            Button("Test Voice") {
                                voiceManager.speakResponse("Xin chào, mình là \(settings.assistantSpokenName). Đây là giọng đọc bạn đang chọn.")
                            }
                            .buttonStyle(.bordered)
                            .frame(maxWidth: .infinity)
                        }
                        
                        HStack {
                            Button("Test Overlay") {
                                voiceManager.showTestOverlay()
                            }
                            .buttonStyle(.bordered)
                            .frame(maxWidth: .infinity)
                            
                            Button("Stop & Reset") {
                                voiceManager.stopListening()
                                voiceManager.errorMessage = nil
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 8)
                }
            } header: {
                Text("Công cụ Chẩn đoán (Debug)")
            }
            #endif
        }
        .navigationTitle("Cài đặt Voice")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddCustomResponse) {
            NavigationStack {
                Form {
                    TextField("Ví dụ: Dạ, mình đây!", text: $newResponseText)
                        .autocorrectionDisabled()
                }
                .navigationTitle("Câu trả lời mới")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Hủy") { showAddCustomResponse = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Lưu") {
                            if !newResponseText.isEmpty {
                                settings.addCustomWakeResponse(newResponseText)
                                newResponseText = ""
                                showAddCustomResponse = false
                            }
                        }
                    }
                }
            }
            .presentationDetents([.height(200)])
        }
        .task {
            let result = await voiceManager.checkPermissions()
            if !result.canUseVoiceAssistant && settings.globalWakeEnabled {
                permissionMessage = result.message
            }
        }
    }
    
    // MARK: - Logic Helpers
    
    private var responseSubtitle: String {
        if settings.wakeResponseMode == "fixed" {
            return settings.allWakeResponses.first(where: { $0.id == settings.selectedWakeResponseId })?.text ?? "Chưa chọn"
        } else {
            return "Ngẫu nhiên (\(settings.enabledRandomResponseIds.count))"
        }
    }
    
    private func isSelected(_ option: WakeResponseOption) -> Bool {
        if settings.wakeResponseMode == "fixed" {
            return settings.selectedWakeResponseId == option.id
        } else {
            return settings.enabledRandomResponseIds.contains(option.id)
        }
    }
    
    private func handleResponseSelection(_ option: WakeResponseOption) {
        if settings.wakeResponseMode == "fixed" {
            settings.selectedWakeResponseId = option.id
        } else {
            var enabled = settings.enabledRandomResponseIds
            if enabled.contains(option.id) {
                if enabled.count > 1 {
                    enabled.remove(option.id)
                }
            } else {
                enabled.insert(option.id)
            }
            settings.enabledRandomResponseIds = enabled
        }
    }
    
    // MARK: - Custom Binding for Activation
    
    private var wakeToggleBinding: Binding<Bool> {
        Binding(
            get: { settings.globalWakeEnabled },
            set: { newValue in
                if newValue {
                    Task {
                        let result = await voiceManager.requestPermissionsIfNeeded()
                        await MainActor.run {
                            if result.canUseVoiceAssistant {
                                settings.globalWakeEnabled = true
                                permissionMessage = nil
                                voiceManager.startListening()
                            } else {
                                settings.globalWakeEnabled = false
                                permissionMessage = result.message
                            }
                        }
                    }
                } else {
                    settings.globalWakeEnabled = false
                    voiceManager.stopListening()
                    permissionMessage = nil
                }
            }
        )
    }
    
    private func pitchLabel(_ val: Double) -> String {
        if val > 1.0 { return "Cao" }
        if val < 1.0 { return "Trầm" }
        return "Tự nhiên"
    }
    
    private func rateLabel(_ val: Double) -> String {
        if val > 1.0 { return "Nhanh" }
        if val < 1.0 { return "Chậm" }
        return "Vừa"
    }
}

struct DiagnosticRow: View {
    let label: String
    let value: String
    var color: Color = .primary
    
    var body: some View {
        HStack {
            Text(label).font(.caption)
            Spacer()
            Text(value).font(.caption).monospaced().foregroundColor(color)
        }
    }
}
