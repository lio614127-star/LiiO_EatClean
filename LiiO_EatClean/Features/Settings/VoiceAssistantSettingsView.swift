import SwiftUI

struct VoiceAssistantSettingsView: View {
    @Environment(AssistantVoiceSettings.self) var settings
    @State private var showingCustomPhraseInput = false
    @State private var newCustomPhrase = ""
    
    private var wakePhraseDetector: WakePhraseDetector {
        WakePhraseDetector(assistantName: settings.assistantName)
    }
    
    var body: some View {
        List {
            // Section 1: Assistant Name
            Section("Tên trợ lý AI") {
                TextField("Tên", text: Binding(
                    get: { settings.assistantName },
                    set: { settings.assistantName = $0 }
                ))
                
                if wakePhraseDetector.isNameTooShort {
                    Label("Tên quá ngắn", systemImage: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
                if wakePhraseDetector.isNameTooCommon {
                    Label("Tên này có thể dễ bị nhận nhầm", systemImage: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
            }
            
            // Section 2: Wake Phrases
            Section("Câu gọi trợ lý") {
                ForEach(wakePhraseDetector.generateWakePhrases(name: settings.assistantName), id: \.self) { phrase in
                    Text("\"\(phrase)\"")
                        .foregroundColor(.secondary)
                }
            } footer: {
                Text("Những cụm từ này được tạo tự động từ tên trợ lý (không dấu).")
            }
            
            // Section 3: Wake Responses
            Section("Câu trả lời khi được gọi") {
                Picker("Chế độ trả lời", selection: $settings.wakeResponseMode) {
                    Text("Cố định").tag("fixed")
                    Text("Ngẫu nhiên").tag("random")
                }
                .pickerStyle(.segmented)
                
                if settings.wakeResponseMode == "fixed" {
                    Picker("Câu trả lời", selection: $settings.selectedWakeResponse) {
                        ForEach(AssistantVoiceSettings.presetWakeResponses, id: \.self) { phrase in
                            Text(phrase).tag(phrase)
                        }
                        ForEach(settings.customWakeResponses, id: \.self) { phrase in
                            Text(phrase).tag(phrase)
                        }
                    }
                } else {
                    Toggle("Bao gồm câu trả lời ngẫu nhiên", isOn: $settings.randomizeEnabled)
                }
                
                Button("Thêm câu trả lời riêng") {
                    showingCustomPhraseInput = true
                }
                .foregroundColor(.green)
            }
            
            // Section 4: Global Wake
            Section {
                Toggle("Gọi AI bằng giọng nói trong app", isOn: $settings.globalWakeEnabled)
            } footer: {
                Text("Khi bật, bạn có thể gọi trợ lý bất cứ lúc nào khi app đang mở. LiiO chỉ lắng nghe tại chỗ, không gửi dữ liệu ra ngoài cho đến khi bạn bắt đầu nói lệnh.")
            }
            
            // Section 5: Default Style
            Section("Phong cách trả lời mặc định") {
                ForEach(AssistantResponseStyle.allCases, id: \.self) { style in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(style.displayName)
                                .font(.body)
                            Text(style.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if settings.defaultResponseStyle == style.rawValue {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        settings.defaultResponseStyle = style.rawValue
                    }
                }
            }
            
            // Section 6: Per-Intent Styles
            Section("Cách trả lời theo tình huống") {
                NavigationLink(destination: IntentResponseStyleView(intentKey: "meal_logging", intentTitle: "Khi log món ăn")) {
                    Label("Khi log món ăn", systemImage: "fork.knife")
                }
                NavigationLink(destination: IntentResponseStyleView(intentKey: "plan_question", intentTitle: "Khi hỏi nên ăn gì")) {
                    Label("Khi hỏi nên ăn gì", systemImage: "calendar")
                }
                NavigationLink(destination: IntentResponseStyleView(intentKey: "cooking_advice", intentTitle: "Khi hỏi nấu ăn")) {
                    Label("Khi hỏi nấu ăn", systemImage: "flame")
                }
                NavigationLink(destination: IntentResponseStyleView(intentKey: "health_question", intentTitle: "Khi hỏi sức khỏe")) {
                    Label("Khi hỏi sức khỏe", systemImage: "heart")
                }
                NavigationLink(destination: IntentResponseStyleView(intentKey: "progress_question", intentTitle: "Khi hỏi tiến độ")) {
                    Label("Khi hỏi tiến độ", systemImage: "chart.line.uptrend.xyaxis")
                }
                NavigationLink(destination: IntentResponseStyleView(intentKey: "rebalance_request", intentTitle: "Khi AI Rebalance")) {
                    Label("Khi AI Rebalance", systemImage: "arrow.triangle.2.circlepath")
                }
            }
            
            // Section 7: Response Length
            Section("Độ dài câu trả lời bằng giọng nói") {
                ForEach(VoiceResponseLength.allCases, id: \.self) { length in
                    HStack {
                        Text(length.displayName)
                        Spacer()
                        if settings.voiceResponseLength == length.rawValue {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        settings.voiceResponseLength = length.rawValue
                    }
                }
            }
            
            // Section 8: General Toggles
            Section {
                Toggle("Tự gửi sau khi nói xong", isOn: $settings.autoSendAfterSpeech)
                Toggle("Trả lời bằng giọng nói (TTS)", isOn: $settings.voiceReplyEnabled)
            }
        }
        .navigationTitle("Trợ lý giọng nói")
        .alert("Thêm câu trả lời", isPresented: $showingCustomPhraseInput) {
            TextField("Nhập câu trả lời...", text: $newCustomPhrase)
            Button("Hủy", role: .cancel) { newCustomPhrase = "" }
            Button("Thêm") {
                if !newCustomPhrase.isEmpty {
                    settings.customWakeResponses.append(newCustomPhrase)
                    newCustomPhrase = ""
                }
            }
        }
    }
}
