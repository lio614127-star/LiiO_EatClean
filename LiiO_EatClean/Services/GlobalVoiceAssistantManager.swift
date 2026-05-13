import Foundation
import AVFoundation
import SwiftUI
import Combine

@Observable
class GlobalVoiceAssistantManager: NSObject {
    // MARK: - State
    var state: VoiceAssistantState = .idle
    var currentTranscript: String = ""
    var lastResponse: String = ""
    var lastSuggestedFoods: [AISuggestedFood]?
    var errorMessage: String?
    var audioLevel: Float = 0.0
    
    // MARK: - Dependencies
    let settings: AssistantVoiceSettings
    private let wakePhraseDetector: WakePhraseDetector
    private let speechService: SpeechRecognitionService
    private let ttsService: TextToSpeechService
    private let chatRepository: ChatRepositoryProtocol
    private let aiService: AIService
    private let contextBuilder: ContextBuilder
    
    // MARK: - Audio Engine
    private let audioEngine = AVAudioEngine()
    private var audioLevelTimer: Timer?
    private let audioLevelThreshold: Float = 0.02 // RMS threshold for voice gate
    private let audioLevelDuration: TimeInterval = 0.3 // 300ms sustained
    private var audioAboveThresholdStart: Date?
    
    // MARK: - Cooldowns & Controls
    private let ttsCooldown: TimeInterval = 1.0
    private let wakeDoubleTriggerCooldown: TimeInterval = 2.0
    private var lastWakeTime: Date?
    private var isProcessingCommand: Bool = false
    
    // MARK: - Init
    init(
        settings: AssistantVoiceSettings = AssistantVoiceSettings(),
        chatRepository: ChatRepositoryProtocol = ChatRepository(),
        aiService: AIService = AIService.shared,
        contextBuilder: ContextBuilder = ContextBuilder()
    ) {
        self.settings = settings
        self.wakePhraseDetector = WakePhraseDetector(assistantName: settings.assistantName)
        self.speechService = SpeechRecognitionService()
        self.ttsService = TextToSpeechService()
        self.chatRepository = chatRepository
        self.aiService = aiService
        self.contextBuilder = contextBuilder
        
        super.init()
        
        setupCallbacks()
        
        // Initial state check
        if settings.globalWakeEnabled {
            self.state = .idle
        } else {
            self.state = .disabled
        }
    }
    
    private func setupCallbacks() {
        ttsService.onFinished = { [weak self] in
            guard let self = self else { return }
            // Wait for cooldown to avoid self-listening
            DispatchQueue.main.asyncAfter(deadline: .now() + self.ttsCooldown) {
                if self.state == .speaking {
                    self.startListening()
                }
            }
        }
        
        speechService.onSilenceTimeout = { [weak self] in
            guard let self = self else { return }
            if self.state == .commandListening && self.settings.autoSendAfterSpeech {
                self.handleCommandResult(self.speechService.transcript)
            }
        }
    }
    
    // MARK: - Controls
    
    func startListening() {
        guard settings.globalWakeEnabled else {
            state = .disabled
            return
        }
        
        stopAllActivities()
        
        do {
            try setupAudioSession()
            setupAudioEngineTap()
            try audioEngine.start()
            
            state = .voiceGateListening
            errorMessage = nil
        } catch {
            state = .error
            errorMessage = "Lỗi khởi tạo âm thanh: \(error.localizedDescription)"
        }
    }
    
    func stopListening() {
        stopAllActivities()
        state = settings.globalWakeEnabled ? .idle : .disabled
    }
    
    private func stopAllActivities() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        speechService.stopListening()
        ttsService.stop()
        audioLevelTimer?.invalidate()
        audioLevelTimer = nil
        audioAboveThresholdStart = nil
        audioLevel = 0.0
    }
    
    // MARK: - Audio Gate Logic
    
    private func setupAudioEngineTap() {
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            guard let self = self, self.state == .voiceGateListening else { return }
            
            // Calculate RMS
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frames = buffer.frameLength
            var sum: Float = 0
            for i in 0..<Int(frames) {
                sum += channelData[i] * channelData[i]
            }
            let rms = sqrt(sum / Float(frames))
            
            DispatchQueue.main.async {
                self.handleAudioLevelUpdate(rms)
            }
        }
    }
    
    private func handleAudioLevelUpdate(_ level: Float) {
        self.audioLevel = level
        
        if level > audioLevelThreshold {
            if audioAboveThresholdStart == nil {
                audioAboveThresholdStart = Date()
            } else if let start = audioAboveThresholdStart, Date().timeIntervalSince(start) >= audioLevelDuration {
                // Sustained noise detected, start wake checking
                startWakeChecking()
            }
        } else {
            audioAboveThresholdStart = nil
        }
    }
    
    // MARK: - Wake Detection
    
    private func startWakeChecking() {
        guard state == .voiceGateListening else { return }
        
        // Anti-spam check
        if let lastWake = lastWakeTime, Date().timeIntervalSince(lastWake) < wakeDoubleTriggerCooldown {
            audioAboveThresholdStart = nil
            return
        }
        
        state = .wakeChecking
        audioEngine.stop() // SFSpeech handles its own engine
        
        speechService.startShortSession(maxDuration: 2.5) { [weak self] transcript in
            guard let self = self else { return }
            self.handleWakeCheckResult(transcript)
        }
    }
    
    private func handleWakeCheckResult(_ transcript: String) {
        if wakePhraseDetector.containsWakePhrase(transcript) {
            onWakeDetected()
        } else {
            // Not a wake phrase, go back to gate
            startListening()
        }
    }
    
    private func onWakeDetected() {
        lastWakeTime = Date()
        state = .wakeDetected
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Speak wake response
        let response = settings.getWakeResponse()
        speakResponse(response) { [weak self] in
            self?.startCommandListening()
        }
    }
    
    // MARK: - Command Listening
    
    func startCommandListening() {
        state = .commandListening
        currentTranscript = ""
        speechService.silenceTimeout = 1.2
        speechService.startListening()
        
        // UI should show the overlay now
    }
    
    func handleCommandResult(_ transcript: String) {
        guard state == .commandListening else { return }
        speechService.stopListening()
        
        if transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            startListening()
            return
        }
        
        currentTranscript = transcript
        processVoiceCommand(transcript)
    }
    
    // MARK: - AI Pipeline
    
    func processVoiceCommand(_ text: String) {
        guard !isProcessingCommand else { return }
        isProcessingCommand = true
        state = .processing
        
        Task {
            do {
                // 1. Get or create active session
                let session = try await chatRepository.fetchLatestActiveSession()
                    ?? (try await chatRepository.createSession(title: "Hội thoại giọng nói", source: "globalVoiceAssistant"))
                
                // 2. Save user message
                let userMsg = ChatMessageModel(role: .user, text: text, inputMode: "voice")
                try await chatRepository.saveMessage(userMsg, sessionId: session.id)
                
                // 3. Detect intent for style optimization
                let intent = detectIntent(text)
                let responseStyle = settings.getResponseStyle(for: intent)
                let responseLength = VoiceResponseLength(rawValue: settings.voiceResponseLength) ?? .moderate
                
                // 4. Build context with voice-aware settings
                let systemPrompt = try await contextBuilder.buildSystemPrompt(
                    for: text,
                    strategy: .chat,
                    voiceMode: true,
                    responseStyle: responseStyle,
                    responseLength: responseLength
                )
                
                // 5. Fetch history for context
                let history = try await chatRepository.fetchMessages(sessionId: session.id, limit: 10)
                
                // 6. Send to AI
                var responseMessage = try await aiService.sendChatMessage(
                    history: history,
                    systemPrompt: systemPrompt,
                    task: .chat,
                    feature: "Voice Assistant"
                )
                
                // 7. Configure output mode and persistence
                responseMessage.outputMode = settings.voiceReplyEnabled ? "voice" : "text"
                try await chatRepository.saveMessage(responseMessage, sessionId: session.id)
                try await chatRepository.updateSessionMetadata(sessionId: session.id, lastMessage: text)
                
                await MainActor.run {
                    self.lastResponse = responseMessage.text
                    self.lastSuggestedFoods = responseMessage.suggestedFoods
                    
                    if self.settings.voiceReplyEnabled {
                        self.speakResponse(responseMessage.text)
                    } else {
                        self.state = .idle
                        // Auto-dismiss after delay if not speaking
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                            if self.state == .idle {
                                self.startListening()
                            }
                        }
                    }
                    self.isProcessingCommand = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Lỗi xử lý: \(error.localizedDescription)"
                    self.state = .error
                    self.isProcessingCommand = false
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.startListening()
                    }
                }
            }
        }
    }
    
    private func detectIntent(_ text: String) -> String {
        let lower = text.lowercased()
        if lower.contains("vừa ăn") || lower.contains("đã ăn") || lower.contains("ăn rồi") || lower.contains("ghi lại") {
            return "meal_logging"
        } else if lower.contains("nên ăn") || lower.contains("ăn gì") || lower.contains("gợi ý") || lower.contains("thực đơn") {
            return "plan_question"
        } else if lower.contains("nấu") || lower.contains("chế biến") || lower.contains("làm") || lower.contains("công thức") {
            return "cooking_advice"
        } else if lower.contains("sức khỏe") || lower.contains("bệnh") || lower.contains("dị ứng") || lower.contains("kiêng") {
            return "health_question"
        } else if lower.contains("tiến độ") || lower.contains("tuần qua") || lower.contains("giảm cân") || lower.contains("cân nặng") {
            return "progress_question"
        } else if lower.contains("cân đối") || lower.contains("rebalance") || lower.contains("chỉnh lại") || lower.contains("nhiều quá") {
            return "rebalance_request"
        }
        return "general_chat"
    }
    
    // MARK: - TTS
    
    func speakResponse(_ text: String, completion: (() -> Void)? = nil) {
        state = .speaking
        ttsService.onFinished = { [weak self] in
            completion?()
            // Default behavior if no specific completion: back to listening
            if completion == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + (self?.ttsCooldown ?? 1.0)) {
                    self?.startListening()
                }
            }
        }
        ttsService.speak(text)
    }
    
    // MARK: - Lifecycle & Helpers
    
    func handleAppBackground() {
        stopListening()
    }
    
    func handleAppForeground() {
        if settings.globalWakeEnabled {
            startListening()
        }
    }
    
    func dismissOverlay() {
        if [.wakeDetected, .commandListening, .processing, .speaking, .error].contains(state) {
            stopListening()
            startListening() // Back to gate listening if enabled
        }
    }
    
    private func setupAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth, .duckOthers])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
}
