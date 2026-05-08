import SwiftUI

struct AIActivityOverlay: View {
    @State private var activityCenter = AIActivityCenter.shared
    
    var body: some View {
        VStack(spacing: 8) {
            let visibleActivities = activityCenter.activities.filter { activity in
                // Hide activities that are marked as internal or are finished
                !activity.isInternal && !activity.isFinished
            }
            
            ForEach(visibleActivities) { activity in
                ActivityRow(activity: activity)
                    .frame(width: 280)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .animation(.spring(), value: activityCenter.activities)
    }
}
