import SwiftUI

struct MealsView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Meals")
                    .font(.title)
                Text("Get started by adding your first entry")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Meals")
        }
    }
}

#Preview {
    MealsView()
}
