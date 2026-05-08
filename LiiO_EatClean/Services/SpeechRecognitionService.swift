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
    private var audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    
    // Silence detection
    private var silenceTimer: Timer?
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
    
    func startListening() {
        guard let recognizer = recognizer else {
            self.error = "Nhận diện giọng nói không khả dụng."
            return
        }
        
        // Reset state
        self.error = nil
        self.transcript = ""
        
        do {
            try setupAudioSession()
            
            // Cancel previous task
            recognitionTask?.cancel()
            recognitionTask = nil
            
            // Setup request
            request = SFSpeechAudioBufferRecognitionRequest()
            guard let request = request else {
                self.error = "Không thể tạo request nhận diện."
                return
            }
            request.shouldReportPartialResults = true
            
            // Setup audio input
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.removeTap(onBus: 0) // Ensure no previous tap
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                self?.request?.append(buffer)
                
                // Calculate audio power for waveform
                guard let channelData = buffer.floatChannelData?[0] else { return }
                let frames = buffer.frameLength
                var sum: Float = 0
                for i in 0..<Int(frames) {
                    sum += channelData[i] * channelData[i]
                }
                let rms = sqrt(sum / Float(frames))
                let avgPower = 20 * log10(max(rms, 0.000001))
                // Normalize: -60dB..0dB → 0.0..1.0
                let normalized = max(0, min(1, (avgPower + 60) / 60))
                DispatchQueue.main.async {
                    self?.audioLevel = normalized
                }
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            isListening = true
            
            // Start recognition task
            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                guard let self = self else { return }
                
                if let result = result {
                    DispatchQueue.main.async {
                        self.transcript = result.bestTranscription.formattedString
                        self.resetSilenceTimer()
                    }
                }
                
                if let error = error {
                    // Ignore cancellation errors
                    if let nsError = error as NSError?, nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 216 {
                        // Task was cancelled
                    } else if let nsError = error as NSError?, nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 203 {
                        // Task timeout
                    } else {
                        DispatchQueue.main.async {
                            self.error = "Lỗi nhận diện: \(error.localizedDescription)"
                            self.stopListening()
                        }
                    }
                } else if result?.isFinal == true {
                    DispatchQueue.main.async {
                        self.stopListening()
                    }
                }
            }
            
            resetSilenceTimer()
            
        } catch {
            self.error = "Lỗi khởi tạo audio: \(error.localizedDescription)"
            stopListening()
        }
    }
    
    func stopListening() {
        guard isListening else { return }
        
        silenceTimer?.invalidate()
        silenceTimer = nil
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        request?.endAudio()
        
        isListening = false
        audioLevel = 0.0
    }
    
    private func setupAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    private func resetSilenceTimer() {
        DispatchQueue.main.async { [weak self] in
            self?.silenceTimer?.invalidate()
            self?.silenceTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                self?.onSilenceTimeout?()
            }
        }
    }
}
