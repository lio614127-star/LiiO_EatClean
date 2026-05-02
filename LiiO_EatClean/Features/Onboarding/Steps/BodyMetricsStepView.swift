import SwiftUI

struct BodyMetricsStepView: View {
    @Binding var height: String
    @Binding var weight: String
    @FocusState private var focusedField: Field?
    
    enum Field { case height, weight }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Số đo cơ thể")
                .font(.title2.bold())
            
            // Height
            VStack(alignment: .leading, spacing: 6) {
                Text("Chiều cao (cm)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                HStack {
                    TextField("165", text: $height)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .height)
                    
                    Stepper("", value: Binding(
                        get: { Double(height) ?? 165 },
                        set: { height = String(Int($0)) }
                    ), in: 100...250)
                    .labelsHidden()
                }
            }
            
            // Weight
            VStack(alignment: .leading, spacing: 6) {
                Text("Cân nặng (kg)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                HStack {
                    TextField("65", text: $weight)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .weight)
                    
                    Stepper("", value: Binding(
                        get: { Double(weight) ?? 65 },
                        set: { weight = String(format: "%.1f", $0) }
                    ), in: 30...300, step: 0.5)
                    .labelsHidden()
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .onAppear {
            focusedField = .height
        }
    }
}

#Preview {
    BodyMetricsStepView(height: .constant("165"), weight: .constant("65"))
}
