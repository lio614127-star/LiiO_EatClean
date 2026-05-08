import SwiftUI

struct ActivityRow: View {
    let activity: AIActivity
    
    var body: some View {
        HStack(spacing: 10) {
            // Icon
            ZStack {
                Circle()
                    .fill(activity.provider == "gemini" ? Color.blue.opacity(0.1) : Color.green.opacity(0.1))
                    .frame(width: 28, height: 28)
                
                Image(systemName: activity.provider == "gemini" ? "sparkles" : "bolt.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(activity.provider == "gemini" ? .blue : .green)
                    .symbolEffect(.bounce, options: .repeating, value: !activity.isFinished)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Header: Model + Key Info
                HStack(spacing: 4) {
                    Text(activity.modelName)
                        .font(.system(size: 11, weight: .bold))
                    
                    if let keyName = activity.keyName {
                        Text("|")
                            .foregroundColor(.secondary.opacity(0.5))
                        Text(keyName)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    if let tier = activity.keyTier {
                        Text(tier)
                            .font(.system(size: 9, weight: .black))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(tier == "PAID" ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.2))
                            .foregroundColor(tier == "PAID" ? .orange : .secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                }
                
                // Sub-tasks list or main feature
                if !activity.subTasks.isEmpty {
                    VStack(alignment: .leading, spacing: 1) {
                        ForEach(activity.subTasks, id: \.self) { task in
                            HStack(spacing: 4) {
                                Circle().fill(Color.green).frame(width: 4, height: 4)
                                Text(task)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.primary.opacity(0.8))
                            }
                        }
                    }
                    .padding(.top, 2)
                } else {
                    HStack(spacing: 4) {
                        Circle().fill(Color.green).frame(width: 4, height: 4)
                        Text(activity.featureSource)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.primary.opacity(0.8))
                    }
                    .padding(.top, 2)
                }
                
                // Progress text
                HStack(spacing: 4) {
                    Text(activity.progressText)
                        .font(.system(size: 10))
                        .foregroundColor(statusColor)
                    
                    if !activity.isFinished {
                        ProgressView()
                            .scaleEffect(0.4)
                            .frame(width: 8, height: 8)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(UIColor.secondarySystemBackground).opacity(0.8))
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(statusColor.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var statusColor: Color {
        switch activity.status {
        case .completed: return .green
        case .failed: return .red
        case .swapping: return .orange
        default: return .primary
        }
    }
}
