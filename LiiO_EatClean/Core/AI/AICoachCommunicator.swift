import Foundation

struct CoachingInsight {
    let title: String
    let message: String
    let actionLabel: String?
    let severity: InterventionSeverity
    let proposal: GoalAdjustmentProposal?
}

class AICoachCommunicator {
    
    static func generateCoachingInsight(from proposal: GoalAdjustmentProposal) -> CoachingInsight {
        let title: String
        let message: String
        var actionLabel: String? = nil
        
        switch proposal.intervention.severity {
        case .soft, .medium:
            title = "Cập nhật mục tiêu chuyển hóa"
            message = proposal.intervention.reason + " Hệ thống đề xuất điều chỉnh mục tiêu calo xuống \(Int(proposal.newCalorieTarget)) kcal."
            actionLabel = "Áp dụng mục tiêu mới"
            
        case .recovery:
            title = "Phục hồi tính tuân thủ"
            message = proposal.intervention.reason
            actionLabel = "Bắt đầu tuần kỷ luật"
            
        case .maintenance:
            title = "Duy trì phong độ"
            message = proposal.intervention.reason
            
        default:
            title = "Thông tin từ AI Coach"
            message = proposal.intervention.reason
        }
        
        return CoachingInsight(
            title: title,
            message: message,
            actionLabel: actionLabel,
            severity: proposal.intervention.severity,
            proposal: proposal
        )
    }
    
    static func generateFallbackInsight() -> CoachingInsight {
        return CoachingInsight(
            title: "LiiO đang học hỏi",
            message: "Hãy tiếp tục log món ăn và cân nặng đều đặn để LiiO có đủ dữ liệu phân tích chuyển hóa của bạn.",
            actionLabel: nil,
            severity: .maintenance,
            proposal: nil
        )
    }
}
