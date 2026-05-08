import SwiftUI

struct FoodSearchView: View {
    @State private var viewModel = FoodSearchViewModel()
    var onFoodSelected: (FoodItemModel) -> Void
    
    var body: some View {
        ZStack(alignment: .bottom) {
            List {
                if viewModel.searchText.isEmpty {
                    // When idle: show custom foods + suggestions
                    if !viewModel.customResults.isEmpty {
                        customFoodsSection
                    }
                    if !viewModel.suggestions.isEmpty {
                        Section(header: Text("Gợi ý")) {
                            ForEach(viewModel.suggestions) { food in
                                foodRow(for: food)
                            }
                        }
                    }
                } else {
                    // ⭐ Section 1: Custom foods
                    if !viewModel.customResults.isEmpty {
                        customFoodsSection
                    }
                    
                    // 🕘 Section 2: Recent
                    if !viewModel.recentResults.isEmpty {
                        Section(header: Text("🕘 Gần đây")) {
                            ForEach(viewModel.recentResults) { food in
                                foodRow(for: food)
                            }
                        }
                    }
                    
                    // 📦 Section 3: Local offline
                    if !viewModel.localResults.isEmpty {
                        Section(header: Text("📦 Dữ liệu offline")) {
                            ForEach(viewModel.localResults) { food in
                                foodRow(for: food)
                            }
                        }
                    }
                    
                    // Empty state with CTA
                    if viewModel.customResults.isEmpty && viewModel.localResults.isEmpty && 
                       viewModel.recentResults.isEmpty && !viewModel.isSearchingAPI && viewModel.apiResults.isEmpty {
                        emptyStateWithCTA
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
                    
                    // 🌐 Section 4: API
                    if !viewModel.apiResults.isEmpty {
                        Section(header: Text("🌐 CalorieNinjas")) {
                            ForEach(viewModel.apiResults) { food in
                                foodRow(for: food)
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            
            // Undo toast
            if viewModel.showUndoToast {
                undoToastView
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Nhập tên món ăn...")
        .task {
            await viewModel.loadSuggestions()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { viewModel.showCustomFoodBuilder = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.green)
                }
            }
        }
        .sheet(isPresented: $viewModel.showCustomFoodBuilder) {
            CustomFoodBuilderSheet(
                onSave: { food in Task { await viewModel.saveCustomFoodAndRefresh(food) } },
                onSaveAndAdd: { food in
                    Task { await viewModel.saveCustomFoodAndRefresh(food) }
                    onFoodSelected(food)
                }
            )
        }
        .sheet(item: $viewModel.editingFood) { food in
            CustomFoodBuilderSheet(
                existingFood: food,
                onSave: { updatedFood in Task { await viewModel.updateCustomFoodAndRefresh(updatedFood) } },
                onSaveAndAdd: { updatedFood in
                    Task { await viewModel.updateCustomFoodAndRefresh(updatedFood) }
                    onFoodSelected(updatedFood)
                }
            )
        }
    }
    
    private var customFoodsSection: some View {
        Section(header: HStack {
            Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption2)
            Text("Món của bạn").font(.subheadline.bold())
        }) {
            ForEach(viewModel.customResults) { food in
                customFoodRow(for: food)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) { 
                            Task { await viewModel.deleteCustomFood(food) } 
                        } label: {
                            Label("Xóa", systemImage: "trash")
                        }
                        Button { 
                            viewModel.editingFood = food 
                        } label: {
                            Label("Sửa", systemImage: "pencil")
                        }.tint(.blue)
                    }
                    .contextMenu {
                        Button { viewModel.editingFood = food } label: { Label("Chỉnh sửa", systemImage: "pencil") }
                        Button { Task { await viewModel.duplicateFood(food) } } label: { Label("Nhân bản", systemImage: "doc.on.doc") }
                        Divider()
                        Button(role: .destructive) { Task { await viewModel.deleteCustomFood(food) } } label: { Label("Xóa", systemImage: "trash") }
                    }
            }
        }
    }
    
    private var emptyStateWithCTA: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            Text("Không tìm thấy \"\(viewModel.searchText)\"")
                .font(.headline)
                .foregroundColor(.secondary)
            Button(action: { viewModel.showCustomFoodBuilder = true }) {
                Label("✨ Tạo món mới", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .listRowBackground(Color.clear)
    }
    
    private var undoToastView: some View {
        HStack {
            Text("🗑 Đã xóa món")
                .font(.subheadline)
            Spacer()
            Button("Hoàn tác") { Task { await viewModel.undoDelete() } }
                .font(.subheadline.bold())
                .foregroundColor(.green)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(radius: 4)
        .padding(.horizontal)
        .padding(.bottom, 8)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation { viewModel.showUndoToast = false }
            }
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
                    
                    Text("1 phần")
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
    
    private func customFoodRow(for food: FoodItemModel) -> some View {
        Button(action: {
            Task {
                await viewModel.selectFood(food)
            }
            onFoodSelected(food)
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text(food.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    Text("Custom")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green)
                        .cornerRadius(4)
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
        .listRowBackground(Color.green.opacity(0.05))
    }
}

#Preview {
    NavigationStack {
        FoodSearchView { _ in }
            .navigationTitle("Tìm món ăn")
    }
}
