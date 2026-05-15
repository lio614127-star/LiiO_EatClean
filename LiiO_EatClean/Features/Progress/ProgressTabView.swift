import SwiftUI

struct ProgressTabView: View {
    @State private var viewModel = ProgressViewModel()
    @State private var isShowingLogWeight = false
    @State private var isShowingCustomPicker = false
    @State private var isShowingReflection = false
    @State private var weightInput = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header Section
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(rangeHeader)
                                    .font(.system(size: 34, weight: .semibold))
                                
                                Text(rangeSubheader)
                                    .font(.system(size: 18, weight: .regular))
                                    .foregroundColor(.secondary.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            if viewModel.periodOffset != 0 {
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        viewModel.periodOffset = 0
                                        Task { await viewModel.loadData() }
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
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        
                        // Custom Segmented Control
                        HStack(spacing: 0) {
                            ForEach(ProgressTab.allCases, id: \.self) { tab in
                                let isSelected = viewModel.selectedTab == tab
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        viewModel.selectedTab = tab
                                    }
                                }) {
                                    Text(tab.rawValue)
                                        .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                                        .foregroundColor(isSelected ? .black : .secondary)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .background(
                                            ZStack {
                                                if isSelected {
                                                    RoundedRectangle(cornerRadius: 22)
                                                        .fill(Color.white)
                                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                                }
                                            }
                                        )
                                }
                            }
                        }
                        .padding(4)
                        .frame(height: 44)
                        .background(Color(.systemGray6).opacity(0.5))
                        .cornerRadius(22)
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        if viewModel.selectedTab != .adherence {
                            // Custom Time Range Selector (MOVED UP)
                            HStack(spacing: 0) {
                                ForEach(TimeRange.allCases, id: \.self) { range in
                                    let isSelected = viewModel.selectedTimeRange == range
                                    Button(action: {
                                        if range == .custom {
                                            isShowingCustomPicker = true
                                        } else {
                                            withAnimation {
                                                viewModel.selectedTimeRange = range
                                                viewModel.periodOffset = 0
                                                Task { await viewModel.loadData() }
                                            }
                                        }
                                    }) {
                                        Text(range == .custom ? customRangeLabel : range.rawValue)
                                            .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                            .foregroundColor(isSelected ? .primary : .secondary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(isSelected ? Color(.systemBackground) : Color.clear)
                                            .cornerRadius(8)
                                            .shadow(color: isSelected ? .black.opacity(0.1) : .clear, radius: 2)
                                    }
                                    .padding(2)
                                }
                            }
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .padding(.horizontal, 24)
                            .padding(.top, 12) // ⚡ Added spacing between selectors
                            .padding(.bottom, 24)
                        }
                        
                        ZStack {
                            let range = viewModel.currentDateRange
                            if viewModel.selectedTab == .calories {
                                CalorieChartView(
                                    data: viewModel.calorieData,
                                    weeklyData: viewModel.weeklyData,
                                    monthlyData: viewModel.monthlyData,
                                    dailyTarget: viewModel.dailyTarget,
                                    timeRange: viewModel.selectedTimeRange,
                                    startDate: range.start,
                                    endDate: range.end
                                )
                                .animation(.easeInOut(duration: 0.35), value: viewModel.selectedTimeRange)
                            } else if viewModel.selectedTab == .weight {
                                WeightChartView(
                                    data: viewModel.weightData,
                                    weeklyData: viewModel.weeklyData,
                                    monthlyData: viewModel.monthlyData,
                                    timeRange: viewModel.selectedTimeRange,
                                    startDate: range.start,
                                    endDate: range.end
                                )
                                .animation(.easeInOut(duration: 0.35), value: viewModel.selectedTimeRange)
                            } else if viewModel.selectedTab == .adherence {
                                CalendarHeatmapView()
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                            
                            if viewModel.isLoading {
                                SwiftUI.ProgressView()
                                    .padding()
                                    .background(Color(.systemBackground).opacity(0.8))
                                    .cornerRadius(8)
                            }
                        }
                        .frame(minHeight: 250)
                        .simultaneousGesture(
                            DragGesture()
                                .onEnded { value in
                                    // ⏱️ Check duration to separate quick flicks from long selection drags
                                    // value.startLocationTime is not directly available, but we can use 
                                    // predictedEndTranslation vs translation as a velocity proxy.
                                    // Additionally, if the user moved very little horizontally initially but then dragged,
                                    // it shouldn't be a swipe.
                                    
                                    let horizontalSwipe = value.translation.width
                                    let predictedHorizontalSwipe = value.predictedEndTranslation.width
                                    
                                    // A flick is characterized by high velocity (predicted >> actual)
                                    // A selection drag is usually slower and more deliberate.
                                    let isFlick = abs(predictedHorizontalSwipe) > abs(horizontalSwipe) + 50
                                    
                                    // If it's a slow drag (not a flick) and the user has been holding/moving slowly, 
                                    // we ignore the navigation to favor chart selection.
                                    if isFlick && abs(value.translation.width) > abs(value.translation.height) {
                                        if horizontalSwipe > 50 {
                                            // Swipe right (previous)
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                viewModel.periodOffset -= 1
                                                Task { await viewModel.loadData() }
                                            }
                                        } else if horizontalSwipe < -50 {
                                            // Swipe left (next)
                                            if viewModel.periodOffset < 0 {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    viewModel.periodOffset += 1
                                                    Task { await viewModel.loadData() }
                                                }
                                            }
                                        }
                                    }
                                }
                        )
                        
                        // Weekly Remainder Card
                        if viewModel.selectedTimeRange == .week && viewModel.periodOffset == 0 {
                            weeklyRemainderCard
                        }
                        
                        // Macro Dashboard (only visible on Calories tab)
                        if viewModel.selectedTab == .calories,
                           let aggregate = viewModel.macroAggregate,
                           let target = viewModel.macroTarget {
                            MacroDashboardView(
                                aggregate: aggregate,
                                target: target,
                                timeRange: viewModel.selectedTimeRange,
                                trend: viewModel.macroTrend
                            )
                            .padding(.horizontal)
                            .padding(.top, 16) // ⚡ Added spacing
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .animation(.easeInOut(duration: 0.3), value: viewModel.selectedTab)
                            
                            MacroInsightsView(
                                aggregate: aggregate,
                                target: target,
                                trend: viewModel.macroTrend,
                                timeRange: viewModel.selectedTimeRange
                            )
                            .padding(.horizontal)
                            .padding(.top, 20) // ⚡ Increased from 16
                        }
                        
                        
                        if viewModel.selectedTimeRange == .week && viewModel.periodOffset == 0 {
                            Button {
                                isShowingReflection = true
                            } label: {
                                HStack {
                                    Image(systemName: "checklist")
                                    Text("Đánh giá tuần này")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                }
                                .font(.headline)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            .padding(.top, 20) // ⚡ Increased from 16
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical)
                }
                .refreshable {
                    await viewModel.loadData()
                }
                
                // Floating Action Button (Only on Weight tab, raised slightly higher)
                if viewModel.selectedTab == .weight {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                // Try to pre-fill with latest weight
                                if let last = viewModel.weightData.last {
                                    weightInput = String(format: "%.1f", last.weight)
                                }
                                isShowingLogWeight = true
                            }) {
                                Image(systemName: "plus")
                                    .font(.title.bold())
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 60)
                                    .background(Color.green)
                                    .clipShape(Circle())
                                    .shadow(color: Color.green.opacity(0.4), radius: 8, x: 0, y: 4)
                            }
                            .padding(.trailing, 24)
                            .padding(.bottom, 64)
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isShowingLogWeight) {
                logWeightSheet
                    .presentationDetents([.height(250)])
            }
            .sheet(isPresented: $isShowingCustomPicker) {
                CustomDateRangePickerSheet(
                    startDate: $viewModel.customStartDate,
                    endDate: $viewModel.customEndDate,
                    selectedRange: $viewModel.selectedTimeRange,
                    onApply: {
                        viewModel.periodOffset = 0
                        Task { await viewModel.loadData() }
                    }
                )
                .presentationDetents([.height(560)])
            }
            .sheet(isPresented: $isShowingReflection) {
                WeeklyReflectionView(
                    adherenceScore: viewModel.weeklyAdherenceScore,
                    nutritionScore: 0.92 // TODO: Connect to nutrition engine
                )
            }
        }
        .onAppear {
            Task {
                await viewModel.loadData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name.appSetProgressRange)) { notification in
            if let rawStr = notification.object as? String,
               let range = TimeRange(rawValue: rawStr) {
                print("[AppAction Router] ProgressTabView updating time range to \(rawStr)")
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    viewModel.selectedTimeRange = range
                    viewModel.periodOffset = 0
                }
                Task { await viewModel.loadData() }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name.appSetProgressMetric)) { notification in
            if let rawStr = notification.object as? String,
               let tab = ProgressTab(rawValue: rawStr) {
                print("[AppAction Router] ProgressTabView updating active tab metric to \(rawStr)")
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    viewModel.selectedTab = tab
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name.appWeightDidChange)) { _ in
            print("[AppAction Router] ProgressTabView received weight delta event. Refreshing dashboard.")
            Task { await viewModel.loadData() }
        }
    }
    
    private var rangeHeader: String {
        let range = viewModel.currentDateRange
        let calendar = Calendar.current
        
        let startMonth = calendar.component(.month, from: range.start)
        let endMonth = calendar.component(.month, from: calendar.date(byAdding: .day, value: -1, to: range.end)!)
        let startYear = calendar.component(.year, from: range.start)
        let endYear = calendar.component(.year, from: calendar.date(byAdding: .day, value: -1, to: range.end)!)
        
        switch viewModel.selectedTimeRange {
        case .week:
            let startDay = calendar.component(.day, from: range.start)
            let endDay = calendar.component(.day, from: calendar.date(byAdding: .day, value: -1, to: range.end)!)
            
            if startMonth == endMonth {
                return "\(startDay)-\(endDay) Th\(startMonth)"
            } else {
                return "\(startDay) Th\(startMonth) - \(endDay) Th\(endMonth)"
            }
            
        case .month:
            return "Tháng \(startMonth), \(startYear)"
            
        case .quarter:
            if startYear == endYear {
                return "Th\(startMonth) - Th\(endMonth) \(startYear)"
            } else {
                return "Th\(startMonth)/\(startYear % 100) - Th\(endMonth)/\(endYear % 100)"
            }
            
        case .custom:
            let startDay = calendar.component(.day, from: range.start)
            let endDay = calendar.component(.day, from: calendar.date(byAdding: .day, value: -1, to: range.end)!)
            return "\(startDay)/\(startMonth) - \(endDay)/\(endMonth)"
        }
    }
    
    private var rangeSubheader: String {
        let range = viewModel.currentDateRange
        let days = (Calendar.current.dateComponents([.day], from: range.start, to: range.end).day ?? 0) + 1
        let aggregation = days <= 31 ? "Từng ngày" : (days <= 120 ? "Trung bình tuần" : "Trung bình tháng")
        return "\(days) ngày • \(aggregation)"
    }
    
    private var customRangeLabel: String {
        if viewModel.selectedTimeRange == .custom {
            let calendar = Calendar.current
            let startDay = calendar.component(.day, from: viewModel.customStartDate)
            let startMonth = calendar.component(.month, from: viewModel.customStartDate)
            let endDay = calendar.component(.day, from: viewModel.customEndDate)
            let endMonth = calendar.component(.month, from: viewModel.customEndDate)
            return String(format: "%02d/%02d-%02d/%02d", startDay, startMonth, endDay, endMonth)
        } else {
            return "Tùy chọn"
        }
    }
    
    private var logWeightSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Nhập cân nặng hôm nay")
                    .font(.headline)
                
                HStack {
                    TextField("VD: 65.5", text: $weightInput)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 40, weight: .bold))
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                    
                    Text("kg")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 32)
                
                Button(action: {
                    if let weight = Double(weightInput.replacingOccurrences(of: ",", with: ".")) {
                        Task {
                            await viewModel.saveWeight(weight)
                            isShowingLogWeight = false
                        }
                    }
                }) {
                    Text("Lưu")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
            .padding(.top, 24)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") {
                        isShowingLogWeight = false
                    }
                }
            }
        }
    }
    
    private var weeklyRemainderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ngân sách tuần còn lại")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(Int(viewModel.weeklyRemainingCalories)) kcal")
                        .font(.title2.bold())
                }
                Spacer()
                CircularProgressView(progress: viewModel.weeklyAdherenceScore, color: .blue)
                    .frame(width: 44, height: 44)
            }
            
            Text("Bạn đang có tính tuân thủ \(Int(viewModel.weeklyAdherenceScore * 100))% trong tuần này.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal, 24)
        .padding(.top, 16) // ⚡ Increased from 8
    }
}

struct CircularProgressView: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.1), lineWidth: 4)
            Circle()
                .trim(from: 0, to: max(0.01, progress))
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

#Preview {
    ProgressTabView()
}
