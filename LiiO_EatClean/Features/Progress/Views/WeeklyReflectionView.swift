import SwiftUI

struct WeeklyReflectionView: View {
    @Environment(\.dismiss) var dismiss
    let adherenceScore: Double
    let nutritionScore: Double
    @AppStorage("last_weekly_energy_level") private var energyLevel: Int = -1 // -1: None, 0: Exhausted, 1: OK, 2: Energetic
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Tổng kết tuần")
                            .font(.largeTitle.bold())
                        Text("Phân tích chuyển hóa & hiệu suất")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 24)
                    
                    // Score Section
                    HStack(spacing: 20) {
                        ScoreRingView(score: adherenceScore, label: "Tuân thủ", color: .blue)
                        ScoreRingView(score: nutritionScore, label: "Dinh dưỡng", color: .green)
                        ScoreRingView(score: 0.70, label: "Vận động", color: .orange)
                    }
                    .padding(.horizontal)
                    
                    // Insight Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Phân tích từ AI Coach")
                            .font(.headline)
                        
                        Text("Dựa trên dữ liệu log thực tế, tính tuân thủ của bạn đang ở mức \(Int(adherenceScore * 100))%. Hãy tập trung bám sát mục tiêu PCF trong những ngày tới.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(20)
                    .padding(.horizontal)
                    
                    // Action Section
                    VStack(spacing: 12) {
                        Text("Bạn cảm thấy thế nào về mức năng lượng?")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            EnergyButton(label: "Kiệt sức", icon: "battery.0", isSelected: energyLevel == 0) { energyLevel = 0 }
                            EnergyButton(label: "Ổn", icon: "battery.50", isSelected: energyLevel == 1) { energyLevel = 1 }
                            EnergyButton(label: "Sung sức", icon: "battery.100", isSelected: energyLevel == 2) { energyLevel = 2 }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Xong") { dismiss() }
                }
            }
        }
    }
}

struct ScoreRingView: View {
    let score: Double
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.1), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: max(0.01, score))
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(score * 100))%")
                    .font(.caption.bold())
            }
            .frame(width: 60, height: 60)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

struct EnergyButton: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(label)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color.green.opacity(0.2) : Color(.secondarySystemGroupedBackground))
            .foregroundColor(isSelected ? .green : .primary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
            )
        }
    }
}

#Preview {
    WeeklyReflectionView(adherenceScore: 0.85, nutritionScore: 0.92)
}
