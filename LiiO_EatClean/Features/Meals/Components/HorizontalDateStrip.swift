import SwiftUI

struct HorizontalDateStrip: View {
    @Binding var selectedDate: Date
    @State private var showCalendarSheet = false
    
    // Generate dates: 7 days ago to 7 days in future
    private var dateRange: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var dates: [Date] = []
        for i in -7...7 {
            if let date = calendar.date(byAdding: .day, value: i, to: today) {
                dates.append(date)
            }
        }
        return dates
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter
    }()
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }()
    
    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                ScrollViewReader { proxy in
                    HStack(spacing: 12) {
                        ForEach(dateRange, id: \.self) { date in
                            DateCell(
                                date: date,
                                isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                                dateFormatter: dateFormatter,
                                dayFormatter: dayFormatter
                            )
                            .id(date)
                            .onTapGesture {
                                withAnimation {
                                    selectedDate = date
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .onAppear {
                        // Scroll to today or selected date on appear
                        proxy.scrollTo(Calendar.current.startOfDay(for: selectedDate), anchor: .center)
                    }
                    .onChange(of: selectedDate) { newDate in
                        withAnimation {
                            proxy.scrollTo(Calendar.current.startOfDay(for: newDate), anchor: .center)
                        }
                    }
                }
            }
            
            Divider()
                .frame(height: 30)
                .padding(.horizontal, 8)
            
            Button(action: {
                showCalendarSheet = true
            }) {
                Image(systemName: "calendar")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
                    .padding(.trailing, 16)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .sheet(isPresented: $showCalendarSheet) {
            NavigationView {
                VStack {
                    DatePicker(
                        "Chọn ngày",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .padding()
                    Spacer()
                }
                .navigationTitle("Lịch")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Xong") {
                            showCalendarSheet = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}

struct DateCell: View {
    let date: Date
    let isSelected: Bool
    let dateFormatter: DateFormatter
    let dayFormatter: DateFormatter
    
    var body: some View {
        VStack(spacing: 4) {
            Text(dayFormatter.string(from: date))
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .secondary)
            
            Text(dateFormatter.string(from: date))
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(isSelected ? .white : .primary)
        }
        .frame(width: 48, height: 56)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue : Color.clear) // Use app's primary color if available
        )
    }
}
