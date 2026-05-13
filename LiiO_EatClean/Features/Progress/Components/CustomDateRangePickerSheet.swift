import SwiftUI

struct CustomDateRangePickerSheet: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var selectedRange: TimeRange
    var onApply: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Quick Presets
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Chọn nhanh")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            presetButton(title: "Hôm nay", days: 0)
                            presetButton(title: "7 ngày", days: 6)
                            presetButton(title: "30 ngày", days: 29)
                            presetButton(title: "90 ngày", days: 89)
                            presetButton(title: "Năm nay", days: -1) // Special case
                        }
                        .padding(.horizontal)
                    }
                    
                    Divider().padding(.horizontal)
                    
                    // Date Pickers
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Khoảng thời gian")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            DatePicker("Từ ngày", selection: $startDate, in: ...endDate, displayedComponents: .date)
                            DatePicker("Đến ngày", selection: $endDate, in: startDate...Date(), displayedComponents: .date)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Live Preview
                    let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
                    let totalDays = days + 1
                    let aggregation: String = totalDays <= 31 ? "Theo ngày" : (totalDays <= 120 ? "Trung bình tuần" : "Trung bình tháng")
                    
                    VStack(spacing: 4) {
                        Text("\(totalDays) ngày")
                            .font(.title3.bold())
                        Text("• \(aggregation)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    Button(action: {
                        selectedRange = .custom
                        onApply()
                        dismiss()
                    }) {
                        Text("Áp dụng")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
                .padding(.vertical)
            }
            .navigationTitle("Tùy chọn thời gian")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func presetButton(title: String, days: Int) -> some View {
        Button(action: {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            if days == -1 {
                // Year to date
                let components = calendar.dateComponents([.year], from: today)
                startDate = calendar.date(from: components)!
                endDate = today
            } else {
                startDate = calendar.date(byAdding: .day, value: -days, to: today)!
                endDate = today
            }
        }) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.05), radius: 2)
        }
    }
}
