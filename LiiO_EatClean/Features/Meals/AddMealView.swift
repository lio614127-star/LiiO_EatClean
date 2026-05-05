import SwiftUI

struct AddMealView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AddMealViewModel
    
    // Alert state for quantity input
    @State private var showingQuantityAlert = false
    @State private var quantityInput = "1"
    @State private var selectedFood: FoodItemModel?
    @State private var showingCartDetails = false
    
    // Voice Input State
    @State private var showVoiceInput = false
    
    // Barcode Scan State
    @State private var showBarcodeScanner = false
    
    let mealTypes = ["Bữa sáng", "Bữa trưa", "Bữa tối", "Ăn vặt"]
    
    init(selectedMealType: String = "Bữa sáng") {
        _viewModel = State(initialValue: AddMealViewModel(selectedMealType: selectedMealType))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Meal Type Selector Header
                Picker("Loại bữa ăn", selection: $viewModel.selectedMealType) {
                    ForEach(mealTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .background(Color(.systemBackground))
                
                // AI Button Bar
                aiSuggestionBar
                
                // AI Suggestions Section
                if viewModel.showingAISection {
                    aiSuggestionsSection
                }
                
                // Embedded Food Search
                FoodSearchView { food in
                    selectedFood = food
                    // For manual search/suggestions, always default to 1 portion
                    quantityInput = "1"
                    showingQuantityAlert = true
                }
                
                // Cart Bottom Bar
                if !viewModel.cartItems.isEmpty {
                    cartBottomBar
                }
            }
            .navigationTitle("Thêm món ăn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Đóng") { dismiss() }
                }
            }
            .alert("Khẩu phần", isPresented: $showingQuantityAlert) {
                TextField("Số lượng (vd: 1.5)", text: $quantityInput)
                    .keyboardType(.decimalPad)
                Button("Huỷ", role: .cancel) { selectedFood = nil }
                Button("Thêm") {
                    if let food = selectedFood, let qty = Double(quantityInput.replacingOccurrences(of: ",", with: ".")), qty > 0 {
                        viewModel.addToCart(food: food, quantity: qty)
                    }
                    selectedFood = nil
                }
            } message: {
                if let food = selectedFood {
                    let perPortionCals = food.servingSize > 0 ? food.calories / food.servingSize : food.calories
                    Text("Nhập số lượng cho \(food.name) (Mỗi phần ≈ \(Int(perPortionCals)) kcal)")
                }
            }
            .alert("Cần API Key", isPresented: $viewModel.needsAPIKey) {
                Button("Đến Profile", role: .none) {
                    UserDefaults.standard.set(3, forKey: "selectedTab")
                    dismiss()
                }
                Button("Huỷ", role: .cancel) {}
            } message: {
                Text("Vui lòng thêm Gemini hoặc OpenAI API Key trong mục Hồ sơ để dùng tính năng AI.")
            }
            .sheet(isPresented: $showVoiceInput) {
                VoiceInputView(isPresented: $showVoiceInput) { foods in
                    // Automatically add the voice parsed foods to the cart
                    for food in foods {
                        viewModel.addSuggestedFood(food)
                    }
                }
            }
            .sheet(isPresented: $showBarcodeScanner) {
                BarcodeScanView(isPresented: $showBarcodeScanner) { food, qty in
                    // Adjust quantity and add
                    viewModel.addToCart(food: food, quantity: qty)
                }
            }
        }
        .task {
            await viewModel.loadRemainingCalories()
        }
    }
    
    // MARK: - AI Button Bar
    private var aiSuggestionBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Còn \(Int(viewModel.remainingCalories)) kcal hôm nay")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: { showBarcodeScanner = true }) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.orange)
                        .clipShape(Capsule())
                }
                
                Button(action: { showVoiceInput = true }) {
                    Image(systemName: "mic.fill")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
                
                Button(action: {
                    Task { await viewModel.requestAISuggestions() }
                }) {
                    Label(viewModel.isLoadingAI ? "Đang hỏi AI..." : "✨ Hỏi AI", systemImage: viewModel.isLoadingAI ? "" : "")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(colors: [.green, Color(red: 0.1, green: 0.7, blue: 0.5)],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(Capsule())
                }
                .disabled(viewModel.isLoadingAI)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
    }
    
    // MARK: - AI Suggestions Section
    private var aiSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
            
            if viewModel.isLoadingAI {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("AI đang phân tích thực đơn...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGroupedBackground))
                
            } else if let error = viewModel.aiError {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .padding(.top, 2)
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGroupedBackground))
                
            } else if viewModel.suggestedFoods.isEmpty {
                Text("Không tìm được gợi ý phù hợp. Hãy thử lại!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(.systemGroupedBackground))
                    
            } else {
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.green)
                        Text("AI gợi ý cho \(viewModel.selectedMealType)")
                            .font(.caption.bold())
                            .foregroundColor(.green)
                        Spacer()
                        Button("Ẩn") {
                            viewModel.showingAISection = false
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.08))
                    
                    ForEach(viewModel.suggestedFoods) { suggestion in
                        aiSuggestionCard(suggestion)
                        Divider().padding(.leading, 16)
                    }
                }
                .background(Color(.systemBackground))
            }
            
            Divider()
        }
    }
    
    @ViewBuilder
    private func aiSuggestionCard(_ suggestion: AISuggestedFood) -> some View {
        HStack(spacing: 12) {
            // Macro Info
            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.name)
                    .font(.subheadline.bold())
                
                HStack(spacing: 8) {
                    Text("\(Int(suggestion.calories)) kcal")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text("P:\(Int(suggestion.protein))g")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("C:\(Int(suggestion.carbs))g")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("F:\(Int(suggestion.fat))g")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Log button
            Button(action: {
                viewModel.addSuggestedFood(suggestion)
            }) {
                Text("+ Log")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .contentShape(Rectangle())
    }
    
    // MARK: - Cart Bottom Bar
    private var cartBottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack {
                Button(action: {
                    showingCartDetails = true
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(viewModel.cartItems.count) món đã chọn")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            let totalCals = viewModel.cartItems.reduce(0) { $0 + $1.caloriesSnapshot }
                            Text("\(Int(totalCals)) kcal")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                
                Button(action: {
                    Task {
                        await viewModel.saveCart(for: Date())
                        dismiss()
                    }
                }) {
                    Text("Hoàn tất")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .sheet(isPresented: $showingCartDetails) {
            NavigationStack {
                List {
                    let grouped = Dictionary(grouping: viewModel.cartItems) { $0.mealType ?? viewModel.selectedMealType }
                    let sortedTypes = ["Bữa sáng", "Bữa trưa", "Bữa tối", "Ăn vặt"].filter { grouped.keys.contains($0) }
                    
                    ForEach(sortedTypes, id: \.self) { type in
                        Section(header: Text(type).font(.subheadline.bold()).foregroundColor(.green)) {
                            if let items = grouped[type] {
                                ForEach(items) { item in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(item.foodItem?.name ?? "Món ăn")
                                                .font(.headline)
                                            Text("\(item.quantity, specifier: "%.1f") phần")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Text("\(Int(item.caloriesSnapshot)) kcal")
                                            .font(.subheadline.bold())
                                            .padding(.trailing, 8)
                                            
                                        Button(action: {
                                            viewModel.removeFromCart(id: item.id)
                                            if viewModel.cartItems.isEmpty {
                                                showingCartDetails = false
                                            }
                                        }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                    }
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Giỏ hàng (\(viewModel.cartItems.count))")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            viewModel.cartItems.removeAll()
                            showingCartDetails = false
                        }) {
                            Text("Xoá tất cả")
                                .foregroundColor(.red)
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Đóng") { showingCartDetails = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
}

#Preview {
    AddMealView()
}
