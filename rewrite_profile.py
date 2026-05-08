import re

with open('/Users/liio/TooL_LiiO/LiiO_EatClean/LiiO_EatClean/Features/Profile/ProfileView.swift', 'r') as f:
    content = f.read()

start_marker = "                // MARK: - API Keys"
end_marker = "                // MARK: - Danger Zone"

start_idx = content.find(start_marker)
end_idx = content.find(end_marker)

if start_idx != -1 and end_idx != -1:
    new_chunk = """                // MARK: - API Keys
                Section {
                    Button(action: {
                        viewModel.showingKeyManager = true
                    }) {
                        HStack {
                            Label("Quản lý API Keys", systemImage: "key.fill")
                            Spacer()
                            Text("\(viewModel.apiKeysCount) keys")
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.primary)
                } header: {
                    Text("AI API Keys")
                } footer: {
                    Text("Cấu hình nhiều API keys để hệ thống tự động fallback khi gặp lỗi.")
                        .font(.caption2)
                }
                
"""
    content = content[:start_idx] + new_chunk + content[end_idx:]
    
    # Add fullScreenCover before task modifier
    task_marker = "        .task {"
    task_idx = content.find(task_marker)
    if task_idx != -1:
        cover_chunk = """        .fullScreenCover(isPresented: $viewModel.showingKeyManager) {
            APIKeyManagerView()
        }
"""
        content = content[:task_idx] + cover_chunk + content[task_idx:]
        
    with open('/Users/liio/TooL_LiiO/LiiO_EatClean/LiiO_EatClean/Features/Profile/ProfileView.swift', 'w') as f:
        f.write(content)
    print("Replaced successfully")
else:
    print("Could not find markers")
