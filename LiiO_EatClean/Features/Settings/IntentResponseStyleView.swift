import SwiftUI

struct IntentResponseStyleView: View {
    let intentKey: String
    let intentTitle: String
    @Environment(AssistantVoiceSettings.self) var settings
    @State private var showingTemplateEditor = false
    @State private var customTemplate = ""
    
    var options: [(id: String, title: String, description: String)] {
        switch intentKey {
        case "meal_logging":
            return [
                ("default", "Mặc định", "Theo phong cách chung của AI."),
                ("confirm_short", "Xác nhận ngắn", "Đã ghi nhận món ăn cho bạn."),
                ("confirm_cal", "Xác nhận + Calo", "Đã ghi nhận, tổng cộng khoảng {calories} kcal."),
                ("confirm_macro", "Xác nhận + Macro", "Đã ghi nhận. Món này có {protein}g đạm và {carbs}g tinh bột."),
            ]
        case "plan_question":
            return [
                ("default", "Mặc định", "Gợi ý món ăn dựa trên calo còn lại."),
                ("quick_suggest", "Gợi ý nhanh", "Bạn nên ăn {foodName}, khoảng {calories} kcal."),
                ("healthy_focus", "Ưu tiên sức khỏe", "Món {foodName} rất tốt cho {condition} của bạn."),
            ]
        case "cooking_advice":
            return [
                ("default", "Mặc định", "Hướng dẫn nấu ăn cơ bản."),
                ("step_by_step", "Từng bước một", "Đầu tiên bạn cần... Sau đó..."),
                ("quick_tip", "Mẹo nhanh", "Bạn nên chú ý {tip} khi làm món này."),
            ]
        default:
            return [
                ("default", "Mặc định", "Theo phong cách chung của AI."),
                ("concise", "Ngắn gọn", "Trả lời súc tích nhất có thể."),
                ("detailed", "Chi tiết", "Phân tích kỹ lưỡng hơn."),
            ]
        }
    }
    
    var body: some View {
        List {
            Section("Chọn phong cách") {
                ForEach(options, id: \.id) { option in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(option.title)
                                .font(.body)
                            Text(option.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if (settings.intentResponseStyles[intentKey] ?? "default") == option.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        settings.intentResponseStyles[intentKey] = option.id
                    }
                }
            }
            
            Section {
                Button("Tạo template riêng (Sắp ra mắt)") {
                    showingTemplateEditor = true
                }
                .disabled(true)
            } footer: {
                Text("Tính năng cho phép bạn tự định nghĩa câu trả lời của AI bằng các biến như {foodName}, {calories}...")
            }
        }
        .navigationTitle(intentTitle)
    }
}
