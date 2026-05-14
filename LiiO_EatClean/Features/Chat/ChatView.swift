import SwiftUI
import AVFoundation

struct ChatView: View {
    @State private var viewModel = ChatViewModel()
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    @State private var showMemoryHub = false
    @Environment(GlobalVoiceAssistantManager.self) var voiceManager
    
    @State private var hasMicPermission: Bool? = nil
    
    // Offline State
    private var isOffline: Bool { !NetworkMonitor.shared.isConnected }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.displayMessages) { message in
                                ActionableMessageView(
                                    message: message, 
                                    isStreaming: viewModel.isStreaming && message.id == viewModel.displayMessages.last?.id
                                ) { food in
                                    viewModel.logSuggestedFood(food)
                                }
                                .id(message.id)
                            }
                            
                            if viewModel.healthSafetyApplied {
                                HealthSafetyBadge(isHighSeverity: false)
                                    .padding(.top, 8)
                                    .transition(.opacity)
                                    .animation(.easeIn, value: viewModel.healthSafetyApplied)
                            }
                            
                            // Pending Message Status Indicators
                            ForEach(PendingChatQueue.shared.pendingMessages) { pending in
                                HStack(spacing: 4) {
                                    switch pending.status {
                                    case .pending:
                                        Image(systemName: "clock").font(.caption2)
                                        Text("Đang chờ kết nối...").font(.caption2)
                                    case .sending:
                                        ProgressView().controlSize(.mini)
                                        Text("Đang gửi...").font(.caption2)
                                    case .failed:
                                        Image(systemName: "exclamationmark.triangle").font(.caption2)
                                        Text("Không gửi được").font(.caption2)
                                        Button("Thử lại") {
                                            Task { await PendingChatQueue.shared.retryPending() }
                                        }
                                        .font(.caption2.bold())
                                        .foregroundColor(Color(red: 0.3, green: 0.69, blue: 0.31))
                                    }
                                }
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .padding(.horizontal)
                                .id(pending.id)
                            }
                            
                            // Dedicated hidden anchor to guarantee absolute bottom positioning 
                            Color.clear
                                .frame(height: 1)
                                .id("bottomAnchor")
                        }
                        .padding(.vertical, 16)
                    }
                    .onChange(of: viewModel.displayMessages.last?.text) { _ in
                        // Ensure layout recalculation completes before scrolling
                        DispatchQueue.main.async {
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo("bottomAnchor", anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: viewModel.displayMessages.count) { _ in
                        DispatchQueue.main.async {
                            withAnimation(.easeOut(duration: 0.25)) {
                                proxy.scrollTo("bottomAnchor", anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: viewModel.displayMessages.last?.status) { _ in
                        DispatchQueue.main.async {
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo("bottomAnchor", anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: viewModel.isStreaming) { _ in
                        DispatchQueue.main.async {
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo("bottomAnchor", anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: viewModel.healthSafetyApplied) { _ in
                        DispatchQueue.main.async {
                            withAnimation(.easeOut(duration: 0.25)) {
                                proxy.scrollTo("bottomAnchor", anchor: .bottom)
                            }
                        }
                    }
                    .onTapGesture {
                        isInputFocused = false
                    }
                }
                
                Divider()
                
                // Input Area
                VStack(spacing: 8) {
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                    }
                    
                    HStack(alignment: .bottom, spacing: 12) {
                        TextField("Hỏi bác sĩ dinh dưỡng...", text: $inputText, axis: .vertical)
                            .lineLimit(1...5)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .frame(minHeight: 54)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(27)
                            .focused($isInputFocused)
                            .disabled(viewModel.isStreaming)
                        
                        Button(action: {
                            if inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Task {
                                    await handleMicTap()
                                }
                            } else {
                                sendMessage()
                            }
                        }) {
                            Group {
                                if inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Image(systemName: "mic.fill")
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundColor(.green)
                                        .frame(width: 44, height: 44)
                                        .background(Circle().fill(Color.green.opacity(0.12)))
                                } else {
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 40)
                                        .background(Circle().fill(Color.green))
                                }
                            }
                            .contentTransition(.symbolEffect(.replace))
                        }
                        .buttonStyle(ChatActionButtonStyle(isMicMode: inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
                        .disabled(viewModel.isStreaming)
                        .opacity((isOffline && inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 0.45 : 1.0)
                        .padding(.trailing, 6)
                        .padding(.bottom, 5)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                }
                .background(Color(UIColor.systemBackground))
            }
            .navigationTitle(viewModel.currentSession?.title ?? "AI Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Task { await viewModel.startNewChat() }
                    }) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(.green)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        NavigationLink(destination: VoiceAssistantSettingsView()) {
                            Image(systemName: "mic.badge.plus")
                                .foregroundColor(.green)
                        }
                        
                        Button(action: {
                            showMemoryHub = true
                        }) {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.green)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showMemoryConfirmation) {
            MemoryUpdateConfirmationView(
                updates: viewModel.pendingMemoryUpdates,
                onConfirm: { updates in
                    viewModel.confirmMemoryUpdates(updates)
                },
                onDismiss: {
                    viewModel.showMemoryConfirmation = false
                    viewModel.pendingMemoryUpdates = []
                }
            )
            .presentationDetents([.medium, .large])
        }
        .fullScreenCover(isPresented: $showMemoryHub) {
            MemoryHubView()
        }
        .onAppear {
            // Removed local voice configs - now managed centrally by GlobalVoiceAssistantManager
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AskAICoachAboutMeal"))) { notification in
            if let food = notification.object as? FoodItemModel {
                let prompt = "Tôi muốn hỏi về món '\(food.name)' (\(Int(food.calories)) kcal). Bạn có lời khuyên gì về dinh dưỡng hoặc cách chế biến món này không?"
                viewModel.sendMessage(prompt)
            }
        }
        .overlay(alignment: .bottom) {
            if voiceManager.dictationState != .idle {
                VoiceRecordingSheet(
                    dictationState: voiceManager.dictationState,
                    transcript: voiceManager.currentTranscript,
                    audioLevel: voiceManager.audioLevel,
                    onDismiss: {
                        voiceManager.cancelChatDictationManual()
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: voiceManager.dictationState)
                .padding(.bottom, 80)
            }
        }
    }
    
    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        viewModel.sendMessage(inputText)
        inputText = ""
    }
    
    private func handleMicTap() async {
        if isOffline {
            viewModel.errorMessage = "📡 Tính năng giọng nói cần kết nối mạng."
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if viewModel.errorMessage == "📡 Tính năng giọng nói cần kết nối mạng." {
                    viewModel.errorMessage = nil
                }
            }
            return
        }
        
        // Toggle pattern: Stop if already active
        if voiceManager.dictationState.isActive {
            voiceManager.cancelChatDictationManual()
            return
        }
        
        // Hand-off entirely to the centralized coordinator
        voiceManager.startChatDictation(
            onUpdate: { partialText in
                self.inputText = partialText
            },
            onFinalized: { finalizedText in
                if !finalizedText.isEmpty {
                    self.inputText = finalizedText
                    if self.voiceManager.settings.autoSendAfterSpeech {
                        self.sendMessage()
                    }
                }
            }
        )
    }
}

struct StreamingCursor: View {
    @State private var opacity: Double = 1.0
    
    var body: some View {
        Rectangle()
            .fill(Color.green)
            .frame(width: 2, height: 16)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    opacity = 0.0
                }
            }
    }
}

struct ChatActionButtonStyle: ButtonStyle {
    let isMicMode: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            // Scale up to ~52pt when pressed (if it's mic mode, 44 -> 52 is ~1.18 scale)
            .scaleEffect(configuration.isPressed ? (isMicMode ? 1.18 : 0.9) : 1.0)
            // Add subtle glow when pressed
            .shadow(color: (configuration.isPressed && isMicMode) ? Color.green.opacity(0.4) : Color.clear, radius: 8, x: 0, y: 0)
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .contentShape(Circle())
    }
}
