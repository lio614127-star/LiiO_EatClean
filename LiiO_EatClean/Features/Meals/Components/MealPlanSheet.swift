import SwiftUI

struct MealPlanSheet: View {
    @Bindable var viewModel: MealPlanViewModel
    @Binding var isPresented: Bool
    let targetCalories: Double
    
    @State private var showConfirmDialog = false
    @State private var showWeeklyPlan = false
    
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
                        VStack(spacing: 16) {
                            ProgressView("Đang tạo kế hoạch...")
                                .padding(40)
                            Text("AI đang phân tích dinh dưỡng và sở thích của bạn")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
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
                        }
                    }
                }
                .padding()
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
                            Task { await viewModel.generateDayPlan(targetCalories: targetCalories) }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.subheadline)
                        }
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
