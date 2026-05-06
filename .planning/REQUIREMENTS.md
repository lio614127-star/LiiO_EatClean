# Requirements: LiiO EatClean v1.2

**Defined:** 2026-05-06
**Core Value:** Trợ lý dinh dưỡng hiểu người dùng sâu sắc (bệnh lý, thói quen), giao tiếp nhanh nhạy (Voice, Parallel API) và hoạt động bền bỉ (Offline, Auto-swap).

## v1.2 Requirements

### 1. AI Memory Hub
- [ ] **MEMH-01**: User có thể truy cập màn hình AI Memory qua icon Brain ở góc màn hình Chat.
- [ ] **MEMH-02**: Màn hình AI Memory hiển thị toàn bộ thông tin đã lưu: Profile (tuổi, giới tính, chiều cao, cân nặng), Calories (target, TDEE, BMR), Health (bệnh lý, kiêng cữ), Preferences (thích/ghét), Notes.
- [ ] **MEMH-03**: Dữ liệu AI Memory phải được lưu persistent trên CoreData, trở thành Single Source of Truth cho các context AI.
- [ ] **MEMH-04**: Loại bỏ mục "AI nhớ về bạn" ở tab Meals để tránh duplicate UI.

### 2. API Key Infrastructure (Tối ưu tốc độ & Độ ổn định)
- [ ] **APIK-01**: User có thể nhập danh sách (pool) nhiều API keys trong màn hình Cài đặt.
- [ ] **APIK-02**: Hệ thống tự động chuyển đổi (auto swap) sang key khác khi key hiện tại báo lỗi quota/rate limit, không làm gián đoạn UX.
- [ ] **APIK-03**: Hỗ trợ tuỳ chọn "Parallel Request" (Gọi song song các key và lấy kết quả trả về sớm nhất) để giảm độ trễ (latency).

### 3. Voice Chat (Chat bằng giọng nói)
- [ ] **VCHT-01**: User có thể nhấn nút Mic trong màn hình Chat để bắt đầu thu âm.
- [ ] **VCHT-02**: Ứng dụng dùng Apple Speech On-device chuyển đổi giọng nói thành văn bản thời gian thực.
- [ ] **VCHT-03**: Hệ thống có bước hiển thị văn bản để User có thể xác nhận trước khi gửi lệnh cho AI.

### 4. Health-Aware AI (Ràng buộc bệnh lý)
- [ ] **HLTH-01**: Khung context của AI (ContextBuilder) có ràng buộc cứng: cấm tuyệt đối đề xuất/lên thực đơn các món ăn thuộc danh sách kiêng cữ hoặc trái với bệnh lý (vd: dị ứng, tiểu đường).
- [ ] **HLTH-02**: Gợi ý món ăn và thực đơn ưu tiên đề xuất thực phẩm hỗ trợ cải thiện tình trạng sức khoẻ.

### 5. Insight Detection Expansion
- [ ] **INSE-01**: Tích hợp thêm logic phát hiện thói quen "Ăn lặp món" (ví dụ: ăn cùng một món quá 3 ngày liên tiếp) để cảnh báo đa dạng hoá bữa ăn.
- [ ] **INSE-02**: Phân tích lệch macro dài ngày (dựa trên dữ liệu 3-7 ngày) để đưa ra Insight cảnh báo mất cân bằng dinh dưỡng.

### 6. Offline Mode (Tính năng cốt lõi)
- [ ] **OFFL-01**: App khởi động và hiển thị dashboard, lịch sử bữa ăn đầy đủ khi hoàn toàn không có internet.
- [ ] **OFFL-02**: User có thể log các món ăn từ local database hoặc Custom Foods khi offline.

### 7. Custom Food Builder
- [ ] **CFOD-01**: Cung cấp form để User tạo món ăn cá nhân hoá (Tên, Calories, Protein, Carbs, Fat).
- [ ] **CFOD-02**: Món ăn tự tạo được lưu vào CoreData và ưu tiên hiển thị đầu tiên khi tìm kiếm để log.

### 8. Context Compression Engine
- [ ] **COMP-01**: Hệ thống tự động tóm tắt history chat và memory trước khi đưa vào context để giảm số lượng token gửi lên LLM.
- [ ] **COMP-02**: Tóm tắt đảm bảo không làm mất thông tin core (bệnh lý, mục tiêu calo).

### 9. AI Personality Settings
- [ ] **PERS-01**: User có thể chọn phong cách trả lời của AI Coach trong Cài đặt (ví dụ: Nghiêm túc, Thân thiện/Động viên, Chill).
- [ ] **PERS-02**: System Prompt của Chatbot tự động điều chỉnh giọng văn (tone) tương ứng với phong cách đã chọn.

## Out of Scope (for v1.2)
- Multi-device CloudKit sync (Defer sang v2.0 do cần migration phức tạp).
- Social sharing/Community (Hoãn lại để ưu tiên AI Coach thông minh hơn).

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| MEMH-01 | Phase 15 | [ ] |
| MEMH-02 | Phase 15 | [ ] |
| MEMH-03 | Phase 15 | [ ] |
| MEMH-04 | Phase 15 | [ ] |
| APIK-01 | Phase 16 | [ ] |
| APIK-02 | Phase 16 | [ ] |
| APIK-03 | Phase 16 | [ ] |
| VCHT-01 | Phase 17 | [ ] |
| VCHT-02 | Phase 17 | [ ] |
| VCHT-03 | Phase 17 | [ ] |
| HLTH-01 | Phase 18 | [ ] |
| HLTH-02 | Phase 18 | [ ] |
| INSE-01 | Phase 18 | [ ] |
| INSE-02 | Phase 18 | [ ] |
| OFFL-01 | Phase 19 | [ ] |
| OFFL-02 | Phase 19 | [ ] |
| CFOD-01 | Phase 19 | [ ] |
| CFOD-02 | Phase 19 | [ ] |
| COMP-01 | Phase 16 | [ ] |
| COMP-02 | Phase 16 | [ ] |
| PERS-01 | Phase 15 | [ ] |
| PERS-02 | Phase 15 | [ ] |

---
*Requirements defined: 2026-05-06 for Milestone v1.2*
