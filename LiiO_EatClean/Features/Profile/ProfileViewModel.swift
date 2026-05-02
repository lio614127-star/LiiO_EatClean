import Foundation

@Observable
class ProfileViewModel {
    var user: UserModel?
    var apiKeys: [APIKeyModel] = []
    
    // Editable fields (bound to Form)
    var name: String = ""
    var age: String = ""
    var height: String = ""
    var weight: String = ""
    var goalType: String = "Duy trì cân nặng"
    var dailyCalorieTarget: String = ""
    
    // API Key inputs
    var geminiKeyInput: String = ""
    var openAIKeyInput: String = ""
    
    var isSaving = false
    var errorMessage: String? = nil
    
    let goalOptions = ["Giảm cân", "Duy trì cân nặng", "Tăng cơ"]
    
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
                goalType = u.goalType.isEmpty ? "Duy trì cân nặng" : u.goalType
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
    @ObservationIgnored var reminderStartHour: Int {
        get { UserDefaults.standard.integer(forKey: "reminderStartHour").nonZero ?? 8 }
        set { UserDefaults.standard.set(newValue, forKey: "reminderStartHour") }
    }
    
    @ObservationIgnored var reminderEndHour: Int {
        get { UserDefaults.standard.integer(forKey: "reminderEndHour").nonZero ?? 20 }
        set { UserDefaults.standard.set(newValue, forKey: "reminderEndHour") }
    }
    
    @ObservationIgnored var reminderIntervalHours: Int {
        get { UserDefaults.standard.integer(forKey: "reminderIntervalHours").nonZero ?? 2 }
        set { UserDefaults.standard.set(newValue, forKey: "reminderIntervalHours") }
    }
    
    var remindersEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "remindersEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "remindersEnabled") }
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
}

private extension Int {
    var nonZero: Int? {
        self == 0 ? nil : self
    }
}

