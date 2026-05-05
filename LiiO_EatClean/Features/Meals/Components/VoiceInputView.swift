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
    @State private var isInitializing = false
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
                    isInitializing = true
                    await startRecordingProcess()
                    isInitializing = false
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
            Button(action: {
                if speechService.isListening {
                    stopAndParse()
                } else {
                    Task {
                        isInitializing = true
                        await startRecordingProcess()
                        isInitializing = false
                    }
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 120, height: 120)
                        .scaleEffect(isPulsing ? 1.8 : 1.0)
                        .opacity(isPulsing ? 0.0 : 0.3)
                        .animation(isPulsing ? .easeOut(duration: 1.5).repeatForever(autoreverses: false) : .default, value: isPulsing)
                    
                    Circle()
                        .fill(Color.green.opacity(0.25))
                        .frame(width: 120, height: 120)
                        .scaleEffect(isPulsing ? 1.4 : 1.0)
                        .opacity(isPulsing ? 0.0 : 0.5)
                        .animation(isPulsing ? .easeOut(duration: 1.5).repeatForever(autoreverses: false).delay(0.3) : .default, value: isPulsing)
                    
                    Image(systemName: "mic.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .frame(width: 120, height: 120)
                        .background(Color.green)
                        .clipShape(Circle())
                }
                .frame(width: 220, height: 220) // Fixed container to prevent layout jumps
            }
            .buttonStyle(.plain)
            .disabled(isInitializing)
            
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
                } else if isInitializing {
                    Text("Đang khởi tạo...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                } else {
                    Text("Nhấn vào mic để nói")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: 100, alignment: .top) // Fixed height prevents layout jumps
            
            Spacer()
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
            
            speechService.onSilenceTimeout = { [weak speechService] in
                if speechService?.isListening == true {
                    stopAndParse()
                }
            }
            
            speechService.startListening()
            isPulsing = true
            HapticManager.interaction()
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
