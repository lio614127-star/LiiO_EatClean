import SwiftUI

struct GoalHistoryView: View {
    let history: [GoalHistoryModel]
    
    var body: some View {
        List {
            ForEach(history) { entry in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(formatDate(entry.effectiveFrom))
                            .font(.subheadline.bold())
                        
                        Spacer()
                        
                        if entry.effectiveTo == nil {
                            Text("Hiện tại")
                                .font(.caption.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .clipShape(Capsule())
                        }
                    }
                    
                    HStack(spacing: 16) {
                        MetricView(label: "Calo", value: "\(Int(entry.calorieTarget))")
                        MetricView(label: "Protein", value: "\(Int(entry.proteinTarget))g")
                        MetricView(label: "Cân nặng", value: String(format: "%.1f kg", entry.weight))
                    }
                    
                    if !entry.reason.isEmpty {
                        Text(entry.reason)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .italic()
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Lịch sử mục tiêu")
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct MetricView: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.footnote.bold())
        }
    }
}
