import SwiftUI

struct HeatmapCell: View {
    let date: Date?
    let score: Double?
    let isToday: Bool
    
    var body: some View {
        ZStack {
            if let _ = date {
                RoundedRectangle(cornerRadius: 4)
                    .fill(fillColor)
                    .aspectRatio(1, contentMode: .fill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(isToday ? Color.primary : Color.clear, lineWidth: 2)
                    )
            } else {
                Color.clear
                    .aspectRatio(1, contentMode: .fill)
            }
        }
    }
    
    private var fillColor: Color {
        guard let score = score else { return Color.gray.opacity(0.15) }
        if score <= 0 { return Color.gray.opacity(0.15) }
        
        switch score {
        case 90...100: return .mint
        case 75..<90: return .green
        case 60..<75: return .yellow
        case 40..<60: return .orange
        case 0.1..<40: return .red
        default: return Color.gray.opacity(0.15)
        }
    }
}
