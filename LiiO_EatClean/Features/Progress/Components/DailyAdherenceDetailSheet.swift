import SwiftUI

struct DailyAdherenceDetailSheet: View {
    let date: Date
    let snapshot: DailyAdherenceSnapshotModel?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text(date.formatted(.dateTime.day().month().year()))
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                if let score = snapshot?.adherenceScore {
                    Text("\(Int(score))")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(scoreColor(score))
                    
                    Text(statusLabel(score))
                        .font(.title3.bold())
                        .foregroundStyle(scoreColor(score))
                } else {
                    Text("No Data")
                        .font(.title2.bold())
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 20)
                }
            }
            .padding(.top)
            
            // Stats Grid
            if let snapshot = snapshot {
                VStack(spacing: 16) {
                    HStack {
                        statRow(label: "Calories", actual: snapshot.totalCalories, target: snapshot.targetCalories, unit: "kcal")
                        Spacer()
                        statRow(label: "Protein", actual: snapshot.totalProtein, target: snapshot.targetProtein, unit: "g")
                    }
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Bữa ăn")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(snapshot.mealCount) đã ăn / \(snapshot.plannedMealCount) kế hoạch")
                                .font(.body.bold())
                        }
                        Spacer()
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
            }
            
            Spacer()
            
            // Action
            Button {
                // Deep link to Journal
                // We need access to the root TabView state
                NotificationCenter.default.post(name: NSNotification.Name("navigateToJournal"), object: date)
                dismiss()
            } label: {
                Text("Xem chi tiết Journal")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
        }
        .padding(24)
    }
    
    private func statRow(label: String, actual: Double, target: Double, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(Int(actual))")
                    .font(.body.bold())
                Text("/ \(Int(target)) \(unit)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 90...100: return .mint
        case 75..<90: return .green
        case 60..<75: return .yellow
        case 40..<60: return .orange
        case 0.1..<40: return .red
        default: return .secondary
        }
    }
    
    private func statusLabel(_ score: Double) -> String {
        switch score {
        case 90...100: return "Tuyệt vời"
        case 75..<90: return "Rất tốt"
        case 60..<75: return "Bám sát plan"
        case 40..<60: return "Cần chú ý"
        default: return "Lệch mục tiêu"
        }
    }
}
