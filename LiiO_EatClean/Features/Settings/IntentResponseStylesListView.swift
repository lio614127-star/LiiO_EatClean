import SwiftUI

struct IntentResponseStylesListView: View {
    @Environment(AssistantVoiceSettings.self) var settings
    
    let intents = [
        (key: "meal_logging", title: "Ghi chép bữa ăn"),
        (key: "plan_question", title: "Hỏi về kế hoạch"),
        (key: "cooking_advice", title: "Tư vấn nấu ăn"),
        (key: "health_question", title: "Câu hỏi sức khỏe"),
        (key: "progress_question", title: "Hỏi về tiến độ"),
        (key: "rebalance_request", title: "Yêu cầu cân đối lại"),
        (key: "general_chat", title: "Trò chuyện chung")
    ]
    
    var body: some View {
        List {
            Section {
                ForEach(intents, id: \.key) { intent in
                    NavigationLink(destination: IntentResponseStyleView(intentKey: intent.key, intentTitle: intent.title)) {
                        HStack {
                            Text(intent.title)
                            Spacer()
                            let style = settings.intentResponseStyles[intent.key] ?? "default"
                            Text(style == "default" ? "Mặc định" : style)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } header: {
                Text("Tùy chỉnh theo loại câu hỏi")
            } footer: {
                Text("Chọn cách AI phản hồi cụ thể cho từng loại nội dung bạn hỏi.")
            }
        }
        .navigationTitle("Phản hồi theo tình huống")
    }
}
