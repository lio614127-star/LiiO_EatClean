# Phase 2: Splash + Onboarding + Goal Setup - Discussion Log

**Date:** 2026-04-29
**Duration:** ~10 phút
**Areas discussed:** 4/4

## Discussion History

### Area 1: Splash Screen (2 câu hỏi)

**Q1: Kiểu hiển thị logo**
- Options: (1) Tĩnh đơn giản, (2) Animation nhẹ
- **Selected: 2 — Animation nhẹ**
- Reasoning: First impression quan trọng, scale+fade tạo cảm giác premium, 2s không gây khó chịu

**Q2: Logo dùng gì**
- Options: (1) SF Symbol + Text, (2) Typography thuần
- **Selected: 2 — Typography thuần**
- Reasoning: Clean hơn, giống app premium, không cần design asset. "LiiO" Bold 32-40pt + "EatClean" Regular #666
- User refine: scale 0.9→1.0, opacity 0→1, easeOut

### Area 2: Onboarding Slides (2 câu hỏi)

**Q3: Minh hoạ trên slide**
- Options: (1) SF Symbol lớn, (2) Emoji + Gradient
- **Selected: 1 — SF Symbol lớn**
- Reasoning: Đồng bộ Apple ecosystem, clean/chuyên nghiệp, dễ maintain

**Q4: Chuyển slide kiểu gì**
- Options: (1) TabView PageStyle, (2) Scroll dọc
- **Selected: 1 — TabView PageStyle**
- Reasoning: Pattern chuẩn iOS, user đã quen swipe ngang + dots
- User refine: Icons: flame.fill / chart.bar.fill / figure.walk. Animation fade+slide nhẹ

### Area 3: Goal Setup Flow (3 câu hỏi)

**Q5: Số bước**
- Options: (1) 3 bước, (2) 4 bước
- **Selected: 1 — 3 bước**
- Reasoning: Ít friction, đủ thông tin, không dài dòng

**Q6: Cách nhập số**
- Options: (1) Wheel Picker, (2) TextField + Stepper
- **Selected: 2 — TextField + Stepper**
- Reasoning: Nhập nhanh + chính xác, dễ sửa
- User refine: auto focus, numeric keyboard

**Q7: Goal types**
- Options: (1) 3 loại cơ bản, (2) 5 loại chi tiết
- **Selected: 1 — 3 loại cơ bản**
- Reasoning: Lose/Maintain/Gain đủ rõ, map deficit nội bộ (-500/0/+300)

### Area 4: Calorie Calculation (2 câu hỏi)

**Q8: Hiển thị kết quả**
- Options: (1) Màn hình riêng celebration, (2) Preview inline tại Step 3
- **Selected: 2 — Preview inline**
- Reasoning: Nhanh gọn, không gián đoạn flow, speed > cảm xúc cho app utility

**Q9: Cho chỉnh thủ công?**
- Options: (1) Không cho chỉnh, (2) Cho chỉnh sau trong Profile
- **Selected: 2 — Cho chỉnh sau**
- Reasoning: Onboarding đơn giản, user nâng cao vẫn có control ở Profile
- User refine: Preview hiển thị "🔥 Your daily calories" + số lớn + animate khi đổi goal

## Deferred Ideas
- Activity level selection → Phase 7 Profile
- Custom calorie override trong onboarding → Phase 7 Profile
- Dark mode splash colors → Phase 8 Polish

---
*Discussion completed: 2026-04-29*
