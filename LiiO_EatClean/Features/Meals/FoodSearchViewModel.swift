import Foundation
import SwiftUI

@Observable
class FoodSearchViewModel {
    var searchText: String = "" {
        didSet {
            // Cancel previous debounce task
            searchTask?.cancel()
            
            if searchText.isEmpty {
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
    
    var localResults: [FoodItemModel] = []
    var apiResults: [FoodItemModel] = []
    var suggestions: [FoodItemModel] = []
    var isSearchingAPI: Bool = false
    
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
            let rawSuggestions = try await foodRepository.fetchSuggestions()
            let normalized = rawSuggestions.map { normalizeToSinglePortion($0) }
            suggestions = deduplicateByName(normalized)
        } catch {
            print("Failed to load suggestions: \(error)")
            suggestions = []
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
        
        // If servingSize is large (e.g. > 20), it's likely grams (API data).
        // 1 portion = the whole item (e.g. 1 bowl of 550g).
        if food.servingSize > 20 {
            normalized.servingSize = 1.0
            // calories, protein, etc. stay the same as they represent the whole item
        } else if food.servingSize > 0 {
            // If servingSize is small (portions), divide by servingSize to get 1 unit
            let ratio = 1.0 / food.servingSize
            normalized.calories *= ratio
            normalized.protein *= ratio
            normalized.carbs *= ratio
            normalized.fat *= ratio
            normalized.servingSize = 1.0
        }
        
        return normalized
    }
    
    private func performSearch(query: String) async {
        // 1. Instant local search
        do {
            let rawLocal = try await foodRepository.searchLocalFoods(query: query)
            let normalized = rawLocal.map { normalizeToSinglePortion($0) }
            localResults = deduplicateByName(normalized)
        } catch {
            print("Local search failed: \(error)")
            localResults = []
        }
        
        guard !Task.isCancelled else { return }
        
        // 2. Start API search
        isSearchingAPI = true
        apiResults = [] // Clear previous api results while loading
        
        do {
            let fetchedAPIResults = try await apiService.search(query: query)
            
            guard !Task.isCancelled else {
                isSearchingAPI = false
                return
            }
            
            // 3. Deduplicate (Priority: Local)
            let localNames = Set(localResults.map { $0.name.lowercased().trimmingCharacters(in: .whitespaces) })
            
            let filteredAPIResults = fetchedAPIResults.filter { apiItem in
                !localNames.contains(apiItem.name.lowercased().trimmingCharacters(in: .whitespaces))
            }
            
            let normalizedAPI = filteredAPIResults.map { normalizeToSinglePortion($0) }
            apiResults = deduplicateByName(normalizedAPI)
            
        } catch {
            print("API search failed: \(error)")
            // Silent fallback: apiResults remains empty
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
        } catch {
            print("Failed to auto-cache food: \(error)")
        }
    }
}
