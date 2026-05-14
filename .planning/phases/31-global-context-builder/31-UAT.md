# UAT Protocol: Phase 31 - Global Context Builder cho AI Coach

Hồ sơ kiểm thử nghiệm thu người dùng (User Acceptance Testing) cho hệ thống Adaptive Context Builder hiệu suất cao.

## Trạng thái Tổng quan
- **Tên Phase:** Global Context Builder cho AI Coach
- **Trạng thái:** Đang tiến hành kiểm thử (In Testing)
- **Tỷ lệ Đạt:** 1/5 kịch bản (20%)

---

## Bảng Kịch bản Kiểm thử

| ID | Kịch bản Kiểm thử | Mong đợi | Kết quả | Trạng thái |
|---|---|---|---|---|
| **UAT-31-01** | **Trạng thái Biên dịch XCode** | Dự án build thành công 100% trên Xcode, không phát sinh bất kỳ lỗi cú pháp, lỗi Codable hay lỗi tham số hàm `init()`. | Đã biên dịch thành công (Build Succeeded) | ✅ PASSED |
| **UAT-31-02** | **Bộ nhận diện Multi-Intent** | Đưa vào câu truy vấn tiếng Việt phức hợp. Hệ thống bóc tách chính xác danh mục Context (ví dụ: hỏi ăn uống + cân nặng -> nạp đồng thời MealLogs + WeightTrend). | Chờ xác nhận | ⏳ CHƯA CHẠY |
| **UAT-31-03** | **Độ trễ Thích ứng (Adaptive Timeout)** | Chế độ Chat chờ tối đa 3.0s. Chế độ Voice chờ tối đa 1.2s. Quá giờ lập tức hủy nạp nền và fallback lấy từ Snapshot Cache mà không đơ UI. | Chờ xác nhận | ⏳ CHƯA CHẠY |
| **UAT-31-04** | **Hướng dẫn Chống ảo giác** | Khi thiếu dữ liệu (ví dụ do Timeout), chuỗi prompt gắn nhãn lý do rõ ràng và kèm mệnh lệnh nghiêm cấm AI tự bịa thông tin Calo. | Chờ xác nhận | ⏳ CHƯA CHẠY |
| **UAT-31-05** | **Đấu nối E2E Toàn diện** | Kích hoạt Voice Assistant, kiểm tra luồng logs xác nhận hệ thống tự truyền tham số `voiceMode: true` và phản hồi trực quan tức thì. | Chờ xác nhận | ⏳ CHƯA CHẠY |

---

## Lịch sử Chạy Kiểm thử

### Đợt 1: 2026-05-14 (Đang chạy)
- *Ghi chú:* Đang yêu cầu User xác nhận UAT-31-01 đầu tiên để mở khóa chạy trên Simulator/Thiết bị thật.

---
*Người kiểm thử: AI Orchestrator & User*
*Lần cập nhật cuối: 2026-05-14*
