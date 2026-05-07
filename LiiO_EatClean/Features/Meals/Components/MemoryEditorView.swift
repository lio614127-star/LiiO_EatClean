import SwiftUI

struct MemoryEditorView: View {
    @State private var memory = MemoryManager.shared.fetchMemory()
    
    var body: some View {
        Form {
            if memory.healthConditions.isEmpty && memory.likes.isEmpty && memory.dislikes.isEmpty && memory.dietaryNotes.isEmpty {
                Text("AI chưa có dữ liệu nào về sở thích và sức khỏe của bạn.")
                    .foregroundColor(.secondary)
                    .listRowBackground(Color.clear)
            }
            
            if !memory.healthConditions.isEmpty {
                Section(header: Text("Bệnh lý & Kiêng cữ")) {
                    ForEach(memory.healthConditions) { condition in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(condition.name)
                                .font(.headline)
                            if !condition.dietaryNotes.isEmpty {
                                Text(condition.dietaryNotes)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        let idsToDelete = indexSet.map { memory.healthConditions[$0].id }
                        for id in idsToDelete {
                            MemoryManager.shared.removeHealthCondition(id: id)
                        }
                        refreshMemory()
                    }
                }
            }
            
            if !memory.likes.isEmpty {
                Section(header: Text("Sở thích (Thích ăn)")) {
                    ForEach(memory.likes, id: \.self) { like in
                        Text(like)
                    }
                    .onDelete { indexSet in
                        let itemsToDelete = indexSet.map { memory.likes[$0] }
                        for item in itemsToDelete {
                            MemoryManager.shared.removeLike(item)
                        }
                        refreshMemory()
                    }
                }
            }
            
            if !memory.dislikes.isEmpty {
                Section(header: Text("Không thích (Tránh ăn)")) {
                    ForEach(memory.dislikes, id: \.self) { dislike in
                        Text(dislike)
                    }
                    .onDelete { indexSet in
                        let itemsToDelete = indexSet.map { memory.dislikes[$0] }
                        for item in itemsToDelete {
                            MemoryManager.shared.removeDislike(item)
                        }
                        refreshMemory()
                    }
                }
            }
            
            if !memory.dietaryNotes.isEmpty {
                Section(header: Text("Ghi chú khác")) {
                    ForEach(memory.dietaryNotes, id: \.self) { note in
                        Text(note)
                    }
                    .onDelete { indexSet in
                        let itemsToDelete = indexSet.map { memory.dietaryNotes[$0] }
                        for item in itemsToDelete {
                            MemoryManager.shared.removeDietaryNote(item)
                        }
                        refreshMemory()
                    }
                }
            }
        }
        .navigationTitle("Trí nhớ AI")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            refreshMemory()
        }
    }
    
    private func refreshMemory() {
        memory = MemoryManager.shared.fetchMemory()
    }
}
