# Phase 12: Advanced Data Inputs — Context

**Date:** 2026-05-05
**Phase:** 12 — Advanced Data Inputs (Voice Input & Barcode Scan)
**Requirements:** VOIC-01, VOIC-02, SCAN-01, SCAN-02

## Domain

Tích hợp hai phương thức nhập liệu mới — Voice Input (nói để log bữa ăn) và Barcode Scan (quét mã vạch sản phẩm) — để giảm thao tác và tăng tốc quy trình log bữa ăn.

## Decisions

### Voice Input — Entry Point & UX Flow (VOIC-01)

- **Entry points (2 nơi):**
  1. **Home Dashboard:** Nút micro floating/prominent — cho quick action log nhanh
  2. **AddMealView:** Nút micro cạnh nút "✨ Hỏi AI" — đúng ngữ cảnh khi đang thêm món
- **Confirm flow: Auto-fill cart → user confirm trước khi save**
  - SAI voice parse = mất trust → KHÔNG auto-save
  - Sau khi parse, hiển thị: tên món + số lượng + ước tính calo
  - 2 nút: [Xác nhận] và [Sửa]
  - User review rồi mới log
- **UX flow chuẩn:**
  ```
  Tap mic → Nói → AI parse → Hiện kết quả → [Xác nhận] / [Sửa]
  ```

### Voice Input — Speech Engine & AI Parsing (VOIC-02)

- **Speech-to-Text: Apple Speech (SFSpeechRecognizer) — on-device**
  - 100% FREE, không cần API key
  - Hỗ trợ tiếng Việt (`vi-VN`)
  - Hoạt động offline
  - Đủ tốt cho use-case log món ăn
- **Text → Food parsing: AI (Gemini/OpenAI) + local DB match-first**
  - **Tối ưu chi phí — local match trước, AI fallback:**
    ```
    Speech → text
     ↓
    Check local Vietnamese food DB (simple text match)
     ↓
    Match được → skip AI → hiện kết quả
    Không match → gọi AI parse → JSON {name, quantity, calories}
    ```
  - **Cache kết quả parse:** "phở bò" đã parse 1 lần → lưu lại → lần sau không cần gọi AI
  - **Prompt ngắn gọn:** Giảm token — chỉ gửi text ngắn, yêu cầu JSON output
  - **Limit usage:** 5–10 voice parse/ngày (v1) hoặc fallback sang manual nếu vượt
  - **Nguyên tắc:** AI đủ tốt + UX sửa nhanh > AI hoàn hảo 100%

### Barcode Scan — Camera UI & Scan Experience (SCAN-01)

- **Camera UI: Sheet camera (half-screen, `.medium` detent)**
  - Consistent với pattern sheet đã dùng trong app (AddMeal, MealDetail)
  - Nhẹ nhàng, dễ dismiss, không "nhảy context"
- **Scan behavior: Single-shot**
  - Quét 1 barcode → auto dismiss camera → hiện kết quả
  - 90% user chỉ scan 1 sản phẩm/lần
  - Đơn giản, ổn định, ít bug (không duplicate, không spam)
- **Hiển thị kết quả: Dismiss camera → result screen riêng**
  - User review: tên sản phẩm, calories, quantity
  - 2 nút: [Xác nhận] → add to cart, [Sửa] → chỉnh thông tin
  - Quan trọng vì barcode data đôi khi sai calo
- **Flow chuẩn:**
  ```
  Tap scan → Camera (sheet) → Scan → Auto dismiss → Result screen → [Xác nhận] / [Sửa]
  ```

### Barcode Scan — Data Source & Fallback (SCAN-02)

- **API chính: OpenFoodFacts (miễn phí, open-source)**
  - 100% FREE, không cần API key
  - Database 3M+ sản phẩm
  - REST: `GET https://world.openfoodfacts.org/api/v2/product/{barcode}`
  - Hạn chế với hàng Việt nội địa → chấp nhận cho v1
- **Fallback 2 tầng — "Always give user a next step":**
  ```
  Scan barcode
   ↓
  Case 1: OpenFoodFacts có đầy đủ data
   → Hiện → Confirm → Log

  Case 2: Có tên sản phẩm, thiếu nutrition
   → AI estimate calo/macros (dùng AIService)
   → Label: "Ước tính bởi AI"

  Case 3: Không tìm thấy gì
   → Auto-fill search bar bằng barcode/tên (nếu có)
   → User chọn từ search results
  ```
- **Tối ưu thêm:**
  - Cache barcode đã scan → lần sau load cực nhanh
  - Nếu AI estimate: hiển thị rõ label "Ước tính bởi AI" để user biết

## Code Context

### Reusable Assets
- `AddMealView.swift` — Integration point chính cho cả Voice và Barcode buttons
- `AIService.swift` — Đã có pattern gọi Gemini/OpenAI, tái sử dụng cho voice text parsing
- `FoodSearchView.swift` — Callback `onFoodSelected` — kết quả voice/barcode có thể feed vào
- `FoodSearchViewModel.swift` — Local food DB search logic, dùng cho local-match-first
- `HapticManager.swift` — Đã có `.success()`, `.interaction()` cho feedback khi scan/voice thành công
- `MealSheetItem` pattern — Tham khảo cho camera sheet presentation

### Patterns
- `@Observable` macro cho ViewModels
- Sheet pattern `.sheet(item:)` cho camera và result screens
- Repository pattern cho data persistence
- Cart pattern trong `AddMealViewModel` — kết quả voice/barcode add vào cart

## Canonical Refs
- `.planning/REQUIREMENTS.md` — VOIC-01, VOIC-02, SCAN-01, SCAN-02
- `.planning/ROADMAP.md` — Phase 12 scope
- `LiiO_EatClean/Features/Meals/AddMealView.swift` — Integration point chính
- `LiiO_EatClean/Features/Meals/AddMealViewModel.swift` — Cart logic
- `LiiO_EatClean/Features/AI/AIService.swift` — AI parsing service
- `LiiO_EatClean/Features/Meals/FoodSearchViewModel.swift` — Local food matching
- Apple Speech Framework: `Speech.framework` (SFSpeechRecognizer)
- OpenFoodFacts API: `https://world.openfoodfacts.org/api/v2/product/{barcode}`

## Deferred Ideas
- Continuous barcode scan (quét liên tục) — v2 nếu user cần
- Whisper API fallback cho speech — khi budget cho phép
- Barcode history / favorites — phase riêng
- Food photo recognition (AI từ ảnh) — capability hoàn toàn mới
