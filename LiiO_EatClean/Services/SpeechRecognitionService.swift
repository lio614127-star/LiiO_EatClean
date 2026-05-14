import Speech
import AVFoundation
import SwiftUI

@Observable
class SpeechRecognitionService {
    var transcript: String = ""
    var isListening: Bool = false
    var error: String? = nil
    var audioLevel: Float = 0.0
    
    private var recognizer: SFSpeechRecognizer?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var internalAudioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    var expectedCancellation: Bool = false
    private var currentSessionId: UUID = UUID()
    
    var onTranscriptUpdate: ((String) -> Void)?
    
    // Silence detection
    private var silenceTimer: Timer?
    var silenceTimeout: TimeInterval = 0.8 // Optimized for fast response
    var onSilenceTimeout: (() -> Void)?
    
    init() {
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "vi-VN"))
    }
    
    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.main.async {
                    continuation.resume(returning: status == .authorized)
                }
            }
        }
    }
    
    func startListening(useInternalEngine: Bool = true) {
        guard let recognizer = recognizer, recognizer.isAvailable else {
            self.error = "Nhận diện giọng nói không khả dụng."
            return
        }
        
        self.error = nil
        self.transcript = ""
        self.expectedCancellation = false
        
        // Cleanup previous task thoroughly
        stopListening()
        
        // Setup request
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request = request else {
            self.error = "Không thể tạo request nhận diện."
            return
        }
        request.shouldReportPartialResults = true
        
        if useInternalEngine {
            do {
                try setupAudioSession()
                internalAudioEngine = AVAudioEngine()
                guard let audioEngine = internalAudioEngine else { return }
                
                let inputNode = audioEngine.inputNode
                let inputFormat = inputNode.outputFormat(forBus: 0)
                
                // Safeguard against zero-rate or non-initialized input channels
                let finalSampleRate = inputFormat.sampleRate > 0 ? inputFormat.sampleRate : 44100.0
                let recordingFormat = AVAudioFormat(
                    commonFormat: .pcmFormatFloat32,
                    sampleRate: finalSampleRate,
                    channels: 1, // Highly optimized for Speech Framework
                    interleaved: false
                ) ?? inputFormat
                
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                    guard let self = self, buffer.frameLength > 0 else { return }
                    self.feed(buffer)
                }
                
                audioEngine.prepare()
                try audioEngine.start()
            } catch {
                self.error = "Lỗi âm thanh: \(error.localizedDescription)"
                stopListening()
                return
            }
        }
        
        isListening = true
        
        // Start recognition task
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let text = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.transcript = text
                    self.onTranscriptUpdate?(text)
                    self.resetSilenceTimer()
                }
            }
            
            if let error = error {
                let nsError = error as NSError
                let isCanceled = nsError.domain == "kAFAssistantErrorDomain" && (nsError.code == 216 || nsError.code == 203)
                
                if isCanceled || self.expectedCancellation {
                    // Task cancelled or timeout - normal flow
                    print("[SpeechService] ℹ️ Recognition session ended (expected or canceled).")
                } else {
                    print("[SpeechService] ❌ Recognition error: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.error = "Lỗi: \(error.localizedDescription)"
                    }
                }
            } else if result?.isFinal == true {
                // Final result handled by caller or state
            }
        }
        
        resetSilenceTimer()
    }
    
    func feed(_ buffer: AVAudioPCMBuffer) {
        guard isListening, buffer.frameLength > 0 else { return }
        
        // Guard against zero data size / null pointers
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        request?.append(buffer)
        let frames = buffer.frameLength
        var sum: Float = 0
        for i in 0..<Int(frames) { sum += channelData[i] * channelData[i] }
        let rms = sqrt(sum / Float(frames))
        
        // Apply highly responsive Logarithmic Decibel Scale (dB) for premium visual bouncing
        let minDb: Float = -50.0
        let db = rms > 0.00001 ? 20 * log10(rms) : minDb
        
        // Normalize dB range [-50, -5] to [0, 1]
        let clampedDb = max(minDb, min(-5.0, db))
        let normalized = (clampedDb - minDb) / (-5.0 - minDb)
        
        DispatchQueue.main.async {
            self.audioLevel = normalized
        }
    }
    
    func stopListening() {
        // Invalidate current session ID immediately so any running short-session timers exit
        currentSessionId = UUID()
        
        silenceTimer?.invalidate()
        silenceTimer = nil
        
        if let engine = internalAudioEngine, engine.isRunning {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
            engine.reset() // Purge all hardware graphs
        }
        internalAudioEngine = nil
        
        request?.endAudio()
        request = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isListening = false
        audioLevel = 0.0
    }
    
    func startShortSession(maxDuration: TimeInterval = 3.0, useInternalEngine: Bool = true, onResult: @escaping (String) -> Void) {
        // Start tracking a new session ID before starting listen
        currentSessionId = UUID()
        let sessionId = currentSessionId
        
        startListening(useInternalEngine: useInternalEngine)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + maxDuration) { [weak self] in
            guard let self = self else { return }
            // Critically verify both listening state AND matching session ID!
            guard self.isListening, self.currentSessionId == sessionId else {
                print("[SpeechService] ⏱️ Short session timer discarded. Session expired or changed.")
                return
            }
            
            let finalTranscript = self.transcript
            print("[SpeechService] ⏱️ Short session timeout. Final raw: '\(finalTranscript)'")
            self.stopListening()
            onResult(finalTranscript)
        }
    }
    
    private func setupAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        // MUST match global mode (.voiceChat) to prevent disruptive OS re-routing transitions
        try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth, .duckOthers])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    private func resetSilenceTimer() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.silenceTimer?.invalidate()
            self.silenceTimer = Timer.scheduledTimer(withTimeInterval: self.silenceTimeout, repeats: false) { _ in
                self.onSilenceTimeout?()
            }
        }
    }
}
