# Phase 8: Water Tracking + Smart Reminders + Polish

## Goal Description
Complete the MVP by adding water intake tracking with 1-tap quick buttons on Home, interval-based smart reminders via Local Notifications, and micro-animation polish.
*(Note: Some structural groundwork was preemptively laid out in the previous transition; this plan covers completing the integration and verifying it.)*

## User Review Required
> [!IMPORTANT]
> The reminder system uses Local Notifications. To test this in the Simulator/Device, you will need to grant Notification permissions when prompted. The interval logic schedules multiple localized triggers for the day. Do you approve this approach?

## Open Questions
- None.

## Proposed Changes

### 1. Data Layer — Water Tracking
#### [NEW] [WaterLogModel.swift](file:///c:/Users/K2HPC/OneDrive/Desktop/CodeToolLiiO/LiiO_EatClean/LiiO_EatClean/Data/Models/WaterLogModel.swift)
#### [MODIFY] [UserRepositoryProtocol.swift](file:///c:/Users/K2HPC/OneDrive/Desktop/CodeToolLiiO/LiiO_EatClean/LiiO_EatClean/Data/Protocols/UserRepositoryProtocol.swift) — add water log methods
#### [MODIFY] [UserRepository.swift](file:///c:/Users/K2HPC/OneDrive/Desktop/CodeToolLiiO/LiiO_EatClean/LiiO_EatClean/Data/Repositories/UserRepository.swift) — implement water log CRUD

### 2. WaterCardView Component
#### [NEW] [WaterCardView.swift](file:///c:/Users/K2HPC/OneDrive/Desktop/CodeToolLiiO/LiiO_EatClean/LiiO_EatClean/Features/Home/Components/WaterCardView.swift) — progress bar + quick-add buttons

### 3. HomeView/HomeViewModel Integration
#### [MODIFY] [HomeViewModel.swift](file:///c:/Users/K2HPC/OneDrive/Desktop/CodeToolLiiO/LiiO_EatClean/LiiO_EatClean/Features/Home/HomeViewModel.swift) — add water state + log methods
#### [MODIFY] [HomeView.swift](file:///c:/Users/K2HPC/OneDrive/Desktop/CodeToolLiiO/LiiO_EatClean/LiiO_EatClean/Features/Home/HomeView.swift) — insert WaterCardView below CalorieRing

### 4. ReminderService
#### [NEW] [ReminderService.swift](file:///c:/Users/K2HPC/OneDrive/Desktop/CodeToolLiiO/LiiO_EatClean/LiiO_EatClean/Features/AI/ReminderService.swift) — UNUserNotificationCenter scheduling

### 5. ProfileView — Reminder Settings
#### [MODIFY] [ProfileView.swift](file:///c:/Users/K2HPC/OneDrive/Desktop/CodeToolLiiO/LiiO_EatClean/LiiO_EatClean/Features/Profile/ProfileView.swift) — add Reminder section
#### [MODIFY] [ProfileViewModel.swift](file:///c:/Users/K2HPC/OneDrive/Desktop/CodeToolLiiO/LiiO_EatClean/LiiO_EatClean/Features/Profile/ProfileViewModel.swift) — add reminder state

### 6. Micro-animation Polish
#### [MODIFY] [CalorieRingView.swift](file:///c:/Users/K2HPC/OneDrive/Desktop/CodeToolLiiO/LiiO_EatClean/LiiO_EatClean/Features/Home/Components/CalorieRingView.swift) — sweep animation
#### [MODIFY] [HomeView.swift](file:///c:/Users/K2HPC/OneDrive/Desktop/CodeToolLiiO/LiiO_EatClean/LiiO_EatClean/Features/Home/HomeView.swift) — haptic on water log

## Verification Plan

### Automated Tests
- None required for MVP.

### Manual Verification
1. Launch app, view Home screen, verify WaterCard is displayed.
2. Tap `+250ml` and ensure progress bar animates, haptic triggers, and state updates.
3. Open Profile view, toggle reminders, change interval settings, verify prompt for notification permissions appears.
4. Verify Calorie ring sweep animation when adding a new meal.
