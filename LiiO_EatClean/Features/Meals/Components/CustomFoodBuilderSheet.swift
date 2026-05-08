import SwiftUI

struct CustomFoodBuilderSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var existingFood: FoodItemModel?
    var onSave: ((FoodItemModel) -> Void)?
    var onSaveAndAdd: ((FoodItemModel) -> Void)?
    
    @State private var name = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var servingSize = "1"
    @State private var useAutoCalc = true
    @State private var isSaving = false
    
    var calculatedCalories: Double {
        let p = Double(protein) ?? 0
        let c = Double(carbs) ?? 0
        let f = Double(fat) ?? 0
        return 4 * p + 4 * c + 9 * f
    }
    
    var caloriesMismatch: Bool {
        guard !useAutoCalc, let manual = Double(calories) else { return false }
        return abs(manual - calculatedCalories) > calculatedCalories * 0.15 && calculatedCalories > 0
    }
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        (Double(useAutoCalc ? String(calculatedCalories) : calories) ?? 0) > 0
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Thông tin cơ bản") {
                    TextField("Tên món (VD: Cơm gà mẹ nấu)", text: $name)
                }
                
                Section {
                    Toggle("Tự động tính Calories từ Macros", isOn: $useAutoCalc)
                        .tint(Color(hex: "4CAF50"))
                    
                    if useAutoCalc {
                        HStack {
                            Text("Calories")
                            Spacer()
                            Text("\(Int(calculatedCalories)) kcal")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        TextField("Calories (kcal)", text: $calories)
                            .keyboardType(.decimalPad)
                        
                        if caloriesMismatch {
                            Text("⚠️ Calories không khớp với macros")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    TextField("Protein (g)", text: $protein)
                        .keyboardType(.decimalPad)
                    TextField("Carbs (g)", text: $carbs)
                        .keyboardType(.decimalPad)
                    TextField("Fat (g)", text: $fat)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Dinh dưỡng")
                } footer: {
                    Text("Công thức: 1g Protein = 4 kcal, 1g Carbs = 4 kcal, 1g Fat = 9 kcal")
                }
                
                Section("Khẩu phần") {
                    TextField("Số lượng (mặc định: 1)", text: $servingSize)
                        .keyboardType(.decimalPad)
                }
                
                Section {
                    Button(action: save) {
                        Text(existingFood != nil ? "Cập nhật món" : "Lưu món")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!isValid || isSaving)
                    .tint(Color(hex: "4CAF50"))
                    
                    if existingFood == nil {
                        Button(action: saveAndAdd) {
                            Text("Lưu & thêm vào bữa")
                                .frame(maxWidth: .infinity)
                        }
                        .disabled(!isValid || isSaving)
                        .tint(Color(hex: "4CAF50"))
                    }
                }
            }
            .navigationTitle(existingFood != nil ? "Chỉnh sửa món" : "Tạo món mới")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hủy") { dismiss() }
                }
            }
            .onAppear {
                if let food = existingFood {
                    name = food.name
                    protein = String(format: "%.1f", food.protein)
                    carbs = String(format: "%.1f", food.carbs)
                    fat = String(format: "%.1f", food.fat)
                    servingSize = String(format: "%.1f", food.servingSize)
                    calories = String(format: "%.1f", food.calories)
                    useAutoCalc = false
                }
            }
        }
    }
    
    private func buildModel() -> FoodItemModel {
        return FoodItemModel(
            id: existingFood?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            calories: useAutoCalc ? calculatedCalories : (Double(calories) ?? 0),
            protein: Double(protein) ?? 0,
            carbs: Double(carbs) ?? 0,
            fat: Double(fat) ?? 0,
            servingSize: Double(servingSize) ?? 1.0,
            source: "custom",
            isCustom: true,
            createdAt: existingFood?.createdAt ?? Date(),
            updatedAt: Date()
        )
    }
    
    private func save() {
        isSaving = true
        let model = buildModel()
        HapticManager.success()
        onSave?(model)
        dismiss()
    }
    
    private func saveAndAdd() {
        isSaving = true
        let model = buildModel()
        HapticManager.success()
        onSaveAndAdd?(model)
        dismiss()
    }
}
