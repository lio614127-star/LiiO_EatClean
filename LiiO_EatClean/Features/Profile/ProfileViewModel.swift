import Foundation

@Observable
class ProfileViewModel {
    var user: UserModel?
    var apiKeys: [APIKeyModel] = []
    
    // Editable fields (bound to Form)
    var name: String = ""
    var goalType: String = "maintain" {
        didSet { recalculateCalories() }
    }
    var age: String = "" {
        didSet { recalculateCalories() }
    }
    var height: String = "" {
        didSet { recalculateCalories() }
    }
    var weight: String = "" {
        didSet { recalculateCalories() }
    }
    var dailyCalorieTarget: String = ""
    
    private func recalculateCalories() {
        guard let w = Double(weight), let h = Double(height), let a = Double(age) else { return }
        let calculated = CalorieCalculator.calculateDailyCalories(
            weight: w,
            height: h,
            age: a,
            gender: user?.gender ?? "male",
            goal: goalType
        )
        dailyCalorieTarget = String(Int(calculated))
    }
    
    // API Key inputs
    var geminiKeyInput: String = ""
    var openAIKeyInput: String = ""
    
    var isSaving = false
    var errorMessage: String? = nil
    
    let goalOptions = ["lose", "maintain", "gain"]
    
    // Map goal IDs to Vietnamese labels
    static let goalLabels: [String: String] = [
        "lose": "Giảm cân",
        "maintain": "Duy trì cân nặng",
        "gain": "Tăng cơ",
        // Legacy Vietnamese values
        "Giảm cân": "Giảm cân",
        "Duy trì cân nặng": "Duy trì cân nặng",
        "Tăng cơ": "Tăng cơ"
    ]
    
    func goalLabel(for id: String) -> String {
        Self.goalLabels[id] ?? id
    }
    
    private let userRepository: UserRepositoryProtocol
    
    init(userRepository: UserRepositoryProtocol = UserRepository()) {
        self.userRepository = userRepository
    }
    
    func loadData() async {
        do {
            user = try await userRepository.fetchUser()
            if let u = user {
                name = u.name
                age = u.age > 0 ? String(Int(u.age)) : ""
                height = u.height > 0 ? String(format: "%.0f", u.height) : ""
                weight = u.weight > 0 ? String(format: "%.1f", u.weight) : ""
                goalType = u.goalType.isEmpty ? "maintain" : u.goalType
                dailyCalorieTarget = u.dailyCalorieTarget > 0 ? String(Int(u.dailyCalorieTarget)) : ""
            }
            
            let keys = try await userRepository.fetchAPIKeys()
            apiKeys = keys
            geminiKeyInput = keys.first(where: { $0.provider == "gemini" })?.key ?? ""
            openAIKeyInput = keys.first(where: { $0.provider == "openai" })?.key ?? ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func saveProfile() async {
        isSaving = true
        defer { isSaving = false }
        
        let updatedUser = UserModel(
            id: user?.id ?? UUID(),
            name: name,
            age: Double(age) ?? user?.age ?? 0,
            gender: user?.gender ?? "male",
            height: Double(height) ?? user?.height ?? 0,
            weight: Double(weight) ?? user?.weight ?? 0,
            goalType: goalType,
            dailyCalorieTarget: Double(dailyCalorieTarget) ?? user?.dailyCalorieTarget ?? 2000
        )
        
        do {
            try await userRepository.saveUser(updatedUser)
            user = updatedUser
        } catch {
            errorMessage = "Lưu thất bại: \(error.localizedDescription)"
        }
    }
    
    func saveGeminiKey() async {
        guard !geminiKeyInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let key = APIKeyModel(id: UUID(), provider: "gemini", key: geminiKeyInput.trimmingCharacters(in: .whitespaces), isActive: true)
        do {
            try await userRepository.saveAPIKey(key)
            await loadData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func saveOpenAIKey() async {
        guard !openAIKeyInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let key = APIKeyModel(id: UUID(), provider: "openai", key: openAIKeyInput.trimmingCharacters(in: .whitespaces), isActive: true)
        do {
            try await userRepository.saveAPIKey(key)
            await loadData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func deleteKey(provider: String) async {
        do {
            try await (userRepository as? UserRepository)?.deleteAPIKey(provider: provider)
            await loadData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    var hasGeminiKey: Bool { apiKeys.contains(where: { $0.provider == "gemini" }) }
    var hasOpenAIKey: Bool { apiKeys.contains(where: { $0.provider == "openai" }) }
    
    // Redact key for display (show only last 6 chars)
    func maskedKey(for provider: String) -> String {
        if let key = apiKeys.first(where: { $0.provider == provider })?.key, key.count > 6 {
            return "••••••" + key.suffix(6)
        }
        return ""
    }
    
    // MARK: - Reminder Settings
    var reminderStartHour: Int = UserDefaults.standard.integer(forKey: "reminderStartHour").nonZero ?? 8 {
        didSet { UserDefaults.standard.set(reminderStartHour, forKey: "reminderStartHour") }
    }
    
    var reminderEndHour: Int = UserDefaults.standard.integer(forKey: "reminderEndHour").nonZero ?? 20 {
        didSet { UserDefaults.standard.set(reminderEndHour, forKey: "reminderEndHour") }
    }
    
    var reminderIntervalHours: Int = UserDefaults.standard.integer(forKey: "reminderIntervalHours").nonZero ?? 2 {
        didSet { UserDefaults.standard.set(reminderIntervalHours, forKey: "reminderIntervalHours") }
    }
    
    var remindersEnabled: Bool = UserDefaults.standard.bool(forKey: "remindersEnabled") {
        didSet { UserDefaults.standard.set(remindersEnabled, forKey: "remindersEnabled") }
    }
    
    func updateReminders() async {
        if remindersEnabled {
            await ReminderService.shared.scheduleWaterReminders(
                startHour: reminderStartHour,
                endHour: reminderEndHour,
                intervalHours: reminderIntervalHours
            )
            await ReminderService.shared.scheduleMealReminders()
        } else {
            await ReminderService.shared.cancelAllWaterReminders()
        }
    }
    
    func resetAllData() async {
        isSaving = true
        defer { isSaving = false }
        
        do {
            try await (userRepository as? UserRepository)?.resetAllData()
            let mealRepo = MealRepository()
            try await mealRepo.deleteAllMeals()
            await loadData()
        } catch {
            errorMessage = "Reset thất bại: \(error.localizedDescription)"
        }
    }
}

private extension Int {
    var nonZero: Int? {
        self == 0 ? nil : self
    }
}

