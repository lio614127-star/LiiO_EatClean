# Phase 15: AI Memory Hub & Personality - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-07
**Phase:** 15-ai-memory-hub-personality
**Areas discussed:** Migration Strategy, Memory Hub UI Layout, AI Personality UX, Entry Point & Navigation

---

## Migration Strategy — UserDefaults → CoreData

| Option | Description | Selected |
|--------|-------------|----------|
| Single Entity "AIMemory" | 1 entity chứa tất cả dạng JSON arrays, relationships cơ bản | |
| Multi-Entity normalized | Tách riêng: AIMemory, HealthCondition, FoodPreference, DietaryNote | ✓ |

**User's choice:** 2 — Multi-Entity normalized
**Notes:** "Vì sao đây là lựa chọn đúng nhất: Query được, filter được, scale được, inject context thông minh được. Single Entity JSON sẽ cực kỳ đau đầu."

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-migrate silent | Migrate ngầm không thông báo cho user | |
| Auto-migrate + toast thông báo | Migrate ngầm và hiện 1 dòng toast "✅ Đã nâng cấp trí nhớ AI" | ✓ |

**User's choice:** 2 — Auto-migrate + toast thông báo
**Notes:** "User sẽ yên tâm rằng 'AI memory' của họ không bị mất. Toast nhỏ là đủ, không gây phiền như popup/modal."

| Option | Description | Selected |
|--------|-------------|----------|
| Tạo `AIMemoryRepository` mới | Theo đúng Repository pattern đang có | ✓ |
| Refactor `MemoryManager` thành Repository | Đổi tên + refactor nội bộ MemoryManager | |

**User's choice:** Tạo AIMemoryRepository mới
**Notes:** "Architecture sẽ đồng nhất hoàn toàn (MealRepository, FoodRepository, UserRepository, AIMemoryRepository). MemoryManager đã trở thành data layer thật sự, không còn là manager."

| Option | Description | Selected |
|--------|-------------|----------|
| Duplicate profile vào AIMemory | AIMemory chứa snapshot profile riêng | |
| Reference User entity | Profile data đọc từ User entity qua UserRepository | ✓ |

**User's choice:** Reference User entity
**Notes:** "AI Memory ≠ User Profile. Không duplicate để tránh sync bugs và lệch data."

---

## Memory Hub UI Layout

| Option | Description | Selected |
|--------|-------------|----------|
| Grouped Cards (ScrollView) | Các card riêng biệt bo góc, shadow (consistent với DailySummaryCardView) | ✓ |
| Sectioned Form (List) | Giữ kiểu Form iOS-native feel | |
| Dashboard-style với stats | Header lớn, dashboard analytics overkill | |

**User's choice:** 1 — Grouped Cards (ScrollView)
**Notes:** "Card style: cornerRadius 24, soft shadow, light green accent. Memory Hub phải cho cảm giác AI thật sự hiểu người dùng chứ không phải settings storage page."

| Option | Description | Selected |
|--------|-------------|----------|
| View-only + Edit button | Default beautiful read-only, có nút edit mở sheet/navigation | ✓ |
| Inline edit trực tiếp | Tap edit/add in-place như Apple Contacts | |

**User's choice:** View-only + Edit button
**Notes:** "Inline edit dễ rối UI, phá visual premium. Default state: sạch, dễ đọc. Edit state: tách riêng, controlled."

| Option | Description | Selected |
|--------|-------------|----------|
| Illustration + CTA | Hình minh hoạ + Nút mở flow setup từng bước | ✓ |
| Empty cards với hints | Hiện các cards trống có chữ "Nhấn + để thêm" | |

**User's choice:** Illustration + CTA
**Notes:** "Guided setup cực kỳ quan trọng vì user không biết nên nhập gì. Flow đẹp: empty → onboarding → intelligence."

| Option | Description | Selected |
|--------|-------------|----------|
| Xoá sạch, không thay | Meals tab chỉ có list meal | |
| Thay bằng mini badge nhỏ | "🧠 AI đang cá nhân hoá..." tap vào mở Memory Hub | ✓ |

**User's choice:** Thay bằng mini badge nhỏ
**Notes:** "Nếu xoá sạch hoàn toàn: Meals tab sẽ mất liên kết với AI system. Card cũ quá to. Mini Badge là compact, subtle, nhẹ nhàng."

---

## AI Personality UX

| Option | Description | Selected |
|--------|-------------|----------|
| Trong Memory Hub | Thêm 1 card Tính cách AI ở Memory Hub | ✓ |
| Trong Profile/Settings | Cài đặt chung cùng với API key | |
| Cả hai | Shortcut ở Settings, Main ở Hub | |

**User's choice:** Trong Memory Hub
**Notes:** "Personality thuộc AI relationship/personalization. Đặt ở Memory Hub vì đây là nơi quy tụ AI hiểu bạn thế nào."

| Option | Description | Selected |
|--------|-------------|----------|
| 3 presets (đơn giản) | Cơ bản | |
| 4-5 presets (đa dạng) | Các tone khác biệt phong phú hơn | ✓ |

**User's choice:** 5 presets
**Notes:** "1. Thân thiện & Động viên (default), 2. Chuyên gia Nghiêm túc, 3. Kỷ luật cao, 4. Chill & Thoải mái, 5. Vui vẻ & Hài hước."

| Option | Description | Selected |
|--------|-------------|----------|
| Instant save + sample preview | Chọn -> haptic -> bong bóng chat preview hiện ra 2-3s | ✓ |
| Instant save, không preview | Checkmark im lặng | |

**User's choice:** Instant save + sample preview
**Notes:** "Tạo feeling AI sống động, giúp user cảm được tone ngay mà không cần quay lại test."

---

## Entry Point & Navigation

| Option | Description | Selected |
|--------|-------------|----------|
| Push NavigationLink | Vào stack của ChatView | |
| Sheet (.sheet) | Overlay che 1 phần | |
| Full-screen cover | Che toàn bộ màn hình, không gian riêng | ✓ |

**User's choice:** Full-screen cover
**Notes:** "Memory Hub đã trở thành 'bộ não AI' của toàn app, cần không gian riêng và premium feel. Push làm stack quá sâu."

| Option | Description | Selected |
|--------|-------------|----------|
| Mở Memory Hub full-screen trực tiếp | Tương tự nút ở ChatView | ✓ |
| Switch sang Chat tab + mở Memory Hub | Auto-jump qua Chat trước | |

**User's choice:** Mở Memory Hub full-screen cover trực tiếp
**Notes:** "UX mượt và premium nhất. Memory Hub nên là global AI layer, truy cập được trực tiếp từ nhiều nơi mà không cần nhảy tab loạn xạ."

