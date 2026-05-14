import SwiftUI

struct MealPlanSheet: View {
    @Bindable var viewModel: MealPlanViewModel
    @Binding var isPresented: Bool
    let targetCalories: Double
    
    @State private var showConfirmDialog = false
    @State private var showWeeklyPlan = false
    @State private var showOfflineToast = false
    @State private var showFoodSearch = false
    @State private var selectedMealType: String = "Bữa sáng"
    private var isOffline: Bool { !NetworkMonitor.shared.isConnected }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Date Navigation (Phase 25)
                    HorizontalDateStrip(selectedDate: $viewModel.selectedDate)
                        .onChange(of: viewModel.selectedDate) { _, newDate in
                            Task {
                                await viewModel.loadExistingPlan(for: newDate)
                            }
                        }
                        .padding(.bottom, 8)
                    
                    Divider()
                    
                    // Header summary
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(Calendar.current.isDateInToday(viewModel.selectedDate) ? "Kế hoạch hôm nay" : "Kế hoạch ngày")
                                .font(.title2.bold())
                            if !Calendar.current.isDateInToday(viewModel.selectedDate) {
                                Text(formatDate(viewModel.selectedDate))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if !Calendar.current.isDateInToday(viewModel.selectedDate) {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    viewModel.selectedDate = Date()
                                }
                            } label: {
                                Text("Hôm nay")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.green.opacity(0.5), lineWidth: 1.5)
                                    )
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    Text("Tổng: \(Int(viewModel.totalPlanCalories)) / \(Int(targetCalories)) kcal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                    
                    // Model Indicator (Local UX)
                    if viewModel.isLoading {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Gemini đang thiết kế thực đơn cho bạn...")
                                .font(.caption.bold())
                                .foregroundColor(.purple)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.purple.opacity(0.1))
                        .clipShape(Capsule())
                        .padding(.bottom, 4)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Meal cards with Unified Timeline
                    VStack(spacing: 16) {
                        if let record = viewModel.dailyRecord {
                            let isPastDate = Calendar.current.startOfDay(for: viewModel.selectedDate) < Calendar.current.startOfDay(for: Date())
                            
                            ForEach(record.timelineItems) { item in
                                MealPlanCard(
                                    item: item,
                                    pendingLinks: viewModel.pendingLinks,
                                    isViewOnly: isPastDate,
                                    onMarkEaten: { planned in
                                        Task { await viewModel.markPlannedMealAsEaten(plannedMeal: planned) }
                                    },
                                    onSkip: { planned in
                                        Task { await viewModel.skipPlannedMeal(plannedMeal: planned) }
                                    },
                                    onLink: { meal, plannedId in
                                        Task { await viewModel.linkMealToPlan(meal: meal, plannedMealId: plannedId) }
                                    },
                                    onSwap: { food in
                                        Task { await viewModel.swapMeal(item: food) }
                                    },
                                    onDelete: { food in
                                        viewModel.removeFoodFromPlan(id: food.id)
                                    },
                                    onToggleLock: { planned in
                                        Task { await viewModel.toggleLockMeal(id: planned.id, locked: !planned.isLocked) }
                                    },
                                    onAddFood: {
                                        selectedMealType = item.type
                                        showFoodSearch = true
                                    }
                                )
                                .id("journal-\(item.type)-\(item.actuals.count)-\(item.planned != nil)")
                            }
                        } else if viewModel.isLoading {
                            ForEach(MealPlanViewModel.mealTypes, id: \.self) { mealType in
                                SkeletonMealCard(mealType: mealType)
                            }
                        } else {
                            ContentUnavailableView(
                                "Chưa có kế hoạch",
                                systemImage: "calendar.badge.plus",
                                description: Text("Hãy để AI thiết kế thực đơn phù hợp cho bạn")
                            )
                            .padding(.top, 40)
                        }
                    }
                    // ⚡ Removed per-value animation that caused jittering during streaming
                    
                    if let error = viewModel.errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Thử lại") {
                                Task { await viewModel.generateDayPlan(targetCalories: targetCalories) }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        }
                        .padding(40)
                    } else {
                        // "Áp dụng tất cả" button (D-06)
                        if !viewModel.planItems.isEmpty && !viewModel.allMealsConfirmed {
                            Button {
                                showConfirmDialog = true
                            } label: {
                                HStack {
                                    Image(systemName: "lock.fill")
                                    Text("Chốt kế hoạch hôm nay")
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.green)
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 8)
                        }
                    }
                }
                .padding()
            }
            .overlay(alignment: .bottom) {
                if showOfflineToast {
                    Text("📡 Kế hoạch bữa ăn cần AI để phân tích dinh dưỡng")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.orange.opacity(0.9))
                        .cornerRadius(10)
                        .shadow(radius: 4)
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { showOfflineToast = false }
                            }
                        }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    let isPastDate = Calendar.current.startOfDay(for: viewModel.selectedDate) < Calendar.current.startOfDay(for: Date())
                    
                    if !viewModel.isLoading && !viewModel.planItems.isEmpty && !isPastDate {
                        Button {
                            if isOffline {
                                showOfflineToast = true
                                return
                            }
                            Task { await viewModel.generateDayPlan(targetCalories: targetCalories) }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.subheadline)
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") { isPresented = false }
                }
            }
            // Confirm dialog for bulk log (D-06)
            .alert(
                "Chốt kế hoạch hôm nay?",
                isPresented: $showConfirmDialog
            ) {
                Button("Xác nhận") {
                    Task {
                        await viewModel.confirmDailyPlan()
                    }
                }
                Button("Huỷ", role: .cancel) {}
            } message: {
                Text("Hành động này sẽ lưu thực đơn đã thiết kế cho hôm nay. Bạn có thể thay đổi hoặc ghi nhận thực tế sau.")
            }
            .sheet(isPresented: $showWeeklyPlan) {
                WeeklyPlanView(viewModel: viewModel, targetCalories: targetCalories)
            }
            .sheet(isPresented: $showFoodSearch) {
                NavigationStack {
                    FoodSearchView(onFoodSelected: { food in
                        Task {
                            await viewModel.logSingleFood(food, type: selectedMealType, date: viewModel.selectedDate)
                            showFoodSearch = false
                        }
                    })
                    .navigationTitle("Thêm vào \(selectedMealType)")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Hủy") { showFoodSearch = false }
                        }
                    }
                }
            }
        }
        .overlay {
            SiriStyleVoiceOverlayV4(target: .dailyPlanSheet)
        }
        .onAppear {
            VoiceOverlayRenderCoordinator.shared.activate(.dailyPlanSheet)
            Task {
                await viewModel.loadExistingPlan()
            }
        }
        .onDisappear {
            VoiceOverlayRenderCoordinator.shared.restoreContentViewIfNeeded(from: .dailyPlanSheet)
        }
        .task {
            // Check for existing plan for selected date
            if !(await viewModel.loadExistingPlan()) {
                // Only auto-generate if it's today and empty
                if Calendar.current.isDateInToday(viewModel.selectedDate) {
                    viewModel.generateDayPlan(targetCalories: targetCalories)
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        return formatter.string(from: date)
    }
}
