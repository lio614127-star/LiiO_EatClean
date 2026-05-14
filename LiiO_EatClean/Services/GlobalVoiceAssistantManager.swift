import Foundation
import AVFoundation
import SwiftUI
import Combine
import Speech

enum VoiceAssistantPermissionStatus {
    case notDetermined
    case granted
    case denied
    case restricted
}

struct VoiceAssistantPermissionResult {
    var microphoneStatus: VoiceAssistantPermissionStatus
    var speechStatus: VoiceAssistantPermissionStatus
    var canUseVoiceAssistant: Bool
    var message: String?
}

enum SiriOverlayPhase: String {
    case hidden
    case activatingWave
    case wakePrompt
    case listening
    case processing
    case speaking
    case closing
}

enum RecognitionPurpose {
    case wake
    case command
    case testWake
    case testSpeech
}

@MainActor
@Observable
class GlobalVoiceAssistantManager: NSObject {
    // MARK: - State
    var state: VoiceAssistantState = .idle
    var currentTranscript: String = ""
    var latestMeaningfulCommandTranscript: String = ""
    var lastResponse: String = ""
    var lastSuggestedFoods: [AISuggestedFood]?
    var errorMessage: String?
    var audioLevel: Float = 0.0
    
    // MARK: - Diagnostics
    var lastRawTranscript: String = ""
    var lastNormalizedTranscript: String = ""
    var lastWakeMatch: Bool = false
    var lastMatchedBy: String = "none"
    var isAppForeground: Bool = true
    var audioEngineRunning: Bool { audioEngine.isRunning }
    var activeWakePhrases: [String] { wakePhraseDetector.currentWakePhrases }
    var activeAliases: [String] { wakePhraseDetector.assistantAliases }
    var activeTTSEngineName: String { ttsService.currentEngineName }
    
    // Siri Style UI States
    var siriOverlayPhase: SiriOverlayPhase = .hidden
    var conversationMode: VoiceConversationMode = .inactive
    var isActivationWaveVisible: Bool = false
    var isAssistantPillVisible: Bool = false
    var isTranscriptVisible: Bool = false
    var overlayText: String = ""
    var hasUserStartedSpeaking: Bool = false
    var orbYPosition: CGFloat = 520.0 // Remembers Y drag snap coordinate
    private var initialSpeechTimeoutTask: Task<Void, Never>?
    
    @ObservationIgnored private var activeSessionTimer: Timer?
    
    // MARK: - Dependencies
    let settings: AssistantVoiceSettings
    private let wakePhraseDetector: WakePhraseDetector
    private let speechService: SpeechRecognitionService
    private let ttsService: TextToSpeechService
    private let chatRepository: ChatRepositoryProtocol
    private let aiService: AIService
    private let contextBuilder: ContextBuilder
    private let dailyPlanRepository: DailyPlanRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    
    // MARK: - Audio Engine
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var currentPurpose: RecognitionPurpose = .wake
    private var expectedRecognitionCancellation = false
    
    private var audioLevelTimer: Timer?
    private let audioLevelThreshold: Float = 0.010
    private let audioLevelDuration: TimeInterval = 0.20
    private var audioAboveThresholdStart: Date?
    
    // MARK: - Pre-roll Buffer
    private var preRollBuffers: [AVAudioPCMBuffer] = []
    private let maxPreRollBuffers = 8 // ~0.8s at 1024 buffer size
    
    // MARK: - Cooldowns & Controls
    private let ttsCooldown: TimeInterval = 0.5
    private let wakeDoubleTriggerCooldown: TimeInterval = 2.0
    private var lastWakeTime: Date?
    private var isProcessingCommand: Bool = false
    private var currentClientId: String = UUID().uuidString
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    init(
        settings: AssistantVoiceSettings = AssistantVoiceSettings(),
        chatRepository: ChatRepositoryProtocol = ChatRepository(),
        aiService: AIService = AIService.shared,
        contextBuilder: ContextBuilder = ContextBuilder(),
        dailyPlanRepository: DailyPlanRepositoryProtocol = DailyPlanRepository(),
        userRepository: UserRepositoryProtocol = UserRepository()
    ) {
        self.settings = settings
        self.wakePhraseDetector = WakePhraseDetector(assistantName: settings.assistantName)
        self.speechService = SpeechRecognitionService()
        self.ttsService = TextToSpeechService()
        self.chatRepository = chatRepository
        self.aiService = aiService
        self.contextBuilder = contextBuilder
        self.dailyPlanRepository = dailyPlanRepository
        self.userRepository = userRepository
        
        super.init()
        
        setupCallbacks()
        setupNotifications()
        
        if settings.globalWakeEnabled {
            print("[Voice-Flow 0] Manager init - Wake enabled, setting to idle.")
            self.state = .idle
            self.currentPurpose = .wake
        } else {
            self.state = .disabled
        }
    }
    
    private func setupCallbacks() {
        ttsService.onFinished = { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                print("[VoiceManager] 🔊 TTS Finished callback.")
                
                // If we were speaking a wake response, wait cooldown, then start command listening
                if self.state == .speakingWakeResponse || self.state == .wakeDetected {
                    print("[Voice-Flow 9.1] Wake response finished. Starting cooldown.")
                    self.transitionToCommandListeningAfterCooldown()
                } 
                // If we were speaking an AI response, transition back to continuous listening instead of dismissing
                else if self.state == .speakingAIResponse || self.state == .speaking {
                    if let error = self.ttsService.lastError {
                        print("[Voice-Error] Detected TTS playback failure: \(error)")
                        self.overlayText = "Không phát được âm thanh giọng nói."
                    }
                    
                    self.conversationMode = .speaking
                    print("[Voice-Flow 16] Response finished. Preparing continuous listening mode...")
                    
                    Task {
                        try? await Task.sleep(nanoseconds: 1_200_000_000) // 1.2s padding
                        await MainActor.run {
                            // Ensure we haven't been forceClosed / minimized during wait
                            if self.state == .speakingAIResponse || self.state == .speaking {
                                if self.conversationMode != .activeMinimized && self.conversationMode != .inactive {
                                    print("[Voice-Flow 17] Rolling back to continuous capture.")
                                    self.currentTranscript = ""
                                    self.latestMeaningfulCommandTranscript = ""
                                    self.overlayText = "Bạn hỏi tiếp đi..."
                                    self.conversationMode = .listening
                                    self.startCommandListening()
                                    self.resetActiveSessionTimer()
                                }
                            }
                        }
                    }
                }
            }
        }
        
        speechService.onSilenceTimeout = { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if self.state == .commandListening && self.settings.autoSendAfterSpeech {
                    if self.hasUserStartedSpeaking {
                        print("[VoiceManager] 🔇 Silence timeout. Sending command.")
                        self.handleCommandResult(self.speechService.transcript)
                    } else {
                        print("[Voice-Flow 12.8] silence finalize ignored because no speech yet")
                    }
                }
            }
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: NSNotification.Name("AssistantNameChanged"))
            .sink { [weak self] notification in
                if let newName = notification.object as? String {
                    print("[VoiceManager] 🏷️ Assistant name changed: \(newName)")
                    Task { @MainActor in
                        self?.wakePhraseDetector.updateAssistantName(newName)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Core Controls
    
    func startListening() {
        guard settings.globalWakeEnabled && isAppForeground else {
            print("[Voice-Flow] startListening skipped: enabled=\(settings.globalWakeEnabled), foreground=\(isAppForeground)")
            state = settings.globalWakeEnabled ? .idle : .disabled
            return
        }
        
        print("[Voice-Flow 1] startListening requested.")
        
        Task {
            // Only reset if engine is NOT running or if we need to clean up
            if !audioEngine.isRunning {
                await resetAudioEngine()
            }
            
            let perms = await checkPermissions()
            guard perms.canUseVoiceAssistant else {
                print("[Voice-Error] Step 2: Permission denied.")
                self.state = .error
                self.errorMessage = perms.message ?? "Thiếu quyền truy cập."
                return
            }
            
            print("[Voice-Flow 2] Permissions OK.")
            
            do {
                try setupAudioSession()
                
                if !audioEngine.isRunning {
                    print("[Voice-Flow 2.1] Starting engine tap...")
                    setupAudioEngineTap()
                    try audioEngine.start()
                }
                
                print("[Voice-Flow 3] Audio engine running, mode=voiceGateListening.")
                self.state = .voiceGateListening
                self.errorMessage = nil
            } catch {
                print("[Voice-Error] Step 3: Engine failed: \(error.localizedDescription)")
                self.state = .error
                self.errorMessage = "Lỗi khởi tạo âm thanh."
            }
        }
    }
    
    private func resetAudioEngine() async {
        print("[Voice-Flow] Resetting audio engine...")
        expectedRecognitionCancellation = true
        speechService.expectedCancellation = true
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        preRollBuffers.removeAll()
        
        // Safety delay to let hardware tear down
        try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
        expectedRecognitionCancellation = false
        speechService.expectedCancellation = false
    }
    
    func stopListening() {
        print("[VoiceManager] 🛑 Stop all voice activities.")
        stopAllActivities()
        state = settings.globalWakeEnabled ? .idle : .disabled
    }
    
    private func stopAllActivities() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.reset() // Completely sever graph connections
        }
        speechService.stopListening()
        ttsService.stop()
        audioLevelTimer?.invalidate()
        audioLevelTimer = nil
        audioAboveThresholdStart = nil
        audioLevel = 0.0
    }
    
    // MARK: - Audio Gate
    
    private func setupAudioEngineTap() {
        // TODO (Future Upgrade): Support Barge-In voice detection. 
        // If state is .speaking and rms level stays above gate threshold (> 0.015) for >0.5s, 
        // auto-stop TTS, clear output and immediately switch back to .listening.
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            guard let self = self, buffer.frameLength > 0 else { return }
            
            // 1. Calculate RMS Level for gate
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frames = buffer.frameLength
            var sum: Float = 0
            for i in 0..<Int(frames) { sum += channelData[i] * channelData[i] }
            let rms = sqrt(sum / Float(frames))
            
            Task { @MainActor in
                // 2. Manage Pre-roll buffer
                if let bufferCopy = self.deepCopyBuffer(buffer) {
                    self.preRollBuffers.append(bufferCopy)
                    if self.preRollBuffers.count > self.maxPreRollBuffers {
                        self.preRollBuffers.removeFirst()
                    }
                    
                    // 3. Feed to speech service if active
                    if self.speechService.isListening {
                        self.speechService.feed(bufferCopy)
                        self.audioLevel = self.speechService.audioLevel // Sync level for reactive UI
                    } else {
                        // Ambient level during gate if needed
                        self.audioLevel = min(1.0, max(0.0, rms * 3.0))
                    }
                }
                
                // 4. Update level and gate logic
                if self.state == .voiceGateListening {
                    self.handleAudioLevelUpdate(rms)
                }
            }
        }
    }
    
    private func handleAudioLevelUpdate(_ level: Float) {
        guard state == .voiceGateListening else { return }
        self.audioLevel = level
        
        if level > audioLevelThreshold {
            if audioAboveThresholdStart == nil {
                audioAboveThresholdStart = Date()
            } else if let start = audioAboveThresholdStart, Date().timeIntervalSince(start) >= audioLevelDuration {
                print("[VoiceManager] 🔊 Audio threshold crossed (\(String(format: "%.3f", level))). Starting wake check.")
                startWakeChecking()
            }
        } else {
            audioAboveThresholdStart = nil
        }
    }
    
    // MARK: - Wake Detection
    
    private func startWakeChecking() {
        guard state == .voiceGateListening else { return }
        
        if let lastWake = lastWakeTime, Date().timeIntervalSince(lastWake) < wakeDoubleTriggerCooldown {
            audioAboveThresholdStart = nil
            return
        }
        
        print("[Voice-Flow 5] Threshold sustained. Begin wake check WITHOUT engine reset.")
        state = .wakeChecking
        currentPurpose = .wake
        
        Task {
            print("[Voice-Flow 5.1] Wake recognition request created.")
            
            speechService.onTranscriptUpdate = { [weak self] partial in
                Task { @MainActor [weak self] in
                    guard let self = self, self.state == .wakeChecking else { return }
                    print("[Voice-Flow 6W] Wake partial transcript raw='\(partial)'")
                    
                    // Check for wake phrase on every partial
                    let result = self.wakePhraseDetector.checkWakePhrase(partial)
                    if result.isMatch {
                        print("[Voice-Latency] wakeMatchedPartiallyAt: \(Date().timeIntervalSince1970)")
                        print("[Voice-Flow 7] Wake MATCH true from partial, matchedBy=\(result.matchedBy)")
                        
                        // Use command remainder if available for one-shot flow
                        self.handleWakeDetected(oneShotCommand: result.commandRemainder)
                    }
                }
            }
            
            speechService.startShortSession(maxDuration: 4.5, useInternalEngine: false) { [weak self] transcript in
                Task { @MainActor [weak self] in
                    self?.handleWakeCheckResult(transcript)
                }
            }
            
            // Feed pre-roll immediately
            let preRollCount = preRollBuffers.count
            print("[Voice-Flow 5.2] Appended preRollBuffers count=\(preRollCount) duration=~\(String(format: "%.1f", Double(preRollCount) * 0.1))s")
            
            for buffer in preRollBuffers {
                speechService.feed(buffer)
            }
            
            print("[Voice-Flow 5.3] Appending live buffers to wake recognition...")
        }
    }
    
    private func handleWakeCheckResult(_ transcript: String) {
        // Guard: If we've already matched or left wakeChecking, ignore
        guard state == .wakeChecking else { return }
        
        let result = wakePhraseDetector.checkWakePhrase(transcript)
        self.lastRawTranscript = transcript
        self.lastNormalizedTranscript = result.normalizedTranscript
        self.lastWakeMatch = result.isMatch
        self.lastMatchedBy = result.matchedBy
        
        print("[Voice-Flow 6] Wake transcript: raw='\(transcript)', norm='\(result.normalizedTranscript)'")
        
        if result.isMatch {
            print("[Voice-Latency] wakeMatchedAt: \(Date().timeIntervalSince1970)")
            print("[Voice-Flow 7] Wake MATCH true, matchedBy=\(result.matchedBy)")
            handleWakeDetected(oneShotCommand: result.commandRemainder)
        } else {
            print("[Voice-Flow 6.9] Wake check timeout or no match. finalRaw='\(transcript)', match=false.")
            // Only resume gate if we haven't transitioned to a higher state
            if state == .wakeChecking {
                startListening()
            }
        }
    }
    
    private func handleWakeDetected(oneShotCommand: String? = nil) {
        // Prevent double triggers
        guard state == .wakeChecking else { return }
        
        // 1. Immediately switch state to prevent further wake checks
        state = .wakeDetected
        lastWakeTime = Date()
        print("[Voice-Flow 8] State: wakeDetected. Switching to command session.")
        print("[Voice-Flow 8.1] activationWaveVisible=true")
        
        // 2. Stop wake recognition cleanly
        speechService.expectedCancellation = true
        speechService.stopListening()
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        // 3. Siri Activation UI
        self.conversationMode = .activating
        showSiriActivationOverlay()
        
        let rawResponse = settings.getWakeResponse()
        let renderedResponse = rawResponse.replacingOccurrences(of: "{assistantName}", with: settings.assistantSpokenName)
        self.lastResponse = renderedResponse
        
        // ONE-SHOT OPTIMIZATION: If user spoke full sentence, jump straight to AI!
        if let command = oneShotCommand {
            let cleanCommand = command.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleanCommand.count >= 3 {
                print("[Voice-Flow 8.5] One-shot utterance detected: '\(cleanCommand)'")
                print("[Voice-Flow 12F] command final transcript raw='\(cleanCommand)'")
                
                // We skip speaking response and just transition straight to processing!
                self.currentTranscript = cleanCommand
                self.conversationMode = .processing
                self.processVoiceCommand(cleanCommand)
                return
            }
        }
        
        // NORMAL FLOW: Speak response with duration limit and then listen after cooldown
        if settings.voiceReplyEnabled {
            print("[Voice-Flow 9] Speaking wake response: '\(renderedResponse)'")
            state = .speakingWakeResponse
            self.conversationMode = .speaking
            
            // Speak. Cooldown and transition are handled by onFinished callback.
            executeSpeak(renderedResponse)
            
            // Safety limit for wake response (1.2s) to prevent long delays
            Task {
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                if self.state == .speakingWakeResponse {
                    print("[Voice-Flow 9.2] Wake TTS max duration (1.2s) reached. Stopping TTS.")
                    self.ttsService.stop()
                    // Manually trigger cooldown if stop doesn't fire completion
                    self.transitionToCommandListeningAfterCooldown()
                }
            }
        } else {
            // If reply disabled, directly listen after slight delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                self?.startCommandListening()
            }
        }
    }
    
    private func transitionToCommandListeningAfterCooldown() {
        guard state == .speakingWakeResponse || state == .wakeDetected else { return }
        
        // Transition state to idle temporarily to prevent double executions
        state = .idle
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            print("[Voice-Flow 10] Cooldown finished. Transitioning to command capture.")
            self.startCommandListening()
        }
    }
    
    @MainActor
    func showSiriActivationOverlay() {
        print("[Voice-Latency] waveStartedAt: \(Date().timeIntervalSince1970)")
        siriOverlayPhase = .activatingWave
        isActivationWaveVisible = true
        isAssistantPillVisible = false
        isTranscriptVisible = false
        overlayText = ""
        
        Task {
            // Wave starts immediately. Pill after short delay.
            try? await Task.sleep(nanoseconds: 140_000_000) // 140ms - Silkier entrance
            print("[Voice-Latency] pillShownAt: \(Date().timeIntervalSince1970)")
            print("[Voice-Flow 8.2] assistantPillVisible=true")
            self.isAssistantPillVisible = true
            
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms - Smooth transition
            print("[Voice-Latency] promptShownAt: \(Date().timeIntervalSince1970)")
            print("[Voice-Flow 8.3] transcriptBoxVisible=true")
            self.overlayText = self.settings.getWakeResponse().replacingOccurrences(of: "{assistantName}", with: self.settings.assistantSpokenName)
            self.isTranscriptVisible = true
            self.siriOverlayPhase = .wakePrompt
        }
    }
    
    // MARK: - Command Listening
    
    func startCommandListening() {
        // Allow continuous follow-up transition from active speaking states
        guard state == .wakeDetected || state == .speakingWakeResponse || state == .idle || state == .speaking || state == .speakingAIResponse else { 
            print("[Voice-Flow] Rejecting startCommandListening - unexpected state: \(state)")
            return 
        }
        
        if state == .speaking || state == .speakingAIResponse {
            print("[Voice-Flow C1] follow-up listening armed")
        }
        
        // Generate fresh unique ID for the next command to link with transient drafts
        self.currentClientId = UUID().uuidString
        
        print("[Voice-Latency] commandListeningStartedAt: \(Date().timeIntervalSince1970)")
        print("[Voice-Flow 11] startCommandListening triggered.")
        print("[Voice-Flow 11.1] command session ready for speech.")
        
        // Reset Speaking Machine state
        hasUserStartedSpeaking = false
        state = .commandListening
        self.conversationMode = .listening
        self.resetActiveSessionTimer()
        currentPurpose = .command
        siriOverlayPhase = .listening
        currentTranscript = ""
        latestMeaningfulCommandTranscript = ""
        overlayText = "Bạn nói đi..."
        speechService.silenceTimeout = 0.9 // Responsive finalize duration
        
        print("[Voice-Flow 11.2] command listening armed")
        print("[Voice-Flow 11.3] waiting for user speech")
        
        // Clear existing timers
        initialSpeechTimeoutTask?.cancel()
        
        // Launch separate 6-second Initial No-Speech Timeout
        initialSpeechTimeoutTask = Task {
            try? await Task.sleep(nanoseconds: 6_000_000_000)
            await MainActor.run {
                if !self.hasUserStartedSpeaking && self.state == .commandListening {
                    print("[Voice-Flow 12.9] initial no-speech timeout")
                    self.overlayText = "Mình chưa nghe thấy câu hỏi."
                    self.speechService.stopListening()
                    
                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        if self.state == .commandListening {
                            self.dismissOverlay()
                        }
                    }
                }
            }
        }
        
        speechService.onTranscriptUpdate = { [weak self] partial in
            Task { @MainActor [weak self] in
                guard let self = self, self.state == .commandListening else { return }
                
                // BARGE-IN: If user starts speaking, STOP wake TTS immediately
                if !partial.isEmpty {
                    self.ttsService.stop()
                }
                
                let isMeaningful = self.isMeaningfulTranscript(partial)
                print("[Voice-Flow 12C] command partial raw='\(partial)'")
                print("[Voice-Flow 12C] meaningful=\(isMeaningful)")
                
                // Once user says something meaningful, arm the finalizer
                if isMeaningful && !self.hasUserStartedSpeaking {
                    print("[Voice-Flow 12S] user started speaking")
                    self.hasUserStartedSpeaking = true
                    self.initialSpeechTimeoutTask?.cancel() // Stop the no-speech countdown
                }
                
                if self.hasUserStartedSpeaking {
                    if self.currentTranscript.isEmpty && !partial.isEmpty {
                        print("[Voice-Latency] firstPartialTranscriptAt: \(Date().timeIntervalSince1970)")
                    }
                    
                    // Only update live overlay if we have content to prevent jarring clear outs
                    if !partial.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        self.currentTranscript = partial
                        
                        // Broadcast partial transcript to Live Messenger store
                        let currentCmdId = self.currentClientId
                        Task { @MainActor in
                            let currentSessId = try? await self.chatRepository.fetchLatestActiveSession()?.id
                            ChatRealtimeStore.shared.updateVoiceDraft(
                                text: partial,
                                sessionId: currentSessId,
                                clientId: currentCmdId
                            )
                        }
                    }
                    
                    if isMeaningful {
                        self.latestMeaningfulCommandTranscript = partial
                    }
                    
                    // Add specific log requested
                    print("[Voice-Flow C2] follow-up partial transcript raw='\(partial)'")
                }
            }
        }
        
        Task {
            speechService.startListening(useInternalEngine: false)
        }
    }
    
    private func isMeaningfulTranscript(_ text: String) -> Bool {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleaned.isEmpty else { return false }
        
        // Block common single fillers/noises
        let fillers = ["ít", "ừ", "à", "ơ", "ừm", "dạ", "nhé", "thôi", "nhỉ", "mình"]
        if fillers.contains(cleaned) {
            return false
        }
        
        return true
    }
    
    private func isValidCommand(_ text: String) -> Bool {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleaned.isEmpty else { return false }
        guard cleaned.count >= 3 else { return false } // Enforce minimum 3 characters
        
        // Banned expressions according to strict UX rules
        let banned = [
            "ít",
            "ừ",
            "à",
            "ơ",
            "nói ít thôi",
            "mình nghe đây",
            "bạn nói đi",
            "có mình đây"
        ]
        if banned.contains(cleaned) {
            return false
        }
        
        // Explicitly verify user isn't echoing the current spoken wake response
        let lastRespCleaned = self.lastResponse.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !lastRespCleaned.isEmpty && (cleaned == lastRespCleaned || lastRespCleaned.contains(cleaned)) {
            print("[Voice-Flow] Command rejected as echo of wake response: '\(cleaned)' vs '\(lastRespCleaned)'")
            return false
        }
        
        // Ensure some alphanumeric or alphabetic values exist
        let punctuationSet = CharacterSet.punctuationCharacters.union(.symbols)
        let filtered = cleaned.components(separatedBy: punctuationSet).joined()
        guard !filtered.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        
        return true
    }
    
    func handleCommandResult(_ transcript: String) {
        guard state == .commandListening else { return }
        print("[Voice-Latency] finalTranscriptAt: \(Date().timeIntervalSince1970)")
        print("[Voice-Flow 12.8] silence finalize fired.")
        
        var text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // CRITICAL FALLBACK: If final text is empty, use the latest valid partial we captured
        if text.isEmpty && !latestMeaningfulCommandTranscript.isEmpty {
            print("[Voice-Flow] Falling back from empty final raw to latest meaningful partial: '\(latestMeaningfulCommandTranscript)'")
            text = latestMeaningfulCommandTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        print("[Voice-Flow 12F] command final raw='\(text)'")
        speechService.stopListening()
        
        // Safety Gate: Did they actually speak during the session?
        guard hasUserStartedSpeaking else {
            print("[Voice-Flow 12.8] silence finalize ignored because no speech yet")
            return
        }
        
        let valid = isValidCommand(text)
        print("[Voice-Flow 12V] command valid=\(valid)")
        
        guard valid else {
            print("[Voice-Flow] Invalid/empty command. Not sending AI.")
            self.overlayText = "Mình chưa nghe rõ."
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                // Only dismiss if state has not transitioned to processing
                if self.state == .commandListening {
                    self.dismissOverlay()
                }
            }
            return
        }
        
        // Store exact transcript and trigger processing
        currentTranscript = text
        processVoiceCommand(text)
    }
    
    // MARK: - AI Pipeline
    
    func processVoiceCommand(_ text: String) {
        guard !isProcessingCommand else { return }
        let commandStartTime = Date().timeIntervalSince1970
        print("[Voice-Latency] ⏱️ commandReceivedAt: \(commandStartTime)")
        
        isProcessingCommand = true
        state = .processingCommand
        self.conversationMode = .processing
        siriOverlayPhase = .processing
        overlayText = "Đang xử lý..."
        self.resetActiveSessionTimer()
        
        Task {
            do {
                print("[Voice-Flow 13] Processing voice command='\(text)'")
                
                // 1. Setup/fetch Active Session
                let session: ChatSessionModel
                if let existing = try await chatRepository.fetchLatestActiveSession() {
                    session = existing
                } else {
                    session = try await chatRepository.createSession(title: "Hội thoại giọng nói", source: "globalVoiceAssistant")
                }
                
                // 2. Finalize User Voice Draft & Save official copy to trigger live mirror UI update
                await MainActor.run {
                    ChatRealtimeStore.shared.finalizeVoiceDraft()
                }
                print("[Voice-Flow C3] follow-up final transcript raw='\(text)'")
                
                var userMsg = ChatMessageModel(role: .user, text: text, inputMode: "voice")
                userMsg.clientId = self.currentClientId // Match transient draft
                
                print("[Voice-Flow C4] follow-up sent to AI pipeline")
                await saveAndMirrorMessage(userMsg, sessionId: session.id)
                
                // 2.5 Specialized Routing Intent Flow
                let routedIntent = VoiceCommandIntentRouter.route(transcript: text)
                if routedIntent == .dailyPlanRequest {
                    await handleDailyPlanIntent(sessionId: session.id, commandStartTime: commandStartTime)
                    self.isProcessingCommand = false
                    return
                }
                
                // 3. FAST PATH GATEWAY (Bypasses network latency entirely)
                if let fastResponseText = handleFastPath(text) {
                    let diff = Date().timeIntervalSince1970 - commandStartTime
                    print("[Voice-Latency] ⚡ commandToFastPath = \(String(format: "%.3f", diff))s")
                    print("[Voice-Flow] ⚡ Fast path resolved in \(String(format: "%.2f", diff))s: '\(text)'")
                    
                    let fastRespMsg = ChatMessageModel(
                        role: .assistant,
                        text: fastResponseText,
                        inputMode: "voice",
                        outputMode: settings.voiceReplyEnabled ? "voice" : "text"
                    )
                    
                    // Persist locally and mirror instantly
                    await saveAndMirrorMessage(fastRespMsg, sessionId: session.id)
                    try await chatRepository.updateSessionMetadata(sessionId: session.id, lastMessage: text)
                    
                    // Telemetry
                    let end = Date().timeIntervalSince1970
                    print("[Voice-Latency] ⏱️ totalCommandToFastSpeech = \(String(format: "%.3f", end - commandStartTime))s")
                    
                    // UI Update
                    self.lastResponse = fastResponseText
                    self.overlayText = fastResponseText
                    
                    if self.settings.voiceReplyEnabled {
                        self.state = .speakingAIResponse
                        self.siriOverlayPhase = .speaking
                        self.executeSpeak(fastResponseText)
                    } else {
                        self.siriOverlayPhase = .closing
                        self.state = .idle
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        if self.state == .idle {
                            self.siriOverlayPhase = .hidden
                            self.startListening()
                        }
                    }
                    self.isProcessingCommand = false
                    return
                }
                
                // 4. SLOW PATH - IMMEDIATE ZERO-LATENCY LOCAL ACKNOWLEDGEMENT
                if settings.voiceReplyEnabled {
                    print("[Voice-Flow] 📻 Local instant ACK triggered.")
                    // Short, fast, zero-network local speak so user knows we heard them!
                    self.ttsService.speakLocal("Mình nghe rồi.", voiceName: "vi-VN", rate: 1.05, volume: 1.0)
                }
                
                // 5. START LONG-RUNNING AI WORKLOAD
                let aiStart = Date().timeIntervalSince1970
                print("[Voice-Latency] aiRequestSentAt: \(aiStart)")
                
                // Broadcast assistant thinking draft for realtime chat mirror
                let assistantClientId = UUID().uuidString
                await MainActor.run {
                    ChatRealtimeStore.shared.startAssistantDraft(sessionId: session.id, clientId: assistantClientId)
                }
                
                // Engagement timer: Keep user in loop if network drags
                let statusUpdateTask = Task {
                    try? await Task.sleep(nanoseconds: 3_200_000_000) // 3.2s
                    await MainActor.run {
                        if self.state == .processingCommand {
                            print("[Voice-Flow] ⏱️ AI lagging past 3.2s. Updating engagement message.")
                            self.overlayText = "Mạng hơi chậm, mình vẫn đang xử lý..."
                        }
                    }
                }
                
                let intent = detectIntent(text)
                let responseStyle = settings.getResponseStyle(for: intent)
                let responseLength = VoiceResponseLength(rawValue: settings.voiceResponseLength) ?? .moderate
                
                var voiceInstruction = ""
                if settings.voiceReplyEnabled {
                    voiceInstruction = " Bạn đang trả lời bằng giọng nói. Tuyệt đối KHÔNG chào hỏi xã giao ('Chào bạn', 'Chào bạn thân mến...') và KHÔNG tự xưng là LiiO hay LiiO EatClean. Không dùng emoji, markdown, ký tự trang trí hoặc chữ kéo dài. Trả lời tự nhiên, cực kỳ ngắn gọn, tập trung thẳng vào đáp án và dễ đọc bằng TTS."
                }
                
                let systemPrompt = try await contextBuilder.buildSystemPrompt(
                    for: text,
                    strategy: .chat,
                    voiceMode: true,
                    responseStyle: responseStyle,
                    responseLength: responseLength,
                    assistantName: settings.assistantName
                ) + voiceInstruction
                
                let history = try await chatRepository.fetchMessages(sessionId: session.id, limit: 10)
                
                // The remote network query
                let responseMessage = try await aiService.sendChatMessage(
                    history: history,
                    systemPrompt: systemPrompt,
                    task: .chat,
                    feature: "Voice Assistant"
                )
                
                // AI returned! Kill the status tracker
                statusUpdateTask.cancel()
                
                let aiEnd = Date().timeIntervalSince1970
                print("[Voice-Latency] ⏱️ aiRequestToResponse = \(String(format: "%.3f", aiEnd - aiStart))s")
                print("[Voice-Flow 14] AI response received for command='\(text)'")
                
                var finalMsg = responseMessage
                finalMsg.clientId = assistantClientId
                finalMsg.outputMode = settings.voiceReplyEnabled ? "voice" : "text"
                
                // Finalize draft so official model replaces it
                await MainActor.run {
                    ChatRealtimeStore.shared.finalizeAssistantDraft()
                }
                
                await saveAndMirrorMessage(finalMsg, sessionId: session.id)
                try await chatRepository.updateSessionMetadata(sessionId: session.id, lastMessage: text)
                
                // 6. PRESENT RESULT IMMEDIATELY
                self.lastResponse = finalMsg.text
                self.overlayText = finalMsg.text
                self.lastSuggestedFoods = finalMsg.suggestedFoods
                
                let total = Date().timeIntervalSince1970 - commandStartTime
                print("[Voice-Latency] ⏱️ totalCommandToSpeech = \(String(format: "%.3f", total))s")
                
                if self.settings.voiceReplyEnabled {
                    print("[Voice-Latency] responseTTSStartedAt: \(Date().timeIntervalSince1970)")
                    print("[Voice-Flow 15] response TTS started")
                    self.state = .speakingAIResponse
                    self.siriOverlayPhase = .speaking
                    
                    // Switch to Premium Mode and Read Full Neural Output
                    self.executeSpeak(finalMsg.text)
                } else {
                    print("[Voice-Flow] Voice reply disabled. Resuming gate after delay.")
                    self.siriOverlayPhase = .closing
                    self.state = .idle
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    if self.state == .idle {
                        self.siriOverlayPhase = .hidden
                        self.startListening()
                    }
                }
                self.isProcessingCommand = false
            } catch {
                print("[Voice-Error] AI Pipeline failed: \(error.localizedDescription)")
                self.overlayText = "Đã xảy ra lỗi kết nối, vui lòng thử lại nhé."
                self.state = .error
                self.isProcessingCommand = false
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                if self.state == .error {
                    self.dismissOverlay()
                }
            }
        }
    }
    
    
    private func handleFastPath(_ text: String) -> String? {
        let lower = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Weather fast path
        if lower.contains("trời thế nào") || lower.contains("thời tiết") || lower.contains("trời hôm nay") {
            return "Mình chưa có dữ liệu thời tiết trực tiếp, nhưng mình luôn sẵn lòng giúp bạn thiết kế một thực đơn Eat Clean tuyệt vời hôm nay nhé!"
        }
        
        // System status / static nutrition queries
        if lower.contains("calo tối thiểu") || lower.contains("ít nhất bao nhiêu calo") {
            return "LiiO EatClean luôn khuyến nghị mức nạp vào tối thiểu 1200 calo mỗi ngày để bảo vệ trao đổi chất và sức khỏe cơ bản cho bạn."
        }
        
        // Greetings
        if lower == "chào bạn" || lower == "xin chào" || lower == "hello" || lower == "hi trợ lý" {
            let responses = [
                "Xin chào! Rất vui được hỗ trợ bạn. Hôm nay bạn muốn lên thực đơn hay ghi nhận món ăn?",
                "Chào bạn, mình đây! Bạn cần mình hỗ trợ gì về chế độ dinh dưỡng hôm nay nào?"
            ]
            return responses.randomElement() ?? responses[0]
        }
        
        return nil
    }
    
    private func handleDailyPlanIntent(sessionId: UUID, commandStartTime: TimeInterval) async {
        print("[Voice-Flow] 🗓️ Route matched dailyPlanRequest intent.")
        
        // 1. Local Check: Is today's plan already confirmed?
        let today = Date()
        var existingPlan: DailyPlanModel? = nil
        do {
            existingPlan = try await dailyPlanRepository.fetchPlan(for: today)
        } catch {
            print("❌ Error fetching existing plan: \(error)")
        }
        
        if let existing = existingPlan, existing.status == "confirmed" {
            let confirmText = "Hôm nay bạn đã có thực đơn rồi. Mình mở lại kế hoạch hôm nay nhé."
            
            // Save to local chat session
            let chatMsg = ChatMessageModel(
                role: .assistant,
                text: confirmText,
                inputMode: "voice",
                outputMode: settings.voiceReplyEnabled ? "voice" : "text"
            )
            await saveAndMirrorMessage(chatMsg, sessionId: sessionId)
            
            self.lastResponse = confirmText
            self.overlayText = confirmText
            
            // Immediate navigation trigger: Switch Tab AND pop Sheet
            NotificationCenter.default.post(name: NSNotification.Name("navigateToJournal"), object: nil)
            
            // Give ContentView a tiny nanosecond gap to switch tabs before presenting the sheet
            Task {
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                NotificationCenter.default.post(name: NSNotification.Name("openDailyPlanning"), object: nil)
            }
            
            if self.settings.voiceReplyEnabled {
                self.state = .speakingAIResponse
                self.siriOverlayPhase = .speaking
                self.executeSpeak(confirmText)
            } else {
                self.siriOverlayPhase = .closing
                self.state = .idle
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                if self.state == .idle {
                    self.siriOverlayPhase = .hidden
                    self.startListening()
                }
            }
            return
        }
        
        // 2. Setup generation
        let loadingText = "Mình nghe rồi, đang lên thực đơn hôm nay cho bạn."
        self.overlayText = loadingText
        
        // 🚀 SAVE INTERIM ACKNOWLEDGEMENT TO CHAT IMMEDIATELY FOR TOTAL SYNC
        let interimMsg = ChatMessageModel(
            role: .assistant,
            text: loadingText,
            inputMode: "voice",
            outputMode: settings.voiceReplyEnabled ? "voice" : "text"
        )
        await saveAndMirrorMessage(interimMsg, sessionId: sessionId)
        
        if self.settings.voiceReplyEnabled {
            self.ttsService.speakLocal(loadingText, voiceName: "vi-VN", rate: 1.0, volume: 1.0)
        }
        
        do {
            // Fetch User Profile to get target calories
            let user = try await userRepository.fetchUser()
            let targetCalories = user?.dailyCalorieTarget ?? 2000.0
            
            // Build User Context
            let userContext = try await contextBuilder.buildFullUserContext()
            
            // Call streaming generation in AIOrchestrator
            let allFoods = try await AIOrchestrator.shared.generateDayPlanStreaming(
                targetCalories: targetCalories,
                userContext: userContext,
                completedMealTypes: [],
                isInternal: true
            ) { _ in }
            
            if allFoods.isEmpty {
                throw NSError(domain: "GlobalVoiceAssistantManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "AI returned empty day plan"])
            }
            
            // Run Safety Check
            let memory = try await AIMemoryRepository.shared.fetchMemory()
            let dictItems = allFoods.map { ["name": $0.name] }
            let violations = FoodSafetyValidator.shared.validateFoodItems(dictItems, against: memory)
            var validatedFoods = allFoods
            
            if !violations.isEmpty {
                for violation in violations.reversed() {
                    validatedFoods.remove(at: violation.index)
                }
            }
            
            // Validate Calories
            let finalFoods = MealPlanViewModel.validateCalories(items: validatedFoods, target: targetCalories)
            
            // Group and Save Plan as Draft
            var grouped: [String: [PlannedFoodItemModel]] = [:]
            for item in finalFoods {
                let type = MealPlanViewModel.normalizeMealType(item.mealType ?? "Ăn vặt")
                let foodModel = PlannedFoodItemModel(
                    name: item.name,
                    calories: item.calories,
                    protein: item.protein,
                    carbs: item.carbs,
                    fat: item.fat,
                    servingSize: item.servingSize
                )
                grouped[type, default: []].append(foodModel)
            }
            
            let plannedMeals = grouped.map { (type, foods) in
                PlannedMealModel(type: type, foodItems: foods)
            }
            
            let draftPlan = DailyPlanModel(
                date: today,
                status: "draft",
                targetCalories: targetCalories,
                targetProtein: targetCalories * 0.3 / 4,
                targetCarbs: targetCalories * 0.4 / 4,
                targetFat: targetCalories * 0.3 / 9,
                plannedMeals: plannedMeals
            )
            
            try await dailyPlanRepository.savePlan(draftPlan, status: "draft")
            
            // Save Chat session text
            let completeText = "Mình đã tạo thực đơn hôm nay. Bạn xem lại rồi chốt kế hoạch nhé."
            let chatMsg = ChatMessageModel(
                role: .assistant,
                text: completeText,
                inputMode: "voice",
                outputMode: settings.voiceReplyEnabled ? "voice" : "text",
                suggestedFoods: finalFoods
            )
            await saveAndMirrorMessage(chatMsg, sessionId: sessionId)
            
            self.lastResponse = completeText
            self.overlayText = completeText
            self.lastSuggestedFoods = finalFoods
            
            // Trigger view reload & tab transition
            NotificationCenter.default.post(name: NSNotification.Name("mealPlanDidUpdate"), object: nil)
            NotificationCenter.default.post(name: NSNotification.Name("navigateToJournal"), object: nil)
            
            // Give Tab switch a split second, then PRESENT sheet
            Task {
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                NotificationCenter.default.post(name: NSNotification.Name("openDailyPlanning"), object: nil)
            }
            
            if self.settings.voiceReplyEnabled {
                self.state = .speakingAIResponse
                self.siriOverlayPhase = .speaking
                self.executeSpeak(completeText)
            } else {
                self.siriOverlayPhase = .closing
                self.state = .idle
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                if self.state == .idle {
                    self.siriOverlayPhase = .hidden
                    self.startListening()
                }
            }
        } catch {
            print("❌ Failed to generate plan via voice: \(error)")
            let errorMsg = "Mình chưa tạo được thực đơn lúc này. Bạn thử lại sau một chút nhé."
            self.overlayText = errorMsg
            self.lastResponse = errorMsg
            
            // Save Error to Chat for synchronization
            let errorChatMsg = ChatMessageModel(
                role: .assistant,
                text: errorMsg,
                inputMode: "voice",
                outputMode: settings.voiceReplyEnabled ? "voice" : "text",
                isError: true
            )
            await saveAndMirrorMessage(errorChatMsg, sessionId: sessionId)
            
            if self.settings.voiceReplyEnabled {
                self.state = .speakingAIResponse
                self.siriOverlayPhase = .speaking
                self.executeSpeak(errorMsg)
            } else {
                self.siriOverlayPhase = .closing
                self.state = .idle
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                if self.state == .idle {
                    self.siriOverlayPhase = .hidden
                    self.startListening()
                }
            }
        }
    }

    private func detectIntent(_ text: String) -> String {
        let routedIntent = VoiceCommandIntentRouter.route(transcript: text)
        switch routedIntent {
        case .mealLogging: return "meal_logging"
        case .dailyPlanRequest, .weeklyPlanRequest, .nutritionQuestion: return "plan_question"
        case .cookingQuestion: return "cooking_advice"
        case .progressQuestion: return "progress_question"
        case .rebalanceRequest: return "rebalance_request"
        case .weatherQuestion, .generalChat: return "general_chat"
        }
    }
    
    // MARK: - Diagnostics & Test Helpers
    
    func showTestOverlay() {
        print("[VoiceManager] 🧪 Test Overlay triggered.")
        stopAllActivities()
        self.state = .wakeDetected
        self.lastResponse = "Mình nghe đây. Overlay đang hoạt động!"
    }
    
    func startSpeechTest() {
        print("[VoiceManager] 🧪 Test Speech triggered.")
        stopAllActivities()
        state = .commandListening
        speechService.silenceTimeout = 5.0
        speechService.startListening()
        
        audioLevelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.audioLevel = self.speechService.audioLevel
                self.currentTranscript = self.speechService.transcript
            }
        }
    }
    
    func startWakeTest() {
        print("[VoiceManager] 🧪 Test Wake triggered.")
        Task {
            if !audioEngine.isRunning {
                try? setupAudioSession()
                setupAudioEngineTap()
                try? audioEngine.start()
            }
            
            state = .wakeChecking
            errorMessage = nil
            
            speechService.startShortSession(maxDuration: 8.0, useInternalEngine: false) { [weak self] transcript in
                Task { @MainActor [weak self] in
                    print("[VoiceManager] 🧪 Test Wake finished session.")
                    self?.handleWakeCheckResult(transcript)
                }
            }
        }
    }
    
    func startTestWakeResponse() {
        print("[VoiceManager] 🧪 Test Selected Wake Response triggered.")
        handleWakeDetected()
    }
    
    // MARK: - TTS
    
    func speakResponse(_ text: String, completion: (() -> Void)? = nil) {
        let originalCallback = ttsService.onFinished
        
        ttsService.onFinished = { [weak self] in
            Task { @MainActor in
                completion?()
                if completion == nil {
                    self?.state = .idle
                    self?.siriOverlayPhase = .hidden
                    self?.startListening()
                }
                self?.setupCallbacks()
            }
        }
        
        // Stop recognition if speaking
        speechService.stopListening()
        
        executeSpeak(text)
        state = .speakingAIResponse
        siriOverlayPhase = .speaking
    }
    
    // MARK: - Helpers & Lifecycle
    
    func checkPermissions() async -> VoiceAssistantPermissionResult {
        let micStatus = AVAudioApplication.shared.recordPermission
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        
        let micStatusConverted: VoiceAssistantPermissionStatus = {
            switch micStatus {
            case .granted: return .granted
            case .denied: return .denied
            case .undetermined: return .notDetermined
            @unknown default: return .denied
            }
        }()
        
        let speechStatusConverted: VoiceAssistantPermissionStatus = {
            switch speechStatus {
            case .authorized: return .granted
            case .denied: return .denied
            case .notDetermined: return .notDetermined
            case .restricted: return .restricted
            @unknown default: return .denied
            }
        }()
        
        let canUse = micStatusConverted == .granted && speechStatusConverted == .granted
        
        return VoiceAssistantPermissionResult(
            microphoneStatus: micStatusConverted,
            speechStatus: speechStatusConverted,
            canUseVoiceAssistant: canUse,
            message: canUse ? nil : "Thiếu quyền truy cập Micro hoặc Nhận dạng giọng nói."
        )
    }
    
    func requestPermissionsIfNeeded() async -> VoiceAssistantPermissionResult {
        let _ = await AVAudioApplication.requestRecordPermission()
        let _ = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in continuation.resume(returning: status) }
        }
        return await checkPermissions()
    }
    
    func handleAppBackground() {
        print("[VoiceManager] 📱 App background.")
        isAppForeground = false
        stopListening()
    }
    
    func handleAppForeground() {
        print("[VoiceManager] 📱 App foreground.")
        isAppForeground = true
        if settings.globalWakeEnabled { startListening() }
    }
    
    func dismissOverlay() {
        print("[VoiceManager] 🔻 User requested explicit overlay hide.")
        // Map to standard forceClose() to safely end active UI session while preserving engine if globalWake active
        forceClose()
    }
    
    // MARK: - Window & Continuous Controls
    
    func minimizeOverlay() {
        print("[VoiceManager] 🧭 Minimizing overlay to right side orb.")
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            self.conversationMode = .activeMinimized
        }
        // We keep speech capture if previously listening, but prompt text becomes silent
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    func expandOverlay() {
        print("[VoiceManager] 🧭 Expanding overlay from orb.")
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            self.conversationMode = .activeExpanded
            if self.state == .commandListening {
                self.conversationMode = .listening
            } else if self.state == .processingCommand {
                self.conversationMode = .processing
            }
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        self.resetActiveSessionTimer()
    }
    
    func forceClose() {
        print("[VoiceManager] 🔻 Deactivating continuous Assistant session.")
        self.activeSessionTimer?.invalidate()
        self.activeSessionTimer = nil
        
        self.conversationMode = .inactive
        self.siriOverlayPhase = .closing
        
        ttsService.stop()
        speechService.stopListening()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.siriOverlayPhase = .hidden
            self.state = .idle
            self.isProcessingCommand = false
            
            // Re-activate ambient wake background gate if enabled
            if self.settings.globalWakeEnabled {
                self.startListening()
            }
        }
    }
    
    func resetActiveSessionTimer() {
        self.activeSessionTimer?.invalidate()
        
        // 3-Minute active session timeout
        self.activeSessionTimer = Timer.scheduledTimer(withTimeInterval: 180.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.handleActiveSessionTimeout()
            }
        }
    }
    
    private func handleActiveSessionTimeout() {
        print("[VoiceManager] ⏱️ Active continuous session timeout. Minimizing to save visual real estate.")
        if self.conversationMode != .inactive && self.conversationMode != .activeMinimized {
            self.minimizeOverlay()
        }
    }
    
    // MARK: - Realtime Message Mirror Helpers
    
    private func saveAndMirrorMessage(_ msg: ChatMessageModel, sessionId: UUID) async {
        var mutableMsg = msg
        mutableMsg.sessionId = sessionId
        
        // Write to DB
        do {
            try await chatRepository.saveMessage(mutableMsg, sessionId: sessionId)
            print("[ChatRealtime] ✅ Message persisted to CoreData: '\(mutableMsg.text.prefix(15))...'")
        } catch {
            print("[ChatRealtime] ❌ Error persisting message: \(error)")
        }
        
        // Broadcast live to standard UI ViewModels
        await MainActor.run {
            NotificationCenter.default.post(name: .chatMessageSavedExternally, object: mutableMsg)
        }
    }
    
    private func setupAudioSession() throws {
        try setupAudioSession(forMode: .recording)
    }
    
    enum AudioSessionConfigMode {
        case recording
        case speaking
    }
    
    func setupAudioSession(forMode configMode: AudioSessionConfigMode) throws {
        let audioSession = AVAudioSession.sharedInstance()
        
        switch configMode {
        case .recording:
            print("[Audio] 🎙️ Mode: Recording (.playAndRecord + .voiceChat)")
            try audioSession.setCategory(
                .playAndRecord,
                mode: .voiceChat, // Optimized for accurate voice capturing
                options: [.defaultToSpeaker, .allowBluetooth, .duckOthers]
            )
        case .speaking:
            print("[Audio] 🔊 Mode: Premium Playback (.playAndRecord + .videoChat)")
            try audioSession.setCategory(
                .playAndRecord,
                mode: .videoChat, // Forces FaceTime-quality bottom loudspeaker
                options: [.defaultToSpeaker, .allowBluetooth, .duckOthers]
            )
        }
        
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        let route = audioSession.currentRoute
        let outputs = route.outputs.map { "\($0.portName) (\($0.portType.rawValue))" }.joined(separator: ", ")
        print("[Audio] 📍 Audio Route Outputs: \(outputs.isEmpty ? "Internal/System" : outputs)")
    }
    
    func executeSpeak(_ text: String) {
        do {
            try setupAudioSession(forMode: .speaking)
        } catch {
            print("[Audio] ❌ Switch to premium speaking mode failed: \(error.localizedDescription)")
        }
        ttsService.speak(text)
    }
    
    private func deepCopyBuffer(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard let copy = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: buffer.frameCapacity) else { return nil }
        copy.frameLength = buffer.frameLength
        
        guard let src = buffer.floatChannelData, let dst = copy.floatChannelData else { return nil }
        
        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)
        
        for i in 0..<channelCount {
            dst[i].update(from: src[i], count: frameLength)
        }
        
        return copy
    }
}
