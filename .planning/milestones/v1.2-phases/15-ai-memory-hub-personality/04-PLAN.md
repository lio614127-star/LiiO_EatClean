---
wave: 4
depends_on: [03-PLAN.md]
files_modified:
  - LiiO_EatClean/Features/Chat/ChatView.swift
  - LiiO_EatClean/Features/Meals/MealsView.swift
  - LiiO_EatClean/Features/Meals/Components/AIMemoryBadgeView.swift
  - LiiO_EatClean/Features/AI/Components/PersonalityPickerCard.swift
autonomous: true
requirements: [MEMH-01, MEMH-04, PERS-01]
---

# Plan 04: Personality UX & Navigation Entry Points

<objective>
Implement the Personality Picker card inside the Memory Hub with instant preview feedback, wire up the Chat brain icon, and replace the old Memory Summary Card in the Meals tab with a sleek Mini Badge.
</objective>

<action>
1. Create `PersonalityPickerCard.swift` (inside Memory Hub):
   - Display a list or grid of the 5 `AIPersonalityTone` options.
   - Highlight the currently selected tone.
   - On tap:
     - Update repository instantly.
     - Trigger light Haptic feedback (`UIImpactFeedbackGenerator(style: .light)`).
     - Apply a slight spring scale animation to the selected option.
     - Show a temporary "Preview Bubble" near the card for 2-3 seconds with a sample quote matching the tone.
       - Friendly: "Hôm nay bạn làm khá tốt rồi đó 👏 Chỉ cần thêm chút protein nữa là đẹp!"
       - Expert: "Lượng protein hiện chưa đủ. Bạn nên tăng thêm khoảng 20-25g protein/ngày."
       - Disciplined: "Bạn đã vượt target 3 ngày. Ngày mai cần siết lại đồ ngọt."
       - Chill: "Không sao đâu 😄 Một bữa ăn chưa hoàn hảo không phá hỏng cả hành trình."
       - Humorous: "Phở bò lần thứ 5 tuần này detected 🚨😂"

2. Update `ChatView.swift`:
   - Attach an action to the existing `brain.head.profile` toolbar icon.
   - Use `.fullScreenCover(isPresented:)` to present `MemoryHubView`.

3. Update `MealsView.swift`:
   - Remove usage of `MemorySummaryCard` and `MemoryEditorView`.
   - Create `AIMemoryBadgeView.swift`: a compact capsule (~44-52pt height), brain icon, light green tint, text "🧠 AI đang cá nhân hoá theo hồ sơ sức khoẻ của bạn" or "AI đã nhớ N sở thích".
   - Place `AIMemoryBadgeView` at the top of the Meals tab.
   - On tap, use `.fullScreenCover(isPresented:)` to present `MemoryHubView`.
</action>

<read_first>
- LiiO_EatClean/Features/Chat/ChatView.swift
- LiiO_EatClean/Features/Meals/MealsView.swift
- LiiO_EatClean/Features/Meals/Components/MemorySummaryCard.swift
</read_first>

<acceptance_criteria>
- `PersonalityPickerCard` is rendered in `MemoryHubView` with 5 options.
- Tapping an option immediately saves it, triggers a haptic pop, and displays the correct preview bubble which auto-dismisses.
- Tapping the brain icon in `ChatView` opens `MemoryHubView` via full-screen cover.
- `MealsView` no longer contains the old `MemorySummaryCard`.
- `AIMemoryBadgeView` is present in `MealsView` and tapping it opens `MemoryHubView` via full-screen cover.
</acceptance_criteria>
