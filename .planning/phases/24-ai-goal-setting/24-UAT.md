# Phase 24 UAT: AI Personalized Goal Setting (Metabolic OS)

## Test Case 1: Metabolic Foundation Bootstrap
- **Description**: Verify that `MetabolicProfile` and `GoalHistory` are correctly initialized for a user.
- **Verification Steps**:
    1. Open HomeView.
    2. Check if `MetabolicRepository.bootstrapMetabolicData` is triggered.
- **Expected**: A `MetabolicProfile` is created and the first `GoalHistory` entry is snapshot.
- **Result**: `[x] Passed`

## Test Case 2: AI Coaching Card Display
- **Description**: Verify that the coaching card appears on the Home screen with relevant insights.
- **Verification Steps**:
    1. Observe the Home screen.
    2. Check for the "sparkles" icon and the "Cập nhật mục tiêu" or "Duy trì phong độ" title.
- **Expected**: A premium coaching card is visible above the streak card.
- **Result**: `[x] Passed`

## Test Case 3: Goal Adjustment Application
- **Description**: Verify that applying an AI suggestion creates a new versioned history entry.
- **Verification Steps**:
    1. Tap "Áp dụng mục tiêu mới" on a coaching card.
    2. Confirm the UI updates (calorie target ring change).
    3. Verify a new `GoalHistory` entry is saved with `version: 2`.
- **Expected**: Target updates immediately, previous goal is closed, new goal is active.
- **Result**: `[x] Passed`

## Test Case 4: Weekly Remainder & Flex Coaching
- **Description**: Verify the "Weekly Budget" display in the Progress tab.
- **Verification Steps**:
    1. Navigate to the Progress tab.
    2. Select "Calo" and "7N" (Week) view.
    3. Check for the "Ngân sách tuần còn lại" card.
- **Expected**: Card displays remaining kcal for the week with an adherence ring.
- **Result**: `[x] Passed`

## Test Case 5: Weekly Reflection Check-in
- **Description**: Verify the Weekly Reflection flow.
- **Verification Steps**:
    1. In Progress tab (Week view), tap "Đánh giá tuần này".
    2. Observe the full-screen reflection view.
- **Expected**: View shows adherence scores and energy level check-in.
- **Result**: `[x] Passed`

---

## Feedback & Issues Found
(None yet)
