import SwiftUI

struct WeeklyPlanView: View {
    @Bindable var viewModel: MealPlanViewModel
    let targetCalories: Double
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedDay: WeeklyDayPlan?
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoadingWeekly {
                    VStack(spacing: 12) {
                        // Real-time model transparency rows for parallel tasks (Days of the week)
                        let dayOrder = ["Thứ 2", "Thứ 3", "Thứ 4", "Thứ 5", "Thứ 6", "Thứ 7", "Chủ Nhật"]
                        let weeklyActivities = AIActivityCenter.shared.activities.filter { 
                            ($0.featureSource.contains("Thứ") || 
                             $0.featureSource.contains("Chủ Nhật") || 
                             $0.featureSource.contains("Gom")) && 
                            $0.status != .completed
                        }.sorted { a1, a2 in
                            let o1 = dayOrder.firstIndex(where: { a1.featureSource.contains($0) }) ?? 99
                            let o2 = dayOrder.firstIndex(where: { a2.featureSource.contains($0) }) ?? 99
                            return o1 < o2
                        }
                        
                        ForEach(weeklyActivities) { activity in
                            ActivityRow(activity: activity)
                                .frame(maxWidth: 320)
                                .transition(.opacity.combined(with: .scale))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 60)
                    .padding(.horizontal)
                    .animation(.spring(), value: AIActivityCenter.shared.activities)
                } else if viewModel.weeklyPlan.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("Chưa có kế hoạch tuần")
                            .font(.headline)
                        
                        if let error = viewModel.weeklyErrorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        } else {
                            Text("Nhấn nút bên dưới để tạo")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Button {
                            Task { await viewModel.generateWeekPlan(targetCalories: targetCalories) }
                        } label: {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("Tạo kế hoạch tuần")
                            }
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.green)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            // Header
                            VStack(spacing: 4) {
                                Text("Kế hoạch tuần")
                                    .font(.title2.bold())
                                Text("Nhấn vào ngày để xem chi tiết")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 8)
                            .padding(.bottom, 4)
                            
                            // 7 day rows (D-05: compact 7-row overview)
                            ForEach(viewModel.weeklyPlan) { dayPlan in
                                WeeklyDayRow(dayPlan: dayPlan)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedDay = dayPlan
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") { dismiss() }
                }
            }
            .sheet(item: $selectedDay) { dayPlan in
                WeeklyDayDetailView(dayPlan: dayPlan, targetCalories: targetCalories)
            }
        }
        .task {
            if viewModel.weeklyPlan.isEmpty {
                await viewModel.generateWeekPlan(targetCalories: targetCalories)
            }
        }
    }
}

// MARK: - Weekly Day Row (compact, D-05)

struct WeeklyDayRow: View {
    let dayPlan: WeeklyDayPlan
    
    var body: some View {
        HStack {
            // Day label
            Text(dayPlan.day)
                .font(.headline)
                .foregroundColor(.green)
                .frame(width: 60, alignment: .leading)
            
            // Separator
            Text("—")
                .foregroundColor(.secondary)
            
            // Total kcal
            Text("\(Int(dayPlan.totalCalories)) kcal")
                .font(.subheadline.bold())
                .frame(width: 80, alignment: .leading)
            
            // Highlight foods
            Text(dayPlan.highlights.joined(separator: " • "))
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Day Detail View (reuses MealPlanCard pattern)

struct WeeklyDayDetailView: View {
    let dayPlan: WeeklyDayPlan
    let targetCalories: Double
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 4) {
                        Text("Thực đơn \(dayPlan.day)")
                            .font(.title2.bold())
                        Text("Tổng: \(Int(dayPlan.totalCalories)) kcal")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                    
                    // Cards per meal type (view-only, no log action for weekly preview)
                    ForEach(MealPlanViewModel.mealTypes, id: \.self) { mealType in
                        let foods = dayPlan.items.filter { ($0.mealType ?? "Ăn vặt") == mealType }
                        if !foods.isEmpty {
                                MealPlanCard(
                                    mealType: mealType,
                                    foods: foods,
                                    isLogged: false,
                                    isViewOnly: true,
                                    onLog: {} // No-op for weekly preview
                                )
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") { dismiss() }
                }
            }
        }
    }
}
