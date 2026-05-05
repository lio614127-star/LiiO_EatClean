import SwiftUI

struct VoiceInputView: View {
    @State private var speechService = SpeechRecognitionService()
    @State private var parserService = VoiceFoodParserService()
    
    @State private var parsedFoods: [AISuggestedFood] = []
    @State private var isParsing = false
    @State private var showResults = false
    
    @Binding var isPresented: Bool
    var onFoodsConfirmed: ([AISuggestedFood]) -> Void
    
    @State private var isPulsing = false
    @State private var permissionError: String? = nil
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if showResults {
                    resultsView
                } else {
                    recordingView
                }
            }
            .navigationTitle(showResults ? "Kết quả" : "Ghi âm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") {
                        speechService.stopListening()
                        isPresented = false
                    }
                }
            }
            .task {
                if !showResults {
                    await startRecordingProcess()
                }
            }
            .onDisappear {
                speechService.stopListening()
            }
        }
    }
    
    // MARK: - Recording View
    private var recordingView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Pulsing Mic
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: isPulsing ? 200 : 120, height: isPulsing ? 200 : 120)
                    .animation(isPulsing ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true) : .default, value: isPulsing)
                
                Circle()
                    .fill(Color.green.opacity(0.4))
                    .frame(width: isPulsing ? 160 : 120, height: isPulsing ? 160 : 120)
                    .animation(isPulsing ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default, value: isPulsing)
                
                Button(action: {
                    if speechService.isListening {
                        stopAndParse()
                    } else {
                        Task { await startRecordingProcess() }
                    }
                }) {
                    Image(systemName: speechService.isListening ? "stop.fill" : "mic.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .frame(width: 120, height: 120)
                        .background(speechService.isListening ? Color.red : Color.green)
                        .clipShape(Circle())
                }
            }
            
            // Status Text
            VStack(spacing: 8) {
                if isParsing {
                    ProgressView()
                    Text("Đang phân tích...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                } else if speechService.isListening {
                    Text("Đang nghe...")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    Text(speechService.transcript.isEmpty ? "Hãy nói món bạn vừa ăn..." : speechService.transcript)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .animation(.default, value: speechService.transcript)
                } else if let error = permissionError ?? speechService.error {
                    Text(error)
                        .font(.body)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                } else {
                    Text("Nhấn vào mic để nói")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if speechService.isListening {
                Button("Dừng và phân tích") {
                    stopAndParse()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .padding(.bottom, 24)
            }
        }
    }
    
    // MARK: - Results View
    private var resultsView: some View {
        VStack {
            if parsedFoods.isEmpty {
                Spacer()
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                    .padding()
                Text("Không tìm thấy món ăn nào.")
                    .font(.headline)
                Text("Vui lòng thử nói rõ hơn.")
                    .foregroundColor(.secondary)
                    .padding(.bottom)
                Button("Thử lại") {
                    showResults = false
                    parsedFoods = []
                    Task { await startRecordingProcess() }
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            } else {
                List {
                    Section(header: Text("Món ăn AI nhận diện được")) {
                        ForEach($parsedFoods) { $food in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(food.name)
                                        .font(.headline)
                                    Text("\(Int(food.calories)) kcal/phần")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                // Quantity Editor
                                HStack(spacing: 12) {
                                    Button(action: {
                                        if food.servingSize > 0.5 { food.servingSize -= 0.5 }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Text("\(food.servingSize, specifier: "%.1f")")
                                        .frame(width: 30)
                                        .multilineTextAlignment(.center)
                                    
                                    Button(action: {
                                        food.servingSize += 0.5
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            parsedFoods.remove(atOffsets: indexSet)
                        }
                    }
                }
                
                // Confirm Button
                Button(action: {
                    HapticManager.success()
                    onFoodsConfirmed(parsedFoods)
                    isPresented = false
                }) {
                    Text("Xác nhận & Thêm (\(parsedFoods.count) món)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(parsedFoods.isEmpty ? Color.gray : Color.green)
                        .cornerRadius(12)
                }
                .disabled(parsedFoods.isEmpty)
                .padding()
            }
        }
    }
    
    // MARK: - Logic
    private func startRecordingProcess() async {
        let authorized = await speechService.requestAuthorization()
        if authorized {
            permissionError = nil
            speechService.startListening()
            isPulsing = true
            HapticManager.interaction()
            
            speechService.onSilenceTimeout = {
                if speechService.isListening {
                    stopAndParse()
                }
            }
        } else {
            permissionError = "Vui lòng cấp quyền Microphone và Speech Recognition trong Cài đặt."
        }
    }
    
    private func stopAndParse() {
        speechService.stopListening()
        isPulsing = false
        
        let textToParse = speechService.transcript
        guard !textToParse.isEmpty else { return }
        
        isParsing = true
        
        Task {
            do {
                parsedFoods = try await parserService.parseTranscript(textToParse)
            } catch {
                print("Voice parse error: \(error)")
                parsedFoods = []
            }
            isParsing = false
            showResults = true
            HapticManager.success()
        }
    }
}
