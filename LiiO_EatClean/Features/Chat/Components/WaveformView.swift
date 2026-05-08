import SwiftUI

struct WaveformView: View {
    let audioLevel: Float
    
    private let barCount = 30
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                let normalizedIndex = Float(index) / Float(barCount)
                // Create wave pattern from center outward
                let distanceFromCenter = abs(normalizedIndex - 0.5) * 2
                let baseHeight: CGFloat = 4
                let variation = CGFloat(audioLevel) * (1 - CGFloat(distanceFromCenter) * 0.6)
                let height = max(baseHeight, baseHeight + variation * 32)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.green.opacity(0.6 + Double(audioLevel) * 0.4))
                    .frame(width: 3, height: height)
                    .animation(.easeOut(duration: 0.1), value: audioLevel)
            }
        }
    }
}
