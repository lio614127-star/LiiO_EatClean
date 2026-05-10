import SwiftUI

struct ProgressTabView: View {
    @State private var viewModel = ProgressViewModel()
    @State private var isShowingLogWeight = false
    @State private var weightInput = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Top Tab Picker
                        Picker("Thống kê", selection: $viewModel.selectedTab) {
                            ForEach(ProgressTab.allCases, id: \.self) { tab in
                                Text(tab.rawValue).tag(tab)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                        ZStack {
                            if viewModel.selectedTab == .calories {
                                CalorieChartView(
                                    data: viewModel.calorieData,
                                    weeklyData: viewModel.weeklyData,
                                    dailyTarget: viewModel.dailyTarget,
                                    timeRange: viewModel.selectedTimeRange
                                )
                                .padding(.horizontal)
                                .animation(.easeInOut(duration: 0.35), value: viewModel.selectedTimeRange)
                            } else {
                                WeightChartView(
                                    data: viewModel.weightData,
                                    weeklyData: viewModel.weeklyData,
                                    timeRange: viewModel.selectedTimeRange
                                )
                                .padding(.horizontal)
                                .animation(.easeInOut(duration: 0.35), value: viewModel.selectedTimeRange)
                            }
                            
                            if viewModel.isLoading {
                                SwiftUI.ProgressView()
                                    .padding()
                                    .background(Color(.systemBackground).opacity(0.8))
                                    .cornerRadius(8)
                            }
                        }
                        .frame(minHeight: 250)
                        
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
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .animation(.easeInOut(duration: 0.3), value: viewModel.selectedTab)
                            
                            MacroInsightsView(
                                aggregate: aggregate,
                                target: target,
                                trend: viewModel.macroTrend,
                                timeRange: viewModel.selectedTimeRange
                            )
                            .padding(.horizontal)
                        }
                        
                        // Time Range Toggle
                        Picker("Thời gian", selection: $viewModel.selectedTimeRange) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .onChange(of: viewModel.selectedTimeRange) { _ in
                            Task {
                                await viewModel.loadData()
                            }
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
            .navigationTitle("Tiến độ")
            .sheet(isPresented: $isShowingLogWeight) {
                logWeightSheet
                    .presentationDetents([.height(250)])
            }
        }
        .onAppear {
            Task {
                await viewModel.loadData()
            }
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
}

#Preview {
    ProgressTabView()
}
