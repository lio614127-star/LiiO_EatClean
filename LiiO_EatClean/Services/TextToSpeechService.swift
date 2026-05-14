import AVFoundation
import Foundation
import SwiftUI

// MARK: - Protocols & Types

protocol TextToSpeechEngine: NSObject {
    var isSpeaking: Bool { get }
    var onFinished: (() -> Void)? { get set }
    func speak(_ text: String, voiceName: String, rate: Double, pitch: Double, volume: Double) async throws
    func stop()
}

enum TTSEngineMode: String, CaseIterable {
    case auto = "auto"
    case azure = "azure"
    case appleLocal = "appleLocal"
    
    var displayName: String {
        switch self {
        case .auto: return "Tự động"
        case .azure: return "Microsoft Neural"
        case .appleLocal: return "Giọng iOS mặc định"
        }
    }
}

// MARK: - coordinator

@Observable
class TextToSpeechService: NSObject {
    var isSpeaking: Bool {
        activeEngine?.isSpeaking ?? false
    }
    var onFinished: (() -> Void)?
    var lastError: String? = nil
    var currentEngineName: String = "None"
    
    private var activeEngine: TextToSpeechEngine?
    private let localEngine = AppleLocalTTSEngine()
    private let azureEngine = AzureNeuralTTSEngine()
    
    private let settings: AssistantVoiceSettings
    
    init(settings: AssistantVoiceSettings = AssistantVoiceSettings()) {
        self.settings = settings
        super.init()
    }
    
    private var activeCompletion: (() -> Void)?
    
    func speak(_ text: String, completion: (() -> Void)? = nil) {
        lastError = nil
        let cleanedText = VoiceResponseTextFormatter.formatForSpeech(text, assistantName: settings.assistantSpokenName)
        self.activeCompletion = completion
        
        Task {
            let mode = TTSEngineMode(rawValue: settings.ttsEngineMode) ?? .auto
            let voiceName = settings.selectedTTSVoice
            let rate = settings.ttsRate
            let pitch = settings.ttsPitch
            let volume = settings.ttsVolume
            
            do {
                switch mode {
                case .azure:
                    try await useAzure(cleanedText, voiceName: voiceName, rate: rate, pitch: pitch, volume: volume)
                case .appleLocal:
                    try await useApple(cleanedText, rate: rate, pitch: pitch, volume: volume)
                case .auto:
                    do {
                        try await useAzure(cleanedText, voiceName: voiceName, rate: rate, pitch: pitch, volume: volume)
                    } catch {
                        print("[TTS] ⚠️ Azure failed, falling back to Apple Local: \(error.localizedDescription)")
                        try await useApple(cleanedText, rate: rate, pitch: pitch, volume: volume)
                    }
                }
            } catch {
                print("[TTS] ❌ speak failed: \(error.localizedDescription)")
                await MainActor.run {
                    self.lastError = error.localizedDescription
                    // Safety: always call completion on error
                    self.onFinished?()
                }
            }
        }
    }
    
    func speakLocal(_ text: String, voiceName: String = "vi-VN", rate: Double = 1.0, volume: Double = 1.0) {
        Task {
            do {
                print("[TTS] 📻 Triggering zero-latency local speech: '\(text)'")
                try await useApple(text, rate: rate, pitch: 1.0, volume: volume)
            } catch {
                print("[TTS] ⚠️ Local speech failed: \(error.localizedDescription)")
            }
        }
    }
    
    func stop() {
        activeEngine?.stop()
    }
    
    private func handleFinished() {
        activeCompletion?()
        activeCompletion = nil
        onFinished?()
    }
    
    private func useAzure(_ text: String, voiceName: String, rate: Double, pitch: Double, volume: Double) async throws {
        activeEngine = azureEngine
        currentEngineName = "Azure Neural"
        azureEngine.onFinished = { [weak self] in
            self?.handleFinished()
        }
        try await azureEngine.speak(text, voiceName: voiceName, rate: rate, pitch: pitch, volume: volume)
    }
    
    private func useApple(_ text: String, rate: Double, pitch: Double, volume: Double) async throws {
        activeEngine = localEngine
        currentEngineName = "Apple Local"
        localEngine.onFinished = { [weak self] in
            self?.handleFinished()
        }
        try await localEngine.speak(text, voiceName: "vi-VN", rate: rate, pitch: pitch, volume: volume)
    }
}

// MARK: - Apple Local Engine

class AppleLocalTTSEngine: NSObject, TextToSpeechEngine, AVSpeechSynthesizerDelegate {
    private(set) var isSpeaking: Bool = false
    var onFinished: (() -> Void)?
    
    private let synthesizer = AVSpeechSynthesizer()
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func speak(_ text: String, voiceName: String, rate: Double, pitch: Double, volume: Double) async throws {
        stop()
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setActive(true)
        
        let route = audioSession.currentRoute
        let outputs = route.outputs.map { "\($0.portName) (\($0.portType.rawValue))" }.joined(separator: ", ")
        print("[TTS Engine] 🍎 Running AppleLocal engine. Voice: \(voiceName), Rate: \(rate), Vol: \(volume)")
        print("[TTS Audio] 📍 Session Category: \(audioSession.category.rawValue), Route outputs: \(outputs)")
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: voiceName)
        
        // Mapping rate: Apple's default is 0.5. Range 0.0 to 1.0.
        // We use 1.0 as "normal".
        let baseRate: Float = 0.48
        if rate > 1.0 { utterance.rate = baseRate * 1.15 }
        else if rate < 1.0 { utterance.rate = baseRate * 0.85 }
        else { utterance.rate = baseRate }
        
        // Mapping pitch: Apple's range 0.5 to 2.0. Default 1.0.
        if pitch > 1.0 { utterance.pitchMultiplier = 1.08 }
        else if pitch < 1.0 { utterance.pitchMultiplier = 0.92 }
        else { utterance.pitchMultiplier = 1.0 }
        
        utterance.volume = Float(volume)
        
        isSpeaking = true
        print("[TTS Audio] 🗣️ AVSpeechSynthesizer starting speech output...")
        synthesizer.speak(utterance)
    }
    
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        onFinished?()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
        onFinished?()
    }
}

// MARK: - Azure Neural Engine

class AzureNeuralTTSEngine: NSObject, TextToSpeechEngine, AVAudioPlayerDelegate {
    private(set) var isSpeaking: Bool = false
    var onFinished: (() -> Void)?
    
    private var audioPlayer: AVAudioPlayer?
    private let azureRegion = "eastus"
    
    func speak(_ text: String, voiceName: String, rate: Double, pitch: Double, volume: Double) async throws {
        stop()
        
        let keys = await APIKeyPoolManager.shared.getKeys()
        let azureKey = keys.first { $0.provider == "azure_tts" && $0.isActive }?.key
            ?? ProcessInfo.processInfo.environment["AZURE_SPEECH_KEY"]
            ?? ""
        
        if azureKey.isEmpty {
            throw NSError(domain: "AzureTTS", code: -2, userInfo: [NSLocalizedDescriptionKey: "Azure API Key not found"])
        }
        
        print("[TTS Engine] ☁️ Azure Neural start. Fetching audio for: '\(text.prefix(30))...'")
        let audioData = try await fetchAzureAudio(text: text, voice: voiceName, rate: rate, pitch: pitch, volume: volume, key: azureKey, region: azureRegion)
        print("[TTS Audio] 📥 Fetched \(audioData.count) bytes of Azure Neural MP3 data.")
        
        try await MainActor.run {
            let audioSession = AVAudioSession.sharedInstance()
            try? audioSession.setActive(true)
            
            let route = audioSession.currentRoute
            let outputs = route.outputs.map { "\($0.portName) (\($0.portType.rawValue))" }.joined(separator: ", ")
            print("[TTS Audio] 📍 Pre-Playback: Category \(audioSession.category.rawValue), Outputs: \(outputs)")
            
            self.audioPlayer = try AVAudioPlayer(data: audioData)
            self.audioPlayer?.delegate = self
            self.audioPlayer?.volume = Float(volume)
            
            let isPrepped = self.audioPlayer?.prepareToPlay() ?? false
            let duration = self.audioPlayer?.duration ?? 0.0
            print("[TTS Audio] 🎬 Player prepared=\(isPrepped), Duration=\(String(format: "%.2f", duration))s")
            
            self.isSpeaking = true
            let isPlaying = self.audioPlayer?.play() ?? false
            print("[TTS Audio] 🔈 Player play() returned=\(isPlaying), actualIsPlaying=\(self.audioPlayer?.isPlaying ?? false)")
        }
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isSpeaking = false
    }
    
    private func fetchAzureAudio(text: String, voice: String, rate: Double, pitch: Double, volume: Double, key: String, region: String) async throws -> Data {
        let url = URL(string: "https://\(region).tts.speech.microsoft.com/cognitiveservices/v1")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(key, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        request.setValue("application/ssml+xml", forHTTPHeaderField: "Content-Type")
        request.setValue("audio-24khz-48kbitrate-mono-mp3", forHTTPHeaderField: "X-Microsoft-OutputFormat")
        request.setValue("LiiO-EatClean-iOS", forHTTPHeaderField: "User-Agent")
        
        // Escape XML special characters
        let escapedText = text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
        
        // SSML Tuning
        let rateStr = rate > 1.0 ? "+15%" : (rate < 1.0 ? "-15%" : "0%")
        let pitchStr = pitch > 1.0 ? "+5%" : (pitch < 1.0 ? "-5%" : "0%")
        let volStr = String(format: "%.0f", volume * 100)
        
        let ssml = """
        <speak version='1.0' xml:lang='vi-VN'>
          <voice xml:lang='vi-VN' name='\(voice)'>
            <prosody rate='\(rateStr)' pitch='\(pitchStr)' volume='\(volStr)'>
              \(escapedText)
            </prosody>
          </voice>
        </speak>
        """
        request.httpBody = ssml.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "AzureTTS", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
        }
        
        if httpResponse.statusCode != 200 {
            throw NSError(domain: "AzureTTS", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Azure error: \(httpResponse.statusCode)"])
        }
        
        return data
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isSpeaking = false
        onFinished?()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        isSpeaking = false
        onFinished?()
    }
}
