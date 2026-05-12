# Phase 21: Next-Gen Nutrition & AI Planning Update — SPEC

**Status:** Draft
**Date:** 2026-05-09
**Requirements:** PLAN-01..03, UNIT-01..03, COOK-01..03, EDIT-01..03

## 1. Overview

Nâng cấp toàn diện kiến trúc AI Planning và Dữ liệu Dinh dưỡng. Chuyển đổi từ cơ chế "AI-Generated Everything" sang "Hybrid Architecture": Local Intelligence quản lý cấu trúc, AI tăng cường khả năng suy luận chi tiết. 

Mục tiêu: Tốc độ < 10s, UX Premium (Streaming), Dữ liệu cấu trúc sâu (Ingredients, Instructions), và tương tác thông minh (Magic Swap).

## 2. Technical Contracts

### 2.1 Data Models Updates

#### FoodItemModel (Updated)
```swift
struct FoodItemModel: Identifiable, Codable, Equatable {
    // Existing fields...
    var unit: String?             // e.g., "chén", "tô", "cái", "gram"
    var weightInGrams: Double?    // standard weight for the unit
    var ingredients: [Ingredient]? // structured ingredients
    var instructions: [String]?    // step-by-step instructions
    var isRecipeCached: Bool      // flag for recipe availability
}

struct Ingredient: Codable, Equatable {
    let name: String
    let amount: Double
    let unit: String
}
```

### 2.2 Turbo Planning (Single-Pass Streaming)

**Mechanism:**
1. **Request:** Gửi 1 prompt duy nhất cho Gemini 1.5 Flash (v1beta).
2. **Streaming:** Sử dụng `AsyncThrowingStream` để bắt các phần JSON hoàn thiện cho từng bữa ăn.
3. **Partial Parsing:** Sử dụng Regex hoặc JSON scanning để tách khối cho từng `mealType` ngay khi có thể parse được.
4. **Safety:** Vẫn giữ Layer 2 (Validation) và Layer 3 (Auto-repair) nhưng thực hiện async ngay sau khi stream xong từng bữa.

### 2.3 Smart Unit Conversion

**Logic:**
- Database sẽ lưu mapping mặc định: `1 chén cơm ≈ 200g`.
- UI hiển thị: `1 chén (~200g)`.
- Khi user đổi sang `gram`: `Weight = Input`, `Calories = (Input / WeightMặcĐịnh) * CaloriesGốc`.

### 2.4 Magic Swap (Local-First Engine)

**Algorithm:**
1. Filter database cho `mealType` tương ứng.
2. Calculate "Similarity Score" dựa trên:
   - Calorie Delta (±15% target)
   - Macro Ratio distance (Vector distance)
   - User Likes/Avoids logic
   - Variety Memory (Giảm điểm món vừa ăn < 3 ngày)
3. Return Top 10 results instantly.

## 3. UI/UX Workflow

### 3.1 Planning Dashboard
- [ ] Render 4 empty skeletons (Breakfast, Lunch, Dinner, Snack).
- [ ] Status bar: "Gemini 1.5 Flash đang tối ưu bữa trưa..."
- [ ] Meal Card fills in once parsed.

### 3.2 Meal Detail & AI Coach
- [ ] Recipe Sheet: Ingredients list + Instructions.
- [ ] Button "AI dạy nấu ăn" -> deep-link to ChatView.
- [ ] Injected Context: "Tôi muốn nấu món [X] cho [Y] phần ăn. Đây là nguyên liệu: [Z]. Hãy hướng dẫn tôi từng bước."

## 4. Risks & Mitigations

- **Risk:** AI trả về JSON lỗi giữa chừng làm hỏng streaming.
- **Mitigation:** Robust partial JSON parser, fallback về full parse nếu stream lỗi.
- **Risk:** Local swap không đủ đa dạng.
- **Mitigation:** Thêm nút "AI Refresh" để gọi AI tạo món mới hoàn toàn.
