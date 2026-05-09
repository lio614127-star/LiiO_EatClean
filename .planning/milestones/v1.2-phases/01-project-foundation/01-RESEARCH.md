# Phase 1: Project Foundation & Data Layer — Research

**Gathered:** 2026-04-29
**Status:** Completed

## 1. Domain Investigation
The goal is to set up a robust, scalable iOS app skeleton using Swift and SwiftUI. The foundation requires:
1. **Xcode Project:** The base `.xcodeproj` targeting iOS 17+.
2. **CoreData Stack:** A `PersistenceController` that sets up the `NSPersistentContainer`.
3. **Data Model:** The `.xcdatamodeld` file defining the 7 entities and their relationships.
4. **Repository Pattern:** Protocols and their implementations to abstract CoreData away from ViewModels.
5. **App Navigation:** A 4-tab `TabView` structure using `NavigationStack`.

### 1.1 Technical Challenges & Approaches
- **CoreData Schema Creation:** CoreData models are typically created via Xcode's visual editor (`.xcdatamodeld`). Automating this via text files is possible by creating the raw XML of the `contents` file inside the `.xcdatamodeld` package.
- **Data Types:** Using `Double` for all numeric values (e.g., protein, carbs, fat, calories, weight) translates to `Double` type in CoreData (`Double 64-bit`).
- **Snapshot Pattern:** The `MealFood` entity requires storing the macronutrients at the time of logging. This implies the `MealRepository` must copy these values from `FoodItem` to `MealFood` during the save operation.
- **Background Contexts:** To ensure UI thread is not blocked, CoreData writes should use `container.performBackgroundTask`.

## 2. Standard Stack & Architecture Patterns
- **UI Framework:** SwiftUI (iOS 17+)
- **Concurrency:** `async/await` natively
- **Data Persistence:** CoreData with `NSPersistentContainer`
- **State Management:** `@Observable` (iOS 17 native macro)
- **Folder Structure:** Hybrid (Features for UI, Data for repositories and models, Core for utilities)

## 3. Implementation Strategy

### Step 1: Project Initialization
Since Xcode project files are difficult to generate from scratch safely without Xcodegen, the most reliable approach is to:
1. Provide a shell script or step-by-step instruction to create the Xcode project if it doesn't exist, OR
2. Generate the directory structure and the Swift source files, and instruct the user to open Xcode to create the initial `.xcodeproj` and `.xcdatamodeld`.
*Decision:* We will generate all the `.swift` files and the raw `.xcdatamodeld` XML structure. The user will just need to open the project in Xcode.

### Step 2: Persistence Layer
- Create `Persistence.swift` with a `PersistenceController` singleton.
- Configure for in-memory store for SwiftUI previews.
- Ensure the `CoreData` model XML is strictly aligned with the schema defined in `01-CONTEXT.md`.

### Step 3: Domain Models
- Define plain Swift structs for `User`, `Meal`, `FoodItem`, `MealFood`, `DailyLog`, `WeightEntry`, and `APIKey`.
- These map 1:1 with CoreData `NSManagedObject` subclasses but decouple the UI from CoreData.

### Step 4: Repository Layer
- Define protocols in `Data/Protocols/`.
- Implement them in `Data/Repositories/`.
- `UserRepository`: Auto-create a default User if none exists.
- `FoodRepository`: Fetch, add, search custom/API foods.
- `MealRepository`: Handle the Meal + MealFood junction, enforcing the snapshot pattern.

### Step 5: Tab Navigation Skeleton
- Create `Features/Home/HomeView.swift`, `Features/Meals/MealsView.swift`, etc.
- Create `LiiO_EatCleanApp.swift` integrating the `PersistenceController` and `TabView`.

## 4. Dependencies
- No external third-party dependencies required for Phase 1. All native Apple frameworks (SwiftUI, CoreData, Foundation).

## 5. Security & Safety
- **Threading:** CoreData managed objects must not be passed across thread boundaries. Repositories must map `NSManagedObject` to plain Swift structs before returning them to ViewModels.

---
*Research completed successfully.*
