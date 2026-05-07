---
wave: 3
depends_on: [02-PLAN.md]
files_modified:
  - LiiO_EatClean/Features/AI/MemoryHubView.swift
  - LiiO_EatClean/Features/AI/MemoryHubViewModel.swift
  - LiiO_EatClean/Features/AI/Components/MemoryCards.swift
  - LiiO_EatClean/Features/AI/GuidedSetupView.swift
autonomous: true
requirements: [MEMH-02]
---

# Plan 03: Memory Hub UI & Guided Setup

<objective>
Build the new AI Memory Hub UI using a premium grouped-cards layout, complete with an empty state illustration and a 5-step guided setup flow for new users.
</objective>

<action>
1. Create `MemoryHubViewModel.swift`:
   - Fetch `AIMemory` and User Profile data.
   - Provide properties for the UI to bind to.
   - Handle empty state detection: `hasMemoryData == true` if any conditions/preferences/notes exist.

2. Create `GuidedSetupView.swift`:
   - A multi-step sheet/view for onboarding:
     - Step 1: "Bạn có bệnh lý nào không?"
     - Step 2: "Có món nào cần kiêng?"
     - Step 3: "Bạn thích ăn gì?"
     - Step 4: "Có món nào ghét?"
     - Step 5: "Có lưu ý đặc biệt nào?"
   - Use simple text fields / tag inputs.
   - Save to `AIMemoryRepository` on completion.

3. Create `MemoryHubView.swift`:
   - If `!hasMemoryData`, show Empty State:
     - Brain illustration.
     - Text: "AI chưa hiểu rõ về bạn. Thêm bệnh lý, món yêu thích và các lưu ý để AI tư vấn chính xác hơn."
     - CTA Button: "Bắt đầu thiết lập AI Memory" (Opens `GuidedSetupView`).
   - If `hasMemoryData`, show Grouped Cards (ScrollView):
     - `ProfileCard`: Shows basic user metrics, "Chỉnh sửa" navigates to Profile.
     - `CaloriesCard`: Shows BMR/TDEE/Target.
     - `HealthCard`: Lists health conditions. "Chỉnh sửa" opens an editor sheet.
     - `PreferencesCard`: Lists likes/dislikes as chips. "Chỉnh sửa" opens an editor sheet.
     - `AvoidFoodsCard`: Lists avoid foods.
     - `NotesCard`: Lists dietary notes.
   - Style all cards with `cornerRadius: 24`, soft shadow, light green accent (`#4CAF50`), matching `StreakCardView` aesthetics.
</action>

<read_first>
- LiiO_EatClean/Features/Home/Components/StreakCardView.swift (for card visual references)
- LiiO_EatClean/Features/Profile/ProfileView.swift (for profile navigation context)
</read_first>

<acceptance_criteria>
- `MemoryHubView` correctly displays the empty state with CTA when no data exists.
- The 5-step guided setup successfully saves new data to the repository.
- When data exists, `MemoryHubView` displays grouped cards matching the premium aesthetic.
- "Chỉnh sửa" buttons exist on cards but do not allow inline editing directly in the ScrollView.
</acceptance_criteria>
