# Phase 7: Profile & AI Meal Suggestions - Discussion Log

**Date:** 2026-04-29
**Areas discussed:** 4/4

## Discussion History

### Area 1: Vị trí nút "Gợi ý món ăn AI" (AI Trigger Placement)

**Q1: Nơi đặt nút gọi AI**
- Options: (1) Trong Add Meal Sheet, (2) Một thẻ riêng trên màn hình Home
- **Selected: 1 — Trong Add Meal Sheet**
- Reasoning: Nút AI xuất hiện đúng moment user cần nhất (khi đang nghĩ "ăn gì?"). Tránh làm màn hình Home bị rối, và vì Add Meal là nơi hành động xảy ra, AI phải nằm ở đây để chuyển đổi nhanh nhất.

### Area 2: API Key Onboarding

**Q2: Cách hỏi API Key**
- Options: (1) Nhập khi cần (Lazy Prompt), (2) Nhập sẵn trong Profile
- **Selected: 1 — Lazy Prompt**
- Reasoning: Không cản trở onboarding chính. User chỉ bị yêu cầu nhập key khi thực sự muốn dùng AI. Nếu bắt nhập trước, 90% user có thể sẽ skip hoặc bỏ app. Đây là pattern chuẩn của các app xịn (unlock khi cần).

### Area 3: UI Profile

**Q3: Cấu trúc màn hình Profile**
- Options: (1) Standard iOS Form, (2) Custom Cards
- **Selected: 1 — Standard iOS Form**
- Reasoning: Chuẩn Apple, code nhanh, dễ maintain và user quen ngay lập tức. Màn hình Profile là functional screen (màn hình chức năng) nên không cần thiết kế Custom Card cầu kỳ gây mất diện tích.

### Area 4: Phân tích kết quả AI (AI Response Parsing)

**Q4: Định dạng kết quả trả về từ AI**
- Options: (1) Text đọc chơi, (2) JSON & tự động Log
- **Selected: 2 — JSON & Tự động Log**
- Reasoning: Quyết định cốt lõi để "nâng app lên level khác". Ép AI trả về JSON chuẩn để render thành Card đẹp mắt kèm nút "Log ngay". Auto thêm món vào bữa ăn. Tránh bắt user đọc text rồi tự đi search lại. "AI để action, không phải để chat".

## User Insight
Định hướng cốt lõi: **Biến app không chỉ thành tracker, mà là assistant ăn uống thật sự.** AI phải được ép trả về JSON hợp lệ, và app phải validate kỹ (nếu parse lỗi -> fallback) để không bị crash.

---
*Discussion completed: 2026-04-29*
