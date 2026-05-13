import SwiftUI

struct MealDetailSheet: View {
    let food: FoodItemModel
    @Environment(\.dismiss) private var dismiss
    
    // Deep link to AI Coach
    @State private var navigateToAICoach = false
    
    // Auto-load missing data
    @State private var ingredients: [IngredientModel]?
    @State private var instructions: [String]?
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(food.name)
                                .font(.title.bold())
                                .foregroundColor(.primary)
                            
                            HStack {
                                Label("\(Int(food.calories)) kcal", systemImage: "flame.fill")
                                    .foregroundColor(.orange)
                                if let unit = food.unit {
                                    Label(UnitConversionEngine.shared.formatDisplayUnit(unit: unit, weight: food.weightInGrams), systemImage: "scalemass.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            .font(.subheadline.bold())
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            LinearGradient(colors: [.green.opacity(0.3), .blue.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .cornerRadius(20)
                    }
                    
                    // Macros Row
                    HStack {
                        MacroCard(label: "Đạm", value: food.protein, unit: "g", color: .blue)
                        MacroCard(label: "Tinh bột", value: food.carbs, unit: "g", color: .orange)
                        MacroCard(label: "Chất béo", value: food.fat, unit: "g", color: .pink)
                    }
                    
                    // Ingredients
                    if let currentIngredients = ingredients ?? food.ingredients, !currentIngredients.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Nguyên liệu")
                                .font(.headline)
                            
                            VStack(spacing: 0) {
                                ForEach(currentIngredients, id: \.name) { ingredient in
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text(ingredient.name)
                                                .foregroundColor(.primary)
                                                .fontWeight(.medium)
                                            Spacer()
                                            Text("\(Int(ingredient.amount))\(ingredient.unit)")
                                                .foregroundColor(.blue)
                                                .font(.subheadline.bold())
                                        }
                                        
                                        if let p = ingredient.protein, let c = ingredient.carbs, let f = ingredient.fat {
                                            HStack(spacing: 12) {
                                                Text("P: \(Int(p))g").foregroundColor(.secondary)
                                                Text("C: \(Int(c))g").foregroundColor(.secondary)
                                                Text("F: \(Int(f))g").foregroundColor(.secondary)
                                                Spacer()
                                            }
                                            .font(.caption)
                                        }
                                    }
                                    .padding(.vertical, 12)
                                    
                                    if ingredient != currentIngredients.last {
                                        Divider()
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(15)
                        }
                    }
                    
                    // Instructions
                    if let currentInstructions = instructions ?? food.instructions, !currentInstructions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Cách chế biến")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(Array(currentInstructions.enumerated()), id: \.offset) { index, step in
                                    HStack(alignment: .top, spacing: 12) {
                                        Text("\(index + 1)")
                                            .font(.caption.bold())
                                            .foregroundColor(.white)
                                            .frame(width: 20, height: 20)
                                            .background(Circle().fill(Color.green))
                                        
                                        Text(step)
                                            .font(.subheadline)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(15)
                        }
                    }
                    
                    // AI Coach Button
                    Button {
                        // Deep link logic for Wave 4
                        NotificationCenter.default.post(name: NSNotification.Name("AskAICoachAboutMeal"), object: food)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Hỏi AI Coach về món này")
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") { dismiss() }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .task {
                await loadMissingDataIfNeeded()
            }
        }
    }
    
    private func loadMissingDataIfNeeded() async {
        // 1. First, check if we can fetch a more up-to-date version from the repository
        // (This helps if background enrichment finished while the sheet was closed)
        if let latestFood = try? await MealRepository().fetchFoodItem(id: food.id) {
            if let latestIngredients = latestFood.ingredients, !latestIngredients.isEmpty {
                withAnimation {
                    self.ingredients = latestIngredients
                    self.instructions = latestFood.instructions
                }
                return
            }
        }
        
        // 2. If we already have data in state, don't re-load
        if (ingredients != nil && !ingredients!.isEmpty) {
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Ask AI to generate details based on name and existing macros (SILENTLY)
            if let result = try await AIService.shared.enrichFoodItem(
                name: food.name,
                calories: food.calories,
                isInternal: true
            ) {
                let mappedIngredients = result.ingredients?.map { 
                    IngredientModel(name: $0.name, amount: $0.amount, unit: $0.unit, protein: $0.protein, carbs: $0.carbs, fat: $0.fat)
                } ?? []
                let mappedInstructions = result.instructions ?? []
                
                withAnimation {
                    self.ingredients = mappedIngredients
                    self.instructions = mappedInstructions
                }
                
                // PERSIST for next time
                try? await MealRepository().updateFoodItemDetails(
                    id: food.id, 
                    ingredients: mappedIngredients, 
                    instructions: mappedInstructions
                )
            }
        } catch {
            print("Failed to auto-generate ingredients: \(error)")
        }
    }
}

struct MacroCard: View {
    let label: String
    let value: Double
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(Int(value))\(unit)")
                .font(.headline)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}
