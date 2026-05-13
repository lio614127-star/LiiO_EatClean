import SwiftUI

struct CalendarHeatmapView: View {
    @State private var viewModel = CalendarHeatmapViewModel()
    @State private var selectedDate: Date? = nil
    @State private var showDetail = false
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    let weekDays = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]
    
    var body: some View {
        VStack(spacing: 20) {
            // Month Navigation
            HStack {
                Text(viewModel.currentMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                HStack(spacing: 20) {
                    Button {
                        Task { await viewModel.changeMonth(by: -1) }
                    } label: {
                        Image(systemName: "chevron.left")
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Button {
                        Task { await viewModel.changeMonth(by: 1) }
                    } label: {
                        Image(systemName: "chevron.right")
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal)
            
            // Weekday Headers
            HStack {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 4)
            
            // Grid
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(viewModel.daysInMonth().enumerated()), id: \.offset) { _, date in
                    if let date = date {
                        HeatmapCell(
                            date: date,
                            score: viewModel.adherenceSnapshots[Calendar.current.startOfDay(for: date)]?.adherenceScore,
                            isToday: Calendar.current.isDateInToday(date)
                        )
                        .onTapGesture {
                            selectedDate = date
                            showDetail = true
                        }
                    } else {
                        HeatmapCell(date: nil, score: nil, isToday: false)
                    }
                }
            }
            .padding(.horizontal, 4)
            
            // Legend
            HStack(spacing: 12) {
                Text("Kém")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 4) {
                    ForEach([Color.red, Color.orange, Color.yellow, Color.green, Color.mint], id: \.self) { color in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color)
                            .frame(width: 12, height: 12)
                    }
                }
                
                Text("Tốt")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 10)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(16)
        .padding()
        .task {
            await viewModel.loadMonthData()
        }
        .sheet(isPresented: $showDetail) {
            if let date = selectedDate {
                DailyAdherenceDetailSheet(
                    date: date,
                    snapshot: viewModel.adherenceSnapshots[Calendar.current.startOfDay(for: date)]
                )
                .presentationDetents([.medium, .large])
            }
        }
    }
}
