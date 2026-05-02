# Phase 4: Food Database (Hybrid Search) - Discussion Log

**Date:** 2026-04-29
**Areas discussed:** 4/4

## Discussion History

### Area 1: Local Database (Món ăn Việt)

**Q1: Cấu trúc file JSON**
- Options: (1) Flat list, (2) Theo danh mục
- **Selected: 1 — Flat list**
- Reasoning: Search O(n) với 50-200 items là siêu nhanh. Code đơn giản, không cần xử lý category phức tạp ở data layer.

**Q2: Số lượng món seed ban đầu**
- Options: (1) ~50 món cốt lõi, (2) 200+ món
- **Selected: 1 — Khoảng 50 món cốt lõi**
- Reasoning: Đủ dùng ngay. Data đúng quan trọng hơn data nhiều, tránh làm sai calories và mất trust.

### Area 2: Chiến lược Hybrid Search

**Q3: Hiển thị kết quả khi gõ**
- Options: (1) Local trước, API sau, (2) Chờ API xong rồi merged
- **Selected: 1 — Show Local ngay lập tức, API nối đuôi sau**
- Reasoning: Tạo cảm giác "gõ phát có ngay", mượt mà. API trả về sau chỉ coi là bonus.

**Q4: Xử lý trùng lặp**
- Options: (1) Ưu tiên Local tuyệt đối, (2) Hiển thị tất cả
- **Selected: 1 — Ưu tiên Local tuyệt đối**
- Reasoning: Data VN từ local chuẩn xác hơn. API thường lệch calories và sai tên (e.g. "Pho soup"). Show cả hai gây rối cho user.

### Area 3: Hiển thị "Gợi ý" trước khi tìm

**Q5: Giao diện khi chưa gõ gì**
- Options: (1) Gộp chung Recent + Frequent, (2) Tách Tab
- **Selected: 1 — Gộp chung (Combined List)**
- Reasoning: Ít thao tác nhất, vuốt là thấy, không thêm friction không cần thiết.

### Area 4: Xử lý giới hạn API & Caching

**Q6: Caching kết quả API**
- Options: (1) Auto-Save vào CoreData vĩnh viễn, (2) Chỉ cache tạm thời
- **Selected: 1 — Auto-Save vào CoreData**
- Reasoning: Lợi ích lớn — giảm call API dần, app càng dùng càng thông minh, offline vẫn dùng tốt. Hướng tới "personal food database".

**Q7: Fallback khi API lỗi/hết limit**
- Options: (1) Silent fallback, (2) Alert cảnh báo
- **Selected: 1 — Silent Fallback**
- Reasoning: User không quan tâm lỗi API, chỉ quan tâm tìm món. Báo lỗi phá flow và gây khó chịu.

## User Insight
Định hướng cốt lõi: Xây dựng một **Offline-first intelligent system**. Local là core, API là hỗ trợ, Cache sẽ học theo user. Flow lý tưởng: Gõ -> Local instant -> API append. Chọn món API -> Save vào CoreData -> Lần sau offline dùng được ngay.

---
*Discussion completed: 2026-04-29*
