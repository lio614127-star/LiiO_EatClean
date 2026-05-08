import Foundation

enum AIModelTier {
    case free
    case paid
}

struct AIModelConfig {
    let modelName: String
    let endpoint: String // "v1" or "v1beta"
    let provider: String
}

class AIModelRouter {
    static let shared = AIModelRouter()
    
    private init() {}
    
    func getBestConfig(for task: AIRequestType, tier: AIModelTier, provider: String = "gemini") -> AIModelConfig {
        // Architecture: Lite Tasks -> Flash-Lite, Realtime -> Flash, Heavy -> Pro
        
        switch task {
        // MARK: - Reasoning Tier (Pro, v1)
        case .weeklyPlan, .trendAnalysis, .contextCompression, .healthReasoning, .personalization:
            if tier == .paid {
                return AIModelConfig(modelName: "gemini-2.5-pro", endpoint: "v1", provider: "gemini")
            } else {
                // Fallback to Flash for free tier
                return AIModelConfig(modelName: "gemini-2.5-flash", endpoint: "v1beta", provider: "gemini")
            }
            
        // MARK: - Lite Tier (Flash-Lite, v1beta)
        case .parsing, .classification, .memoryExtraction, .formatting, .activityTracking, .barcodeAnalysis, .toneRewrite:
            return AIModelConfig(modelName: "gemini-2.5-flash-lite", endpoint: "v1beta", provider: "gemini")
            
        // MARK: - Main Tier (Flash, v1beta)
        case .chat, .mealSuggestion, .mealPlanDay, .dailySummary, .ocrRecognition, .voiceParsing, .insightDetection:
            return AIModelConfig(modelName: "gemini-2.5-flash", endpoint: "v1beta", provider: "gemini")
        }
    }
    
    /// Provides a fallback config if the primary one fails (e.g. 404 on v1)
    func getFallbackConfig(for config: AIModelConfig) -> AIModelConfig? {
        // v1 (Pro) fails? Fallback to v1beta (Flash/Flash-Lite)
        if config.endpoint == "v1" {
            let fallbackModel = config.modelName.contains("pro") ? "gemini-2.5-flash" : config.modelName
            return AIModelConfig(modelName: fallbackModel, endpoint: "v1beta", provider: "gemini")
        }
        
        // If v1beta fails, try Lite version if not already on it
        if config.modelName == "gemini-2.5-flash" {
            return AIModelConfig(modelName: "gemini-2.5-flash-lite", endpoint: "v1beta", provider: "gemini")
        }
        
        return nil
    }
}
