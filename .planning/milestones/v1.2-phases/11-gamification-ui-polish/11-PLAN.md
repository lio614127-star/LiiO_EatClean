---
phase: 11
name: "Gamification & UI Polish"
plan: "11-PLAN"
wave: 1
depends_on: []
requirements: [STRK-01, STRK-02, UIPL-01, UIPL-02]
files_modified:
  - LiiO_EatClean.xcdatamodeld/LiiO_EatClean.xcdatamodel/contents
  - LiiO_EatClean/Data/Models/StreakModel.swift
  - LiiO_EatClean/Data/Protocols/UserRepositoryProtocol.swift
  - LiiO_EatClean/Data/Repositories/UserRepository.swift
  - LiiO_EatClean/Services/StreakService.swift
  - LiiO_EatClean/Core/Utils/HapticManager.swift
  - LiiO_EatClean/Features/Home/Components/StreakCardView.swift
  - LiiO_EatClean/Features/Home/Components/MilestonePopupView.swift
  - LiiO_EatClean/Features/Home/HomeView.swift
  - LiiO_EatClean/Features/Home/HomeViewModel.swift
  - LiiO_EatClean/Features/Home/Components/MealCardView.swift
  - LiiO_EatClean/Features/Home/Components/WaterCardView.swift
autonomous: true
verification:
  must_haves:
    - "StreakRecord entity tồn tại trong CoreData schema với currentStreak, longestStreak, lastActiveDate"
    - "StreakCardView hiển thị giữa CalorieRing và WaterCard trên Home"
    - "Streak tính đúng 3 tiêu chí: ≥2 bữa + ±10% calo + ≥80% nước"
    - "HapticManager phân loại: .success / .medium / .warning"
    - "Meal items mới có animation slide-in + fade"
    - "Milestone popup hiển thị khi đạt 7, 14, 30 ngày"
---

# Phase 11: Gamification & UI Polish — Plan

## Overview

Xây dựng hệ thống Streak (chuỗi ngày duy trì thói quen) với CoreData entity riêng, tích hợp Haptic Feedback phân loại theo ngữ nghĩa, và Micro-animations (slide-in + fade) để nâng cấp UX từ "functional" lên "feels good to use".

## Tasks

### Task 1: CoreData Schema + StreakModel

<read_first>
- LiiO_EatClean.xcdatamodeld/LiiO_EatClean.xcdatamodel/contents
- LiiO_EatClean/Data/Models/DailyLogModel.swift
- LiiO_EatClean/Data/Models/UserModel.swift
</read_first>

<action>
1. Mở file `LiiO_EatClean.xcdatamodeld/LiiO_EatClean.xcdatamodel/contents` (XML).
2. Thêm entity mới `StreakRecord` với các attributes:
   - `id` : UUID
   - `currentStreak` : Integer 32
   - `longestStreak` : Integer 32
   - `lastActiveDate` : Date
   - `mealConditionMet` : Boolean (≥2 bữa)
   - `calorieConditionMet` : Boolean (±10% target)
   - `waterConditionMet` : Boolean (≥80% target)
3. Tạo file `LiiO_EatClean/Data/Models/StreakModel.swift`:
   ```swift
   struct StreakModel: Identifiable, Codable {
       let id: UUID
       var currentStreak: Int
       var longestStreak: Int
       var lastActiveDate: Date
       var mealConditionMet: Bool
       var calorieConditionMet: Bool
       var waterConditionMet: Bool
       var conditionsMet: Int { [mealConditionMet, calorieConditionMet, waterConditionMet].filter { $0 }.count }
   }
   ```
</action>

<acceptance_criteria>
- `contents` XML chứa `<entity name="StreakRecord"` với 7 attributes đúng type
- File `StreakModel.swift` tồn tại với computed property `conditionsMet`
- `StreakModel` conform `Identifiable, Codable`
</acceptance_criteria>

---

### Task 2: UserRepository mở rộng — Streak CRUD

<read_first>
- LiiO_EatClean/Data/Protocols/UserRepositoryProtocol.swift
- LiiO_EatClean/Data/Repositories/UserRepository.swift
- LiiO_EatClean/Data/Persistence/Persistence.swift
</read_first>

<action>
1. Thêm vào `UserRepositoryProtocol.swift`:
   ```swift
   func fetchStreak() async throws -> StreakModel?
   func saveStreak(_ streak: StreakModel) async throws
   ```
2. Implement trong `UserRepository.swift`:
   - `fetchStreak()`: Fetch StreakRecord entity, map sang StreakModel struct. Nếu chưa có, return nil.
   - `saveStreak(_:)`: Upsert StreakRecord — tìm record hiện tại, update hoặc tạo mới. Dùng `context.perform` cho thread safety.
</action>

<acceptance_criteria>
- `UserRepositoryProtocol` chứa `func fetchStreak() async throws -> StreakModel?`
- `UserRepositoryProtocol` chứa `func saveStreak(_ streak: StreakModel) async throws`
- `UserRepository` implement cả 2 method với `context.perform`
- Build thành công không lỗi
</acceptance_criteria>

---

### Task 3: StreakService — Logic tính toán streak

<read_first>
- LiiO_EatClean/Features/Home/HomeViewModel.swift
- LiiO_EatClean/Data/Models/StreakModel.swift
- LiiO_EatClean/Data/Protocols/UserRepositoryProtocol.swift
</read_first>

<action>
1. Tạo `LiiO_EatClean/Services/StreakService.swift`:
   ```swift
   @Observable
   class StreakService {
       private let userRepository: UserRepositoryProtocol
       private let mealRepository: MealRepositoryProtocol

       func evaluateToday(meals: [MealModel], totalCalories: Double, dailyTarget: Double, waterConsumed: Double, waterTarget: Double) async -> StreakModel
   }
   ```
2. Logic `evaluateToday`:
   - **Tiêu chí 1 (Meal):** Đếm distinct mealTypes trong meals hôm nay. ≥2 bữa → `mealConditionMet = true`
   - **Tiêu chí 2 (Calo):** `abs(totalCalories - dailyTarget) <= dailyTarget * 0.10` → `calorieConditionMet = true`
   - **Tiêu chí 3 (Nước):** `waterConsumed >= waterTarget * 0.80` → `waterConditionMet = true`
   - Nếu cả 3 đạt AND `lastActiveDate` là hôm qua → `currentStreak += 1`
   - Nếu cả 3 đạt AND `lastActiveDate` KHÔNG phải hôm qua → `currentStreak = 1`
   - Nếu KHÔNG đạt đủ 3 → giữ streak hiện tại (chỉ reset khi qua ngày mới mà không đạt)
   - Update `longestStreak = max(longestStreak, currentStreak)`
   - Lưu qua `userRepository.saveStreak()`
</action>

<acceptance_criteria>
- File `StreakService.swift` tồn tại với method `evaluateToday`
- Dùng `@Observable` macro (không dùng ObservableObject)
- Logic kiểm tra 3 tiêu chí: ≥2 bữa, ±10% calo, ≥80% nước
- Streak chỉ tăng khi `lastActiveDate` là hôm qua (Calendar.current.isDateInYesterday)
- `longestStreak` luôn >= `currentStreak`
</acceptance_criteria>

---

### Task 4: HapticManager — Centralized Haptic Feedback

<read_first>
- LiiO_EatClean/Features/Home/Components/WaterCardView.swift (đã có haptic inline)
</read_first>

<action>
1. Tạo `LiiO_EatClean/Core/Utils/HapticManager.swift`:
   ```swift
   import UIKit

   enum HapticManager {
       static func success() {
           let generator = UINotificationFeedbackGenerator()
           generator.notificationOccurred(.success)
       }
       static func interaction() {
           let generator = UIImpactFeedbackGenerator(style: .medium)
           generator.impactOccurred()
       }
       static func warning() {
           let generator = UINotificationFeedbackGenerator()
           generator.notificationOccurred(.warning)
       }
       static func milestone() {
           let generator = UIImpactFeedbackGenerator(style: .heavy)
           generator.impactOccurred()
           DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
               let second = UINotificationFeedbackGenerator()
               second.notificationOccurred(.success)
           }
       }
   }
   ```
2. Refactor `WaterCardView.swift` — thay thế inline `UIImpactFeedbackGenerator` bằng `HapticManager.interaction()` (quick buttons) và `HapticManager.interaction()` (reset button).
</action>

<acceptance_criteria>
- File `HapticManager.swift` tồn tại với 4 static methods: `success()`, `interaction()`, `warning()`, `milestone()`
- `WaterCardView.swift` KHÔNG còn `UIImpactFeedbackGenerator` inline — tất cả thay bằng `HapticManager`
- Build thành công
</acceptance_criteria>

---

### Task 5: StreakCardView — UI Component

<read_first>
- LiiO_EatClean/Features/Home/Components/WaterCardView.swift (tham khảo card style)
- LiiO_EatClean/Features/Home/Components/CalorieRingView.swift (tham khảo animation)
</read_first>

<action>
1. Tạo `LiiO_EatClean/Features/Home/Components/StreakCardView.swift`:
   - Input: `streak: StreakModel`, `onTap: () -> Void`
   - Layout:
     ```
     [ 🔥 {currentStreak} ngày liên tiếp          🏆 Kỷ lục: {longestStreak} ]
     [   ● Bữa ăn  ● Calo  ● Nước uống                                       ]
     [   "Bạn đang duy trì rất tốt!" / "Gần đạt streak (2/3 điều kiện)"      ]
     ```
   - 3 condition dots: xanh (#4CAF50) nếu đạt, xám nếu chưa
   - 🌿 badge xuất hiện nếu `currentStreak >= 7`: overlay nhỏ góc phải card
   - Nếu `currentStreak >= 30`: 🌿 lớn hơn + màu đậm hơn
   - Card style: `.padding()`, `.background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)).shadow(...))`
   - Khi tap: `HapticManager.interaction()`
2. Animation: streak number animates khi thay đổi (`.contentTransition(.numericText())`)
</action>

<acceptance_criteria>
- File `StreakCardView.swift` tồn tại
- Hiển thị `currentStreak`, `longestStreak`, 3 condition indicators
- 🌿 badge xuất hiện khi `currentStreak >= 7`
- Card dùng `RoundedRectangle(cornerRadius: 16)` + shadow (giống WaterCardView)
- Gọi `HapticManager.interaction()` khi tap
</acceptance_criteria>

---

### Task 6: MilestonePopupView — Celebration khi đạt mốc

<read_first>
- LiiO_EatClean/Features/Home/Components/StreakCardView.swift
</read_first>

<action>
1. Tạo `LiiO_EatClean/Features/Home/Components/MilestonePopupView.swift`:
   - Input: `milestone: Int` (7, 14, 30), `isPresented: Binding<Bool>`
   - Overlay popup ở giữa màn hình, nền blur nhẹ
   - Content:
     - 🌿 icon lớn (7 ngày = cây con 40pt, 30 ngày = cây lớn 60pt)
     - Text: "🎉 Tuyệt vời! {milestone} ngày liên tiếp!"
     - Sub-text theo milestone:
       - 7: "Bạn đang xây dựng thói quen tốt!"
       - 14: "Thói quen đang trở nên bền vững!"
       - 30: "Bạn là người kiên trì nhất! 🏆"
     - Nút "Tiếp tục" để dismiss
   - Animation: scale from 0.5 → 1.0 với spring, fade in background
   - Tự động dismiss sau 4 giây nếu user không tap
   - Gọi `HapticManager.milestone()` khi xuất hiện
</action>

<acceptance_criteria>
- File `MilestonePopupView.swift` tồn tại
- Nhận `milestone: Int` và `isPresented: Binding<Bool>`
- Có animation scale spring khi xuất hiện
- Tự dismiss sau 4 giây (dùng `.task { try? await Task.sleep(...) }`)
- Gọi `HapticManager.milestone()` khi appear
</acceptance_criteria>

---

### Task 7: HomeView + HomeViewModel — Integration

<read_first>
- LiiO_EatClean/Features/Home/HomeView.swift (FULL file)
- LiiO_EatClean/Features/Home/HomeViewModel.swift (FULL file)
- LiiO_EatClean/Features/Home/Components/StreakCardView.swift
- LiiO_EatClean/Features/Home/Components/MilestonePopupView.swift
- LiiO_EatClean/Services/StreakService.swift
</read_first>

<action>
1. **HomeViewModel.swift:**
   - Thêm property: `var streak: StreakModel?`
   - Thêm property: `var showMilestonePopup = false`, `var milestoneValue = 0`
   - Inject `StreakService` vào init
   - Trong `loadDashboard()`: sau khi load meals + water, gọi `streakService.evaluateToday(...)` và gán result vào `self.streak`
   - Check milestone: nếu `streak.currentStreak` đạt mốc [7, 14, 30] AND chưa show → set `showMilestonePopup = true`, `milestoneValue = streak.currentStreak`
   - Thêm `HapticManager.success()` khi save meal thành công (trong `deleteMealFood` success path)
   - Thêm `HapticManager.warning()` khi `isOverTarget` chuyển từ false → true

2. **HomeView.swift:**
   - Chèn `StreakCardView` vào ScrollView, giữa `macroBarsSection` và `WaterCardView`:
     ```swift
     if let streak = viewModel.streak {
         StreakCardView(streak: streak, onTap: { })
             .padding(.horizontal, 24)
             .transition(.asymmetric(insertion: .slide.combined(with: .opacity), removal: .opacity))
     }
     ```
   - Thêm `.overlay` cho `MilestonePopupView`:
     ```swift
     .overlay {
         if viewModel.showMilestonePopup {
             MilestonePopupView(milestone: viewModel.milestoneValue, isPresented: $viewModel.showMilestonePopup)
         }
     }
     ```
</action>

<acceptance_criteria>
- `HomeViewModel` chứa `var streak: StreakModel?` và `var showMilestonePopup`
- `loadDashboard()` gọi `streakService.evaluateToday()`
- `HomeView` hiển thị StreakCardView giữa macroBars và WaterCard
- MilestonePopupView overlay hiển thị khi `showMilestonePopup == true`
- Build thành công, Dashboard hiển thị streak card
</acceptance_criteria>

---

### Task 8: Micro-animations — Slide-in + Fade cho MealCardView

<read_first>
- LiiO_EatClean/Features/Home/Components/MealCardView.swift (FULL file)
- LiiO_EatClean/Features/Home/HomeView.swift
</read_first>

<action>
1. **MealCardView.swift:**
   - Thêm `.transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))` cho mỗi meal food row trong ForEach
   - Wrap ForEach content trong `withAnimation(.easeInOut(duration: 0.3))` khi meals data thay đổi
   - Thêm `HapticManager.success()` khi swipe-delete thành công (trong onDelete callback)

2. **HomeView.swift:**
   - Thêm `.animation(.easeInOut(duration: 0.3), value: viewModel.todayMeals.count)` vào mealsSection để animate khi danh sách thay đổi
   - Thêm `HapticManager.success()` vào `activeAddMealType` sheet `onDismiss` (meal đã được save)
</action>

<acceptance_criteria>
- MealCardView food rows có `.transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))`
- HomeView mealsSection có `.animation(...)` value-based
- Haptic feedback gọi khi dismiss AddMeal sheet và khi delete meal
</acceptance_criteria>

---

## Verification

### Build Check
```bash
xcodebuild -scheme LiiO_EatClean -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
```

### Manual Verification
1. App mở → Home Dashboard hiển thị StreakCard giữa MacroBars và WaterCard
2. Log ≥2 bữa + đạt calo ±10% + nước ≥80% → streak +1, 🔥 tăng
3. Chỉ đạt 2/3 → card hiện "Gần đạt streak (2/3 điều kiện)"
4. Đạt 7 ngày → 🌿 badge xuất hiện + MilestonePopup animation
5. Haptic feedback cảm nhận được khi: save meal, add water, tap streak, vượt calo
6. Thêm meal mới → slide-in + fade animation mượt
