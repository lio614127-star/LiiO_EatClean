import Foundation
import SwiftUI

@Observable
class FoodSearchViewModel {
    var searchText: String = "" {
        didSet {
            // Cancel previous debounce task
            searchTask?.cancel()
            
            if searchText.isEmpty {
                customResults = []
                recentResults = []
                localResults = []
                apiResults = []
                isSearchingAPI = false
            } else {
                // Debounce search
                let currentQuery = searchText
                searchTask = Task {
                    // Slight delay for debounce
                    try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
                    guard !Task.isCancelled else { return }
                    await performSearch(query: currentQuery)
                }
            }
        }
    }
    
    // 4 sections
    var customResults: [FoodItemModel] = []
    var recentResults: [FoodItemModel] = []
    var localResults: [FoodItemModel] = []
    var apiResults: [FoodItemModel] = []
    
    var suggestions: [FoodItemModel] = []
    var isSearchingAPI: Bool = false
    
    // Custom food management
    var showCustomFoodBuilder = false
    var editingFood: FoodItemModel?
    var deletedFood: FoodItemModel?
    var showUndoToast = false
    
    private let foodRepository: FoodRepositoryProtocol
    private let apiService: FoodAPIServiceProtocol
    private var searchTask: Task<Void, Never>?
    
    init(foodRepository: FoodRepositoryProtocol = FoodRepository(),
         apiService: FoodAPIServiceProtocol = FoodAPIService()) {
        self.foodRepository = foodRepository
        self.apiService = apiService
    }
    
    func loadSuggestions() async {
        do {
            // Include custom foods in suggestions if they are recently used
            let custom = try await foodRepository.fetchCustomFoods()
            let rawSuggestions = try await foodRepository.fetchSuggestions()
            
            var allSuggestions = custom.filter { $0.lastUsed != nil } + rawSuggestions
            allSuggestions.sort { ($0.lastUsed ?? .distantPast) > ($1.lastUsed ?? .distantPast) }
            
            let normalized = allSuggestions.prefix(15).map { normalizeToSinglePortion($0) }
            suggestions = deduplicateByName(Array(normalized))
            
            // Re-run search if text is not empty
            if !searchText.isEmpty {
                await performSearch(query: searchText)
            } else {
                // Populate custom foods section even when not searching
                customResults = try await foodRepository.fetchCustomFoods().map { normalizeToSinglePortion($0) }
            }
        } catch {
            print("Failed to load suggestions: \(error)")
            suggestions = []
            customResults = []
        }
    }
    
    private func deduplicateByName(_ foods: [FoodItemModel]) -> [FoodItemModel] {
        var seenNames = Set<String>()
        return foods.filter { food in
            let name = food.name.lowercased().trimmingCharacters(in: .whitespaces)
            if seenNames.contains(name) {
                return false
            } else {
                seenNames.insert(name)
                return true
            }
        }
    }
    
    private func normalizeToSinglePortion(_ food: FoodItemModel) -> FoodItemModel {
        var normalized = food
        if food.servingSize > 20 {
            normalized.servingSize = 1.0
        } else if food.servingSize > 0 {
            let ratio = 1.0 / food.servingSize
            normalized.calories *= ratio
            normalized.protein *= ratio
            normalized.carbs *= ratio
            normalized.fat *= ratio
            normalized.servingSize = 1.0
        }
        return normalized
    }
    
    func performSearch(query: String) async {
        guard !query.isEmpty else { return }
        
        do {
            // 1. Custom foods
            let rawCustom = try await foodRepository.searchCustomFoods(query: query)
            customResults = deduplicateByName(rawCustom.map { normalizeToSinglePortion($0) })
            
            // 2. Recent (non-custom)
            let allSuggestions = try await foodRepository.fetchSuggestions()
            let filteredRecent = allSuggestions.filter { !$0.isCustom && $0.name.localizedCaseInsensitiveContains(query) }
            recentResults = deduplicateByName(filteredRecent.map { normalizeToSinglePortion($0) })
            
            // 3. Local database
            let rawLocal = try await foodRepository.searchLocalFoods(query: query)
            let normalizedLocal = rawLocal.map { normalizeToSinglePortion($0) }
            
            // Deduplicate local against custom and recent
            var seenNames = Set<String>()
            customResults.forEach { seenNames.insert($0.name.lowercased().trimmingCharacters(in: .whitespaces)) }
            recentResults.forEach { seenNames.insert($0.name.lowercased().trimmingCharacters(in: .whitespaces)) }
            
            localResults = normalizedLocal.filter { food in
                let name = food.name.lowercased().trimmingCharacters(in: .whitespaces)
                if seenNames.contains(name) { return false }
                seenNames.insert(name)
                return true
            }
        } catch {
            print("Local/Custom search failed: \(error)")
            customResults = []
            recentResults = []
            localResults = []
        }
        
        guard !Task.isCancelled else { return }
        
        // 4. API Search (Network check)
        guard NetworkMonitor.shared.isConnected else {
            apiResults = []
            isSearchingAPI = false
            return
        }
        
        isSearchingAPI = true
        apiResults = []
        
        do {
            let fetchedAPIResults = try await apiService.search(query: query)
            guard !Task.isCancelled else {
                isSearchingAPI = false
                return
            }
            
            // Deduplicate API against all previous sections
            var seenNames = Set<String>()
            customResults.forEach { seenNames.insert($0.name.lowercased().trimmingCharacters(in: .whitespaces)) }
            recentResults.forEach { seenNames.insert($0.name.lowercased().trimmingCharacters(in: .whitespaces)) }
            localResults.forEach { seenNames.insert($0.name.lowercased().trimmingCharacters(in: .whitespaces)) }
            
            let filteredAPI = fetchedAPIResults.filter { apiItem in
                let name = apiItem.name.lowercased().trimmingCharacters(in: .whitespaces)
                if seenNames.contains(name) { return false }
                seenNames.insert(name)
                return true
            }
            
            let normalizedAPI = filteredAPI.map { normalizeToSinglePortion($0) }
            apiResults = normalizedAPI // deduplicateByName is redundant here if we just checked Set but let's keep it safe
            
        } catch {
            print("API search failed: \(error)")
        }
        
        isSearchingAPI = false
    }
    
    // Auto-cache logic wrapper
    func selectFood(_ food: FoodItemModel) async {
        do {
            if food.source == "api" {
                try await foodRepository.saveFood(food)
            }
            try await foodRepository.updateLastUsed(for: food.id)
            if food.isCustom {
                // If we select a custom food, also fetch custom foods to re-order
                customResults = try await foodRepository.fetchCustomFoods().map { normalizeToSinglePortion($0) }
            }
        } catch {
            print("Failed to auto-cache food: \(error)")
        }
    }
    
    // MARK: - Custom Food Management
    
    func deleteCustomFood(_ food: FoodItemModel) async {
        deletedFood = food
        try? await foodRepository.deleteFood(by: food.id)
        showUndoToast = true
        customResults.removeAll { $0.id == food.id }
        // HapticManager.light() // Haptic logic moved to View level usually, or called here if available
    }

    func undoDelete() async {
        if let food = deletedFood {
            try? await foodRepository.saveCustomFood(food)
            deletedFood = nil
            showUndoToast = false
            if !searchText.isEmpty {
                await performSearch(query: searchText)
            } else {
                customResults = (try? await foodRepository.fetchCustomFoods())?.map { normalizeToSinglePortion($0) } ?? []
            }
        }
    }

    func duplicateFood(_ food: FoodItemModel) async {
        let duplicate = try? await foodRepository.duplicateCustomFood(food)
        if duplicate != nil {
            if !searchText.isEmpty {
                await performSearch(query: searchText)
            } else {
                customResults = (try? await foodRepository.fetchCustomFoods())?.map { normalizeToSinglePortion($0) } ?? []
            }
        }
    }
}
