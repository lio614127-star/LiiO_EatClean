import SwiftUI

struct WeeklyPlanView: View {
    @Bindable var viewModel: MealPlanViewModel
    let targetCalories: Double
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedDay: WeeklyDayPlan?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Header (D-05: compact 7-row overview)
                    VStack(spacing: 2) {
                        Text("Kế hoạch tuần")
                            .font(.title3.bold())
                        Text("Nhấn vào ngày để xem chi tiết")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 4)
                    
                    if viewModel.weeklyPlan.isEmpty && (viewModel.isLoadingWeekly || viewModel.weeklyErrorMessage != nil) {
                        if let error = viewModel.weeklyErrorMessage {
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.title)
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                
                                Button("Thử lại") {
                                    viewModel.generateWeekPlan(targetCalories: targetCalories)
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding()
                        } else {
                            // ⚡ Stable Skeleton rows while loading
                            ForEach(0..<7, id: \.self) { _ in
                                SkeletonWeeklyRow()
                            }
                        }
                    } else if viewModel.weeklyPlan.isEmpty {
                        // Empty state
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("Chưa có kế hoạch tuần")
                                .font(.headline)
                            Button("Tạo kế hoạch") {
                                viewModel.generateWeekPlan(targetCalories: targetCalories)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.top, 100)
                    } else {
                        // Smart Fill Summary
                        if !viewModel.datesToGenerate.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("LiiO sẽ lấp đầy 7 ngày tiếp theo chưa có kế hoạch:")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.purple)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(viewModel.datesToGenerate, id: \.self) { date in
                                            Text(formatShortDate(date))
                                                .font(.system(size: 10, weight: .bold))
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.purple.opacity(0.1))
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color.purple.opacity(0.05))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }

                        // 7 day rows
                        ForEach(viewModel.weeklyPlan) { dayPlan in
                            WeeklyDayRow(dayPlan: dayPlan)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedDay = dayPlan
                                }
                        }
                        
                        // Confirm Button (Phase 26)
                        Button {
                            viewModel.confirmWeeklyPlan(targetCalories: targetCalories)
                            dismiss()
                        } label: {
                            Text("Chốt kế hoạch tuần")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Lên kế hoạch tuần")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 12) {
                        Button {
                            viewModel.generateWeekPlan(targetCalories: targetCalories)
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.subheadline)
                        }
                        
                        if viewModel.weekOffset != 0 {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    viewModel.weekOffset = 0
                                    viewModel.generateWeekPlan(targetCalories: targetCalories)
                                }
                            } label: {
                                Text("Hôm nay")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.green.opacity(0.5), lineWidth: 1.2)
                                    )
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") { dismiss() }
                }
            }
            .safeAreaInset(edge: .top) {
                // ⚡ Stable Header for AI progress
                VStack(spacing: 0) {
                    if viewModel.isLoadingWeekly {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                let weeklyActivities = AIActivityCenter.shared.activities.filter { 
                                    ($0.featureSource.contains("Thứ") || $0.featureSource.contains("Chủ Nhật") || $0.featureSource.contains("Gom")) && 
                                    !$0.isFinished
                                }
                                
                                ForEach(weeklyActivities) { activity in
                                    HStack(spacing: 4) {
                                        ProgressView().scaleEffect(0.6)
                                        Text(activity.featureSource)
                                            .font(.system(size: 10, weight: .bold))
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.purple.opacity(0.1))
                                    .clipShape(Capsule())
                                }
                                
                                if weeklyActivities.isEmpty {
                                    Text("Đang phân tích...")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.purple)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(height: 34)
                    }
                }
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground).opacity(0.9))
                .overlay(Divider(), alignment: .bottom)
            }
            .sheet(item: $selectedDay) { dayPlan in
                WeeklyDayDetailView(dayPlan: dayPlan, targetCalories: targetCalories, viewModel: viewModel)
            }
        }
        .task {
            if viewModel.weeklyPlan.isEmpty {
                viewModel.generateWeekPlan(targetCalories: targetCalories)
            }
        }
    }
    
    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        return formatter.string(from: date)
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
    let viewModel: MealPlanViewModel // ⚡ Added reference
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
                    
                    // Cards per meal type (Phase 26: use TimelineItem pattern)
                    ForEach(dayPlan.timelineItems) { item in
                        MealPlanCard(
                            item: item,
                            pendingLinks: [], // No links in weekly preview
                            isViewOnly: false, // Allow swap/delete in preview
                            onMarkEaten: { _ in }, // No logging in preview
                            onSkip: { _ in },
                            onLink: { _, _ in },
                            onSwap: { food in
                                Task { await viewModel.swapWeeklyMeal(item: food, day: dayPlan.day) }
                            },
                            onDelete: { food in
                                viewModel.removeFoodFromWeeklyPlan(id: food.id, day: dayPlan.day)
                            },
                            onToggleLock: { _ in },
                            onAddFood: {}
                        )
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
struct SkeletonWeeklyRow: View {
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
                .frame(width: 80, height: 24)
            Spacer()
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
                .frame(width: 60, height: 20)
        }
        .padding()
        .frame(height: 80)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.top, 8)
        .opacity(0.6)
    }
}
