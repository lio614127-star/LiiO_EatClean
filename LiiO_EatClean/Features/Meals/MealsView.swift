import SwiftUI

struct MealSheetItem: Identifiable, Equatable {
    let id: String
}

struct MealsView: View {
    @State private var viewModel = MealsViewModel()
    @State private var activeAddMealType: MealSheetItem?
    @State private var activeDetailMealType: MealSheetItem?
    @State private var showMealPlanSheet = false
    @State private var showWeeklyPlanSheet = false
    @State private var mealPlanViewModel = MealPlanViewModel()
    @State private var showMemoryHub = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.meals.isEmpty {
                    ProgressView()
                } else {
                    List {
                        // Header
                        VStack(spacing: 8) {
                            Text(Calendar.current.isDateInToday(viewModel.selectedDate) ? "Hôm nay" : viewModel.selectedDate.formatted(.dateTime.day().month().year().locale(Locale(identifier: "vi_VN"))))
                                .font(.title2.bold())
                            
                            if !Calendar.current.isDateInToday(viewModel.selectedDate) {
                                Button {
                                    viewModel.selectedDate = Date()
                                    Task { await viewModel.loadData() }
                                } label: {
                                    Text("Quay lại Hôm nay")
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
                            
                            Text("Còn \(Int(viewModel.remainingCalories)) kcal")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        
                        // Dual Meal Plan Buttons (D-03: entry point split)
                        HStack(spacing: 12) {
                            Button {
                                guard !showMealPlanSheet else { return }
                                showMealPlanSheet = true
                            } label: {
                                HStack {
                                    Image(systemName: "sparkles")
                                    Text("Kế hoạch ngày")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.green)
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                            
                            Button {
                                showWeeklyPlanSheet = true
                            } label: {
                                HStack {
                                    Image(systemName: "calendar")
                                    Text("Kế hoạch tuần")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.green)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.green.opacity(0.12))
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        
                        
                        // Meal Sections
                        ForEach(["Bữa sáng", "Bữa trưa", "Bữa tối", "Ăn vặt"], id: \.self) { type in
                            mealSection(for: type)
                        }
                        
                    }
                    .listStyle(.insetGrouped)
                    .refreshable {
                        await viewModel.loadData()
                    }
                }
            }
            .navigationTitle("Meals")
            .navigationBarHidden(true)
            .sheet(item: $activeAddMealType, onDismiss: {
                Task { await viewModel.loadData() }
            }) { item in
                AddMealView(selectedMealType: item.id)
                    .id(item.id)
            }
            .sheet(item: $activeDetailMealType) { item in
                MealCategorySummarySheet(
                    mealType: item.id,
                    initialMeals: viewModel.meals(for: item.id),
                    onUpdate: {
                        Task { await viewModel.loadData() }
                    }
                )
                .id(item.id + "-\(viewModel.meals.flatMap { $0.mealFoods }.count)")
            }
            .fullScreenCover(isPresented: $showMealPlanSheet, onDismiss: {
                // ⚡ Delay refresh to avoid transition glitch with fullScreenCover
                Task {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    await viewModel.loadData(forceSilent: true)
                }
            }) {
                MealPlanSheet(
                    viewModel: mealPlanViewModel,
                    isPresented: $showMealPlanSheet,
                    targetCalories: viewModel.dailyTarget
                )
            }
            .fullScreenCover(isPresented: $showWeeklyPlanSheet, onDismiss: {
                // ⚡ Delay refresh to avoid transition glitch with fullScreenCover
                Task {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    await viewModel.loadData(forceSilent: true)
                }
            }) {
                WeeklyPlanView(
                    viewModel: mealPlanViewModel,
                    targetCalories: viewModel.dailyTarget
                )
            }
            .fullScreenCover(isPresented: $showMemoryHub) {
                MemoryHubView()
            }
            .sheet(item: Binding(
                get: { viewModel.rebalanceResult.map { IdentifiableResult(result: $0) } },
                set: { _ in viewModel.rebalanceResult = nil }
            )) { identifiable in
                RebalancePreviewSheet(
                    result: identifiable.result,
                    onConfirm: {
                        Task { await viewModel.confirmRebalance() }
                    },
                    onCancel: {
                        viewModel.rebalanceResult = nil
                    }
                )
            }
            .overlay {
                if viewModel.isRebalancing {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            Text("AI đang cân đối lại thực đơn...")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadData()
            }
        }
        .alert("Thông báo", isPresented: Binding(
            get: { viewModel.rebalanceError != nil },
            set: { if !$0 { viewModel.rebalanceError = nil } }
        )) {
            Button("Đồng ý", role: .cancel) { }
        } message: {
            if let error = viewModel.rebalanceError {
                Text(error)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("navigateToJournal"))) { notification in
            if let date = notification.object as? Date {
                viewModel.selectedDate = date
                Task { await viewModel.loadData() }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("openDailyPlanning"))) { _ in
            viewModel.selectedDate = Date()
            mealPlanViewModel.selectedDate = Date()
            // Guard against presenting twice
            if !showMealPlanSheet {
                showMealPlanSheet = true
            }
        }
    }
    
    @ViewBuilder
    private func mealSection(for type: String) -> some View {
        let meals = viewModel.meals(for: type)
        let foods = meals.flatMap { $0.mealFoods }
        let totalCals = foods.filter { $0.isEaten }.reduce(0) { $0 + $1.caloriesSnapshot }
        
        return Section {
            if foods.isEmpty {
                Text("Chưa có bữa ăn — nhấn + để thêm")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(foods) { food in
                    HStack(spacing: 12) {
                        Button(action: {
                            HapticManager.success()
                            Task {
                                await viewModel.toggleMealFoodStatus(id: food.id)
                            }
                        }) {
                            Image(systemName: food.isEaten ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(food.isEaten ? .green : .secondary)
                                .font(.system(size: 20))
                        }
                        .buttonStyle(.plain)
                        
                        NavigationLink {
                            MealDetailSheet(food: food.foodItem ?? FoodItemModel(id: UUID(), name: food.foodItem?.name ?? "Món ăn", calories: food.caloriesSnapshot, protein: food.proteinSnapshot, carbs: food.carbsSnapshot, fat: food.fatSnapshot, servingSize: 1))
                        } label: {
                            MealItemRow(mealFood: food)
                        }
                        .buttonStyle(.plain)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task { await viewModel.deleteMealFood(id: food.id) }
                        } label: {
                            Label("Xóa", systemImage: "trash")
                        }
                    }
                }
            }
        } header: {
            HStack {
                Label {
                    Text(type)
                        .font(.headline)
                        .foregroundColor(.primary)
                } icon: {
                    Image(systemName: iconForMealType(type))
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                Text("\(Int(totalCals)) kcal")
                    .font(.subheadline.bold())
                    .foregroundColor(totalCals > 0 ? .primary : .secondary)
                
                Button {
                    activeAddMealType = MealSheetItem(id: type)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
                .padding(.leading, 8)
            }
            .textCase(nil) // Prevent iOS from making header all-caps
        }
    }
    
    private func iconForMealType(_ type: String) -> String {
        switch type.lowercased() {
        case "bữa sáng": return "sunrise.fill"
        case "bữa trưa": return "sun.max.fill"
        case "bữa tối": return "moon.fill"
        case "ăn vặt": return "leaf.fill"
        default: return "fork.knife"
        }
    }
}

#Preview {
    MealsView()
}

// MARK: - Rebalance UI Components

struct RebalanceBannerView: View {
    let trigger: RebalanceTrigger
    let onAction: () -> Void
    
    var body: some View {
        Button(action: onAction) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(trigger.reason)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Text("Nhấn để AI tối ưu lại các bữa chưa ăn.")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(12)
            .shadow(color: .green.opacity(0.3), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
}

struct RebalancePreviewSheet: View {
    let result: RebalanceResult
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        // Summary Header
                        VStack(alignment: .leading, spacing: 10) {
                            Text(result.summary)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("Dựa trên những gì bạn đã ăn thực tế hôm nay.")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        
                        // Macro Comparison Cards
                        HStack(spacing: 16) {
                            MacroCompareCard(label: "Calo", old: result.oldExpectedTotals.calories, new: result.newExpectedTotals.calories, unit: "kcal")
                            MacroCompareCard(label: "Protein", old: result.oldExpectedTotals.protein, new: result.newExpectedTotals.protein, unit: "g")
                        }
                        .padding(.horizontal, 20)
                        
                        // Changes List
                        VStack(alignment: .leading, spacing: 18) {
                            Text("Thay đổi đề xuất")
                                .font(.system(size: 18, weight: .bold))
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 12) {
                                ForEach(result.changedMeals) { suggestion in
                                    DiffMealCard(suggestion: suggestion)
                                }
                            }
                        }
                        
                        // AI Insight Notice
                        if let warnings = result.warnings, !warnings.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Lưu ý từ AI", systemImage: "sparkles")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.orange)
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(warnings, id: \.self) { warning in
                                        Text("• \(warning)")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                            .lineLimit(3)
                                    }
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.orange.opacity(0.08))
                            .cornerRadius(16)
                            .padding(.horizontal, 20)
                        }
                        
                        // Spacing for sticky button
                        Color.clear.frame(height: 100)
                    }
                    .padding(.vertical, 20)
                }
                
                // Sticky Action Bar
                VStack(spacing: 0) {
                    Divider()
                    HStack(spacing: 16) {
                        Button(action: onCancel) {
                            Text("Hủy")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            HapticManager.success()
                            onConfirm()
                        }) {
                            Text("Áp dụng kế hoạch mới")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.green)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 34) // Safe area
                    .background(Color(.systemGroupedBackground).opacity(0.95))
                }
            }
            .navigationTitle("AI Điều chỉnh")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Đóng") { onCancel() }
                }
            }
        }
    }
}

struct MacroCompareCard: View {
    let label: String
    let old: Double
    let new: Double
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
                .tracking(0.5)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Int(old))")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .strikethrough()
                        .foregroundColor(.secondary.opacity(0.6))
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary.opacity(0.4))
                    
                    Text("\(Int(new))")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(new <= old ? .green : .orange)
                    
                    Text(unit)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                
                let delta = new - old
                if delta != 0 {
                    Text("\(delta > 0 ? "+" : "")\(Int(delta)) \(unit)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(delta < 0 ? .green : .orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background((delta < 0 ? Color.green : Color.orange).opacity(0.1))
                        .cornerRadius(4)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

struct DiffMealCard: View {
    let suggestion: ChangedMealSuggestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header: Meal Type & Badge
            HStack {
                Text(suggestion.mealType)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                changeTag
            }
            
            // Comparison Content
            HStack(alignment: .top, spacing: 12) {
                // Before
                VStack(alignment: .leading, spacing: 4) {
                    Text("TRƯỚC")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary.opacity(0.8))
                    
                    Text(suggestion.oldName)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    Text("\(Int(suggestion.oldCalories)) kcal")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.3))
                    .padding(.top, 20)
                
                // After
                VStack(alignment: .leading, spacing: 4) {
                    Text("SAU")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.green)
                    
                    Text(suggestion.newName ?? suggestion.oldName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text("\(Int(suggestion.newCalories)) kcal")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Reason
            if let reason = suggestion.reason {
                Text(reason)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(18)
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var changeTag: some View {
        let (text, color) = switch suggestion.changeType {
        case "portionAdjusted": ("Chỉnh khẩu phần", Color.blue)
        case "swapped": ("Đổi món", Color.purple)
        case "removed": ("Bỏ bữa", Color.red)
        case "added": ("Thêm bữa", Color.green)
        default: ("Cập nhật", Color.gray)
        }
        
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .cornerRadius(6)
    }
}
