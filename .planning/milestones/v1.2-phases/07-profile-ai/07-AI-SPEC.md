# Phase 7: Profile & AI Meal Suggestions — AI Specification (AI-SPEC)

**Date:** 2026-04-29

## 1. Objective
Provide dynamic, context-aware meal suggestions for Vietnamese food using OpenAI/Gemini, outputting strict JSON that the app can instantly parse and render into actionable UI cards.

## 2. Framework & Architecture
- **Framework:** Native Swift `URLSession` using standard HTTP POST requests. No heavy third-party SDKs to keep the app lightweight.
- **Providers:** 
  - Primary: Google Gemini (`gemini-1.5-flash`) for speed and generous free tiers.
  - Secondary (Rotation): OpenAI (`gpt-4o-mini` or `gpt-3.5-turbo`) as fallback.
- **Service Layer:** `AIService` managing API key retrieval from `UserRepository`, endpoint routing, and JSON decoding.

## 3. Prompt Engineering
The system prompt must enforce context and strict structured output.

### 3.1 Input Context
The prompt sent to the LLM will dynamically inject:
1. `RemainingCalories` (e.g., 500 kcal).
2. `MealType` (e.g., Bữa tối).
3. `UserGoal` (e.g., Giảm cân / Tăng cơ).

### 3.2 System Prompt Example
```text
Bạn là một chuyên gia dinh dưỡng chuyên về ẩm thực Việt Nam. 
Nhiệm vụ của bạn là gợi ý 2 món ăn phù hợp cho {MealType} với tổng lượng calo khoảng {RemainingCalories} kcal.
Mục tiêu của người dùng là {UserGoal}.

BẮT BUỘC TRẢ VỀ CHUỖI JSON ĐÚNG ĐỊNH DẠNG. KHÔNG GIẢI THÍCH, KHÔNG CHAT THÊM, CHỈ TRẢ VỀ JSON.

Định dạng JSON yêu cầu:
[
  {
    "name": "Tên món ăn bằng tiếng Việt",
    "calories": <số nguyên>,
    "protein": <số nguyên>,
    "carbs": <số nguyên>,
    "fat": <số nguyên>,
    "servingSize": <số nguyên tính bằng gram>
  }
]
```

## 4. API Key Rotation & Fallback
- `AIService` checks the `APIKeyModel` list stored locally via CoreData.
- If Gemini fails (e.g., HTTP 429 or 401), it catches the error and transparently retries with the OpenAI key.
- If both fail, or no key is present, it throws a specific `AIError.missingKey` or `AIError.quotaExceeded`.
- The UI catches these and shows:
  - Missing Key -> "Vui lòng thêm API Key trong mục Profile".
  - Quota Exceeded -> "Hệ thống AI đang bận, vui lòng tự tìm kiếm món ăn".

## 5. Evaluation & Fallback UI (AI-04)
- **JSON Parsing Fallback:** If the LLM returns invalid JSON (e.g., wraps it in ```json ... ``` markdown), the app will use regex or string replacing to clean it before decoding. If decoding still fails, show a graceful error: "AI trả về dữ liệu không hợp lệ. Vui lòng thử lại."
- **UI State:** The `AddMealView` will show a shimmering loading state while fetching. If successful, it displays `MealCardView` style items with a `Log ngay` button.

## 6. Implementation Steps
1. Create `APIKeyModel` schema integration in `UserRepository`.
2. Build `AIService.swift` with endpoints and prompt constructors.
3. Build `ProfileView` for managing API Keys.
4. Integrate "Hỏi AI" button and JSON rendering in `AddMealView`.
