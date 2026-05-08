import SwiftUI

struct MealPlanSheet: View {
    @Bindable var viewModel: MealPlanViewModel
    @Binding var isPresented: Bool
    let targetCalories: Double
    
    @State private var showConfirmDialog = false
    @State private var showWeeklyPlan = false
    @State private var showOfflineToast = false
    private var isOffline: Bool { !NetworkMonitor.shared.isConnected }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header summary
                    if !viewModel.planItems.isEmpty {
                        VStack(spacing: 4) {
                            Text("Kế hoạch hôm nay")
                                .font(.title2.bold())
                            Text("Tổng: \(Int(viewModel.totalPlanCalories)) / \(Int(targetCalories)) kcal")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    }
                    
                    // Meal cards
                    if viewModel.isLoading {
                        VStack(spacing: 12) {
                            // Real-time model transparency rows for parallel tasks
                            let mealOrder = ["Bữa sáng", "Bữa trưa", "Bữa tối", "Ăn vặt"]
                            let planningActivities = AIActivityCenter.shared.activities.filter { 
                                ($0.featureSource.contains("Kế hoạch:") || 
                                 $0.featureSource.contains("Bữa") || 
                                 $0.featureSource.contains("Master")) && 
                                $0.status != .completed 
                            }.sorted { a1, a2 in
                                let o1 = mealOrder.firstIndex(where: { a1.featureSource.contains($0) }) ?? 99
                                let o2 = mealOrder.firstIndex(where: { a2.featureSource.contains($0) }) ?? 99
                                return o1 < o2
                            }
                            
                            ForEach(planningActivities) { activity in
                                ActivityRow(activity: activity)
                                    .frame(maxWidth: 320)
                                    .transition(.opacity.combined(with: .scale))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                        .padding(.horizontal)
                        .animation(.spring(), value: AIActivityCenter.shared.activities)
                    } else if let error = viewModel.errorMessage {
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
                        // 4 meal cards (D-04: Cards xếp dọc)
                        ForEach(MealPlanViewModel.mealTypes, id: \.self) { mealType in
                            let foods = viewModel.items(for: mealType)
                            if !foods.isEmpty {
                                MealPlanCard(
                                    mealType: mealType,
                                    foods: foods,
                                    isLogged: viewModel.loggedMealTypes.contains(mealType),
                                    onLog: {
                                        Task { await viewModel.logMeal(type: mealType) }
                                    }
                                )
                            }
                        }
                        
                        // "Áp dụng tất cả" button (D-06)
                        if !viewModel.planItems.isEmpty && !viewModel.allMealsLogged {
                            Button {
                                showConfirmDialog = true
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Áp dụng toàn bộ kế hoạch")
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
                        
                        // Weekly plan button
                        if !viewModel.planItems.isEmpty {
                            Button {
                                if isOffline {
                                    showOfflineToast = true
                                    return
                                }
                                showWeeklyPlan = true
                            } label: {
                                HStack {
                                    Image(systemName: "calendar")
                                    Text("Lên kế hoạch tuần")
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.green)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                            .opacity(isOffline ? 0.45 : 1.0)
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
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if !viewModel.planItems.isEmpty {
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
                        .opacity(isOffline ? 0.45 : 1.0)
                    }
                }
            }
            // Confirm dialog for bulk log (D-06)
            .alert(
                "Áp dụng toàn bộ kế hoạch?",
                isPresented: $showConfirmDialog
            ) {
                Button("Xác nhận") {
                    Task {
                        await viewModel.logAllMeals(targetCalories: targetCalories)
                    }
                }
                Button("Huỷ", role: .cancel) {}
            } message: {
                Text("Hành động này sẽ lưu toàn bộ 4 bữa ăn của kế hoạch hôm nay vào lịch sử của bạn.")
            }
            .sheet(isPresented: $showWeeklyPlan) {
                WeeklyPlanView(viewModel: viewModel, targetCalories: targetCalories)
            }
        }
        .task {
            if viewModel.planItems.isEmpty {
                await viewModel.generateDayPlan(targetCalories: targetCalories)
            }
        }
        // Auto-dismiss when all meals logged (D-08: ~1s delay + haptic)
        .onChange(of: viewModel.allMealsLogged) { _, allLogged in
            if allLogged {
                HapticManager.interaction()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    isPresented = false
                }
            }
        }
    }
}
