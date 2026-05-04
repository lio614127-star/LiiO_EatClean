import SwiftUI

struct MemoryUpdateConfirmationView: View {
    let updates: [MemoryUpdate]
    let onConfirm: ([MemoryUpdate]) -> Void
    let onDismiss: () -> Void
    
    @State private var selectedIndices: Set<Int> = []
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("AI vừa nhận ra một số thông tin quan trọng về bạn. Bạn có muốn ghi nhớ những điều này để gợi ý món ăn chuẩn xác hơn không?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                List {
                    ForEach(Array(updates.enumerated()), id: \.offset) { index, update in
                        Button {
                            if selectedIndices.contains(index) {
                                selectedIndices.remove(index)
                            } else {
                                selectedIndices.insert(index)
                            }
                        } label: {
                            HStack {
                                Image(systemName: selectedIndices.contains(index) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedIndices.contains(index) ? .green : .gray)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(titleFor(update))
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    if let details = detailsFor(update) {
                                        Text(details)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.leading, 8)
                                
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.insetGrouped)
                
                VStack(spacing: 12) {
                    Button {
                        let selectedUpdates = selectedIndices.map { updates[$0] }
                        onConfirm(selectedUpdates)
                    } label: {
                        Text(selectedIndices.isEmpty ? "Xong" : "Lưu \(selectedIndices.count) thông tin")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedIndices.isEmpty ? Color.gray : Color.green)
                            .cornerRadius(12)
                    }
                    .disabled(selectedIndices.isEmpty)
                    
                    Button("Bỏ qua", action: onDismiss)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("💡 Trí nhớ AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng", action: onDismiss)
                }
            }
        }
        .onAppear {
            // Select all by default
            selectedIndices = Set(0..<updates.count)
        }
    }
    
    private func titleFor(_ update: MemoryUpdate) -> String {
        switch update.type {
        case .addCondition: return "Bệnh lý: \(update.value)"
        case .addLike: return "Thích: \(update.value)"
        case .addDislike: return "Không thích: \(update.value)"
        case .addNote: return "Ghi chú: \(update.value)"
        }
    }
    
    private func detailsFor(_ update: MemoryUpdate) -> String? {
        var details: [String] = []
        if let avoid = update.avoid, !avoid.isEmpty {
            details.append("Tránh: \(avoid.joined(separator: ", "))")
        }
        if let notes = update.dietaryNotes, !notes.isEmpty {
            details.append("Lưu ý: \(notes)")
        }
        
        return details.isEmpty ? nil : details.joined(separator: " • ")
    }
}
