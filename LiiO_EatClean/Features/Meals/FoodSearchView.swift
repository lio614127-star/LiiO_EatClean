import SwiftUI

struct FoodSearchView: View {
    @State private var viewModel = FoodSearchViewModel()
    var onFoodSelected: (FoodItemModel) -> Void
    
    var body: some View {
        List {
            if viewModel.searchText.isEmpty {
                // Suggestions Section
                if !viewModel.suggestions.isEmpty {
                    Section(header: Text("Gợi ý")) {
                        ForEach(viewModel.suggestions) { food in
                            foodRow(for: food)
                        }
                    }
                }
            } else {
                // Search Results
                
                // Local Results
                if !viewModel.localResults.isEmpty {
                    Section(header: Text("Dữ liệu offline")) {
                        ForEach(viewModel.localResults) { food in
                            foodRow(for: food)
                        }
                    }
                } else if !viewModel.isSearchingAPI && viewModel.apiResults.isEmpty {
                    Text("Không tìm thấy món nào")
                        .foregroundColor(.secondary)
                        .padding()
                }
                
                // API Loading State
                if viewModel.isSearchingAPI {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView("Đang tìm kiếm online...")
                                .padding()
                            Spacer()
                        }
                    }
                }
                
                // API Results
                if !viewModel.apiResults.isEmpty {
                    Section(header: Text("Từ CalorieNinjas")) {
                        ForEach(viewModel.apiResults) { food in
                            foodRow(for: food)
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .searchable(text: $viewModel.searchText, prompt: "Nhập tên món ăn...")
        .task {
            await viewModel.loadSuggestions()
        }
    }
    
    private func foodRow(for food: FoodItemModel) -> some View {
        Button(action: {
            Task {
                await viewModel.selectFood(food)
            }
            onFoodSelected(food)
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(food.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if food.source == "api" {
                            Image(systemName: "icloud.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    }
                    
                    Text("\(Int(food.servingSize))g")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(food.calories)) kcal")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Text("P: \(Int(food.protein))g").foregroundColor(.blue)
                        Text("C: \(Int(food.carbs))g").foregroundColor(.orange)
                        Text("F: \(Int(food.fat))g").foregroundColor(.pink)
                    }
                    .font(.caption2)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    NavigationStack {
        FoodSearchView { _ in }
            .navigationTitle("Tìm món ăn")
    }
}
