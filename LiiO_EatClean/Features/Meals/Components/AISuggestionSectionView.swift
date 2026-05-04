import SwiftUI

struct AISuggestionSectionView: View {
    @State private var viewModel = MealSuggestionViewModel()
    let remainingCalories: Double
    let onMealLogged: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.green)
                Text("AI Gợi ý")
                    .font(.headline)
                Spacer()
                Button {
                    Task {
                        await viewModel.fetchSuggestions(remainingCalories: remainingCalories)
                    }
                } label: {
                    Text("Gợi ý thêm")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            }
            
            // Remaining calories banner
            HStack {
                Text("Bạn còn \(Int(remainingCalories)) kcal hôm nay")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("• \(viewModel.suggestedMealType)")
                    .font(.subheadline.bold())
                    .foregroundColor(.green)
            }
            
            // Suggestion Cards
            if viewModel.isLoading {
                VStack {
                    ProgressView("Đang suy nghĩ...")
                        .padding()
                }
                .frame(maxWidth: .infinity)
            } else if let error = viewModel.errorMessage {
                VStack {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                    Button("Thử lại") {
                        Task { await viewModel.fetchSuggestions(remainingCalories: remainingCalories) }
                    }
                    .font(.caption.bold())
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else if viewModel.suggestions.isEmpty {
                Text("Hãy thêm API Key trong Profile để nhận gợi ý món ăn thông minh từ AI.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(viewModel.suggestions) { food in
                    SuggestionCard(food: food) {
                        Task {
                            await viewModel.logSuggestion(food)
                            onMealLogged()
                        }
                    }
                }
            }
            
            // Success Overlay
            if viewModel.showLogSuccess {
                Text("Đã log món ăn! ✓")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        .task {
            if viewModel.suggestions.isEmpty && !viewModel.hasFetched {
                await viewModel.fetchSuggestions(remainingCalories: remainingCalories)
            }
        }
        .animation(.easeInOut, value: viewModel.showLogSuccess)
        .animation(.easeInOut, value: viewModel.suggestions)
    }
}

struct SuggestionCard: View {
    let food: AISuggestedFood
    let onLog: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(food.name)
                    .font(.headline)
                Spacer()
                Text("\(Int(food.calories)) kcal")
                    .font(.headline.bold())
                    .foregroundColor(.green)
            }
            
            HStack(spacing: 16) {
                MacroMini(label: "P", value: food.protein, color: .blue)
                MacroMini(label: "C", value: food.carbs, color: .orange)
                MacroMini(label: "F", value: food.fat, color: .pink)
            }
            
            Button(action: onLog) {
                Text("Log Ngay")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.green)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
}
