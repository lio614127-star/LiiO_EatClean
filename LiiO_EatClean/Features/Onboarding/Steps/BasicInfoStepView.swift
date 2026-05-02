import SwiftUI

struct BasicInfoStepView: View {
    @Binding var name: String
    @Binding var age: String
    @Binding var gender: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Thông tin cơ bản")
                .font(.title2.bold())
            
            // Name (optional)
            VStack(alignment: .leading, spacing: 6) {
                Text("Tên (tuỳ chọn)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("Nhập tên của bạn", text: $name)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Age
            VStack(alignment: .leading, spacing: 6) {
                Text("Tuổi")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("25", text: $age)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
            }
            
            // Gender
            VStack(alignment: .leading, spacing: 6) {
                Text("Giới tính")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Picker("Giới tính", selection: $gender) {
                    Text("Nam").tag("male")
                    Text("Nữ").tag("female")
                }
                .pickerStyle(.segmented)
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
}

#Preview {
    BasicInfoStepView(name: .constant(""), age: .constant("25"), gender: .constant("male"))
}
