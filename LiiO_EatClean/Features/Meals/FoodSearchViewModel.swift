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
            suggestions = try await foodRepository.fetchSuggestions()
        } catch {
            print("Failed to load suggestions: \(error)")
            suggestions = []
        }
    }
    
    private func performSearch(query: String) async {
        // 1. Instant local search
        do {
            localResults = try await foodRepository.searchLocalFoods(query: query)
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
            let localNames = Set(localResults.map { $0.name.lowercased() })
            
            let filteredAPIResults = fetchedAPIResults.filter { apiItem in
                !localNames.contains(apiItem.name.lowercased())
            }
            
            apiResults = filteredAPIResults
            
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
