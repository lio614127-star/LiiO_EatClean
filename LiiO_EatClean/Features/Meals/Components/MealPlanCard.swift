import SwiftUI

struct MealPlanCard: View {
    let item: TimelineItem
    let pendingLinks: [LinkCandidate]
    var isViewOnly: Bool = false
    
    let onMarkEaten: (PlannedMealModel) -> Void
    let onSkip: (PlannedMealModel) -> Void
    let onLink: (MealModel, UUID) -> Void
    let onSwap: (AISuggestedFood) -> Void
    let onDelete: (AISuggestedFood) -> Void
    let onToggleLock: (PlannedMealModel) -> Void
    let onAddFood: () -> Void
    
    private var icon: String {
        MealPlanViewModel.mealIcons[item.type] ?? "🍽"
    }
    
    private var totalActualCalories: Double {
        item.actuals.reduce(0) { $0 + $1.totalCalories }
    }
    
    private var totalPlannedCalories: Double {
        item.planned?.totalCalories ?? 0
    }
    
    @State private var selectedFoodDetails: FoodItemModel?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text(icon)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.type)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    if totalActualCalories > 0 {
                        Text("Thực tế: \(Int(totalActualCalories)) kcal")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                if totalPlannedCalories > 0 {
                    Text("\(Int(totalPlannedCalories)) kcal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                }
                
                if let planned = item.planned, !isViewOnly {
                    Button(action: { 
                        HapticManager.interaction()
                        onToggleLock(planned) 
                    }) {
                        Image(systemName: planned.isLocked ? "lock.fill" : "lock.open")
                            .font(.system(size: 16))
                            .foregroundColor(planned.isLocked ? .orange : .secondary)
                            .padding(8)
                            .background(Circle().fill(planned.isLocked ? Color.orange.opacity(0.1) : Color.clear))
                    }
                    .padding(.leading, 4)
                }
            }
            
            // 1. PLANNED SECTION
            if let planned = item.planned {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        // Case-based status label
                        Group {
                            if planned.status == "eaten" {
                                Text("ĐÃ ĂN THEO KẾ HOẠCH")
                                    .foregroundColor(.green)
                            } else if planned.status == "skipped" {
                                Text("ĐÃ BỎ QUA")
                                    .foregroundColor(.gray)
                            } else if planned.status == "replaced" {
                                Text("ĐÃ THAY KẾ HOẠCH")
                                    .foregroundColor(.orange)
                            } else {
                                Text("KẾ HOẠCH")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .font(.caption2.bold())
                        .tracking(1)
                        
                        Spacer()
                    }
                    
                    ForEach(planned.foodItems) { food in
                        Button(action: { 
                            selectedFoodDetails = FoodItemModel(
                                id: food.id,
                                name: food.name,
                                calories: food.calories,
                                protein: food.protein,
                                carbs: food.carbs,
                                fat: food.fat,
                                servingSize: food.servingSize
                            )
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(food.name)
                                        .font(.subheadline)
                                        .strikethrough(planned.status == "skipped")
                                        .foregroundColor(planned.status != "planned" ? .secondary : .primary)
                                    
                                    MacroMiniRow(calories: food.calories, protein: food.protein)
                                }
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                             }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 4)
                    }
                    
                    if planned.status == "planned" && !isViewOnly {
                        HStack(spacing: 12) {
                            Button(action: { onMarkEaten(planned) }) {
                                Label("Đã ăn", systemImage: "checkmark")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.green)
                                    .cornerRadius(8)
                            }
                            
                            Button(action: { onSkip(planned) }) {
                                Text("Bỏ qua")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(12)
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(12)
            }
            
            // 2. ACTUAL SECTION (Show ONLY if not empty and contains foods)
            if item.actuals.contains(where: { !$0.mealFoods.isEmpty }) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("THỰC TẾ")
                        .font(.caption2.bold())
                        .foregroundColor(.green)
                        .tracking(1)
                    
                    ForEach(item.actuals.filter { !$0.mealFoods.isEmpty }) { meal in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    // Accurate Link Tag based solely on linkedPlannedMealId
                                    if meal.linkedPlannedMealId != nil {
                                        Text("Theo kế hoạch")
                                            .font(.system(size: 9, weight: .bold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.1))
                                            .foregroundColor(.blue)
                                            .cornerRadius(4)
                                    } else {
                                        Text("Ngoài kế hoạch")
                                            .font(.system(size: 9, weight: .bold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.orange.opacity(0.1))
                                            .foregroundColor(.orange)
                                            .cornerRadius(4)
                                    }
                                    
                                    Text(meal.mealFoods.compactMap { $0.foodItem?.name }.filter { !$0.isEmpty }.joined(separator: ", "))
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                                
                                Spacer()
                                
                                Text("\(Int(meal.totalCalories)) kcal")
                                    .font(.caption.bold())
                            }
                            
                            // Smart Linking Suggestion (Show ONLY if unplanned and plan has status "planned")
                            if meal.linkedPlannedMealId == nil,
                               let planned = item.planned,
                               planned.status == "planned",
                               pendingLinks.contains(where: { $0.mealLog.id == meal.id && $0.plannedMeal.id == planned.id }) {
                                Button(action: { onLink(meal, planned.id) }) {
                                    HStack {
                                        Image(systemName: "sparkles")
                                        Text("Gắn vào kế hoạch này?")
                                        Spacer()
                                        Image(systemName: "arrow.right")
                                    }
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(Color.purple.opacity(0.1))
                                    .foregroundColor(.purple)
                                    .cornerRadius(8)
                                }
                                .padding(.top, 2)
                            }
                        }
                        .padding(12)
                        .background(Color(.systemGray6).opacity(0.3))
                        .cornerRadius(12)
                    }
                }
            }
            
            if item.planned == nil && !item.actuals.contains(where: { !$0.mealFoods.isEmpty }) {
                Text("Trống")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        .sheet(item: $selectedFoodDetails) { food in
            MealDetailSheet(food: food)
        }
    }
}

struct MacroMiniRow: View {
    let calories: Double
    let protein: Double
    
    var body: some View {
        HStack(spacing: 8) {
            Text("\(Int(calories)) kcal")
            Text("•")
            Text("\(Int(protein))g P")
        }
        .font(.caption2)
        .foregroundColor(.secondary)
    }
}
