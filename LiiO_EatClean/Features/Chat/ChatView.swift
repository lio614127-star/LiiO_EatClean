import SwiftUI

struct ChatView: View {
    @State private var viewModel = ChatViewModel()
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    @State private var showMemoryHub = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.messages) { message in
                                ActionableMessageView(
                                    message: message, 
                                    isStreaming: viewModel.isStreaming && message.id == viewModel.messages.last?.id
                                ) { food in
                                    viewModel.logSuggestedFood(food)
                                }
                                .id(message.id)
                            }
                        }
                        .padding(.vertical, 16)
                    }
                    .onChange(of: viewModel.messages.last?.text) { _ in
                        if viewModel.isStreaming {
                            proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                        }
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        withAnimation {
                            proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
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
                            .padding(.vertical, 10)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(20)
                            .focused($isInputFocused)
                            .disabled(viewModel.isStreaming)
                        
                        Button(action: {
                            sendMessage()
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .resizable()
                                .frame(width: 32, height: 32)
                                .foregroundColor(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .green)
                        }
                        .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isStreaming)
                        .padding(.bottom, 4)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(UIColor.systemBackground))
            }
            .navigationTitle("AI Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showMemoryHub = true
                    }) {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.green)
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
    }
    
    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        viewModel.sendMessage(inputText)
        inputText = ""
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
