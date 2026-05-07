import Foundation

enum AIPersonalityTone: String, Codable, CaseIterable {
    case friendly = "🌿 Thân thiện & Động viên"
    case expert = "👨‍⚕️ Chuyên gia Nghiêm túc"
    case disciplined = "🔥 Kỷ luật cao"
    case chill = "🌈 Chill & Thoải mái"
    case humorous = "😄 Vui vẻ & Hài hước"
    
    var promptInstruction: String {
        switch self {
        case .friendly: return "Sử dụng giọng điệu nhẹ nhàng, tích cực, khích lệ và không tạo áp lực."
        case .expert: return "Sử dụng giọng điệu logic, chuyên môn chuẩn dinh dưỡng, ít dùng emoji."
        case .disciplined: return "Sử dụng giọng điệu thúc đẩy mạnh mẽ, tập trung vào mục tiêu và kỷ luật cao."
        case .chill: return "Sử dụng giọng điệu thoải mái, ít áp lực, cân bằng cuộc sống và anti-guilt."
        case .humorous: return "Sử dụng giọng điệu dí dỏm, hài hước nhẹ nhàng, nhiều cảm xúc."
        }
    }
}
