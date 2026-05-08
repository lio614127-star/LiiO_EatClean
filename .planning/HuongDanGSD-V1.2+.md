# 📘 CẨM NANG HƯỚNG DẪN SỬ DỤNG GSD (V1.2+)

Chào mừng bạn đến với tài liệu hướng dẫn đầy đủ nhất về **GSD (Get Shit Done) V1.2+** bằng Tiếng Việt. Tài liệu này liệt kê chi tiết toàn bộ các câu lệnh của hệ thống GSD, được sắp xếp theo **quy trình phát triển chuẩn từ khi bắt đầu cho đến khi kết thúc dự án**.

---

## 🗺️ SƠ ĐỒ QUY TRÌNH PHÁT TRIỂN CHUẨN (CORE WORKFLOW)

```
[Bắt đầu Dự án] ➜ /gsd-new-project ➜ /gsd-map-codebase
      │
      ▼
[Quản lý Lộ trình] ➜ /gsd-phase ➜ /gsd-spec-phase ➜ /gsd-ui-phase / /gsd-ai-integration-phase
      │
      ▼
[Lên Kế hoạch] ➜ /gsd-discuss-phase ➜ /gsd-plan-phase ➜ /gsd-review
      │
      ▼
[Thực thi & Code] ➜ /gsd-execute-phase ➜ /gsd-quick ➜ /gsd-fast
      │
      ▼
[Đảm bảo Chất lượng] ➜ /gsd-verify-work ➜ /gsd-code-review ➜ /gsd-ui-review ➜ /gsd-secure-phase
      │
      ▼
[Phát hành & Đóng gói] ➜ /gsd-pr-branch ➜ /gsd-ship ➜ /gsd-complete-milestone [Kết thúc Milestone]
```

---

## 🗂️ CHI TIẾT CÁC CÂU LỆNH THEO TIẾN TRÌNH DỰ ÁN

---

### PHẦN 1: KHỞI TẠO DỰ ÁN & PHÂN TÍCH CODEBASE
*Sử dụng khi bắt đầu một dự án mới hoàn toàn hoặc khi tiếp quản một dự án cũ có sẵn code (Brownfield).*

#### 1. `/gsd-new-project`
* **Chức năng:** Khởi tạo một dự án mới hoàn toàn thông qua một luồng khảo sát thông minh và nghiên cứu sâu.
* **Quy trình hoạt động:**
  1. Đặt câu hỏi sâu để hiểu rõ ý tưởng dự án.
  2. Kích hoạt tối đa 4 tác nhân nghiên cứu độc lập (Research Agents) để khảo sát công nghệ.
  3. Định nghĩa tài liệu yêu cầu chi tiết kèm mã định danh `REQ-ID`.
  4. Tạo cấu trúc các Phase và tiêu chí đánh giá thành công.
* **Sản phẩm tạo ra:** Tạo toàn bộ cấu trúc thư mục `.planning/` gồm `PROJECT.md`, `REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md`, và `config.json`.

#### 2. `/gsd-map-codebase [--fast] [--focus <area>] [--query <term>]`
* **Chức năng:** Bản đồ hóa codebase có sẵn (sử dụng khi tiếp quản dự án cũ).
* **Các tham số:**
  * `--fast`: Đánh giá nhanh và nhẹ nhàng toàn bộ cấu trúc (thay thế lệnh `gsd-scan` cũ).
  * `--focus <khu_vực>` : Giới hạn phạm vi quét vào một module hoặc thư mục cụ thể.
  * `--query <từ_khóa>` : Truy vấn nhanh cơ sở tri thức kỹ thuật của dự án (thay thế lệnh `gsd-intel` cũ).
* **Sản phẩm tạo ra:** Tạo thư mục `.planning/codebase/` gồm 7 tài liệu chi tiết: `STACK.md`, `ARCHITECTURE.md`, `STRUCTURE.md`, `CONVENTIONS.md`, `TESTING.md`, `INTEGRATIONS.md`, và `CONCERNS.md`.

#### 3. `/gsd-ingest-docs [đường_dẫn] [--mode new|merge] [--manifest <file>]`
* **Chức năng:** Đọc và đồng bộ hóa các tài liệu cũ có sẵn (ADR, PRD, SPEC) vào hệ thống `.planning/` của GSD.

---

### PHẦN 2: QUẢN LÝ LỘ TRÌNH & ĐẶC TẢ SẢN PHẨM (SPECIFICATION)
*Xác định lộ trình phát triển và làm rõ thiết kế kỹ thuật, giao diện cho từng Phase trước khi lập kế hoạch code.*

#### 1. `/gsd-phase <mô_tả>`
* **Chức năng:** Quản lý cấu trúc các Phase trong `ROADMAP.md`.
* **Cách dùng mở rộng:**
  * `/gsd-phase "Tạo màn hình thanh toán"`: Thêm một phase mới vào cuối Milestone hiện tại.
  * `/gsd-phase --insert <after_phase_num> "<mô_tả>"`: Chèn một phase khẩn cấp (dạng thập phân, ví dụ: Phase 7.1) vào giữa các phase có sẵn.
  * `/gsd-phase --remove <phase_num>`: Xóa một phase trong tương lai và tự động đánh số lại các phase phía sau.
  * `/gsd-phase --edit <phase_num> [--force]`: Chỉnh sửa trực tiếp thông tin của một phase.

#### 2. `/gsd-spec-phase <phase> [--auto] [--text]`
* **Chức năng:** Làm rõ **CÁI GÌ** sẽ được bàn giao trong phase này bằng cách chấm điểm độ mơ hồ và tạo tài liệu `SPEC.md`.

#### 3. `/gsd-ai-integration-phase [phase]`
* **Chức năng:** Tạo hợp đồng thiết kế hệ thống AI (`AI-SPEC.md`) cho các phase có tích hợp AI, định nghĩa rõ ràng cấu trúc prompt, mô hình sử dụng, và chiến lược xử lý lỗi.

#### 4. `/gsd-ui-phase [phase]`
* **Chức năng:** Tạo hợp đồng thiết kế giao diện (`UI-SPEC.md`) cho các phase có phát triển Frontend, đảm bảo tuân thủ thiết kế, layout, màu sắc và typography.

#### 5. `/gsd-import --from <đường_dẫn>`
* **Chức năng:** Nhập các kế hoạch bên ngoài và kiểm tra xung đột với các quyết định kiến trúc hiện có trước khi ghi dữ liệu.

---

### PHẦN 3: THẢO LUẬN & LẬP KẾ HOẠCH CHI TIẾT (PLANNING)
*Lên kế hoạch thực thi chi tiết cho một Phase cụ thể trước khi viết code.*

#### 1. `/gsd-discuss-phase <phase> [--chain | --analyze | --power] [--batch[=N]]`
* **Chức năng:** Thảo luận, thu thập ý kiến và định hình cách thức hoạt động của Phase.
* **Sản phẩm tạo ra:** Tài liệu `CONTEXT.md` lưu trữ toàn bộ tầm nhìn, những điều thiết yếu và ranh giới không được phạm phải.
* **Tham số nổi bật:** `--batch=3` (Hỏi gộp 3 câu hỏi liên quan cùng lúc thay vì hỏi từng câu một để tiết kiệm thời gian).

#### 2. `/gsd-plan-phase <phase> [--skip-research] [--gaps] [--skip-verify] [--tdd] [--mvp]`
* **Chức năng:** Lên kế hoạch thực thi chi tiết, bóc tách công việc thành các tác vụ nhỏ có thể thực thi.
* **Sản phẩm tạo ra:** File kế hoạch `XX-YY-PLAN.md` (ví dụ: `01-01-PLAN.md`) nằm trong thư mục của Phase tương ứng.
* **Tham số nổi bật:**
  * `--gaps`: Chỉ tập trung lên kế hoạch sửa chữa các khoảng trống/lỗi được phát hiện từ đợt kiểm tra trước đó.
  * `--tdd`: Lên kế hoạch theo trình tự ưu tiên viết Test trước khi viết code.

#### 3. `/gsd-review --phase <phase> [--all] [--gemini] [--claude]`
* **Chức năng:** Kích hoạt đánh giá chéo kế hoạch bằng cách gửi `PLAN.md` cho các AI CLI khác nhau chạy độc lập nhằm tìm ra kẽ hở hoặc rủi ro tiềm ẩn, tạo file `REVIEWS.md`.

#### 4. `/gsd-plan-review-convergence <phase> [--all] [--max-cycles N]`
* **Chức năng:** Vòng lặp tự động sửa đổi kế hoạch dựa trên phản hồi của các AI đánh giá chéo cho đến khi không còn lỗi nghiêm trọng nào được phát hiện.

#### 5. `/gsd-ultraplan-phase [phase]`
* **Chức năng:** [BETA] Chuyển tác vụ lên kế hoạch chi tiết lên dịch vụ đám mây Ultraplan của Claude Code và tải kết quả đã tối ưu về.

---

### PHẦN 4: THỰC THI & CODE (EXECUTION)
*Quá trình viết mã nguồn thực tế dựa trên kế hoạch đã duyệt.*

#### 1. `/gsd-execute-phase <phase> [--wave N] [--gaps-only] [--tdd]`
* **Chức năng:** Chạy thực thi tự động viết code toàn bộ kế hoạch của phase.
* **Cơ chế hoạt động:** GSD tự động gom các kế hoạch thành từng "Đợt" (Wave) đồng quy và thực thi song song để tối đa hóa hiệu suất mà không bị xung đột code.
* **Tham số:**
  * `--wave N`: Chỉ chạy đợt thực thi số N.
  * `--gaps-only`: Chỉ thực thi các phần việc bị đánh dấu là lỗi/thiếu hụt từ đợt chạy trước.

#### 2. `/gsd-quick [--full] [--validate] [--discuss] [--research]`
* **Chức năng:** Lập kế hoạch và thực thi ngay lập tức các task nhỏ nằm ngoài lộ trình chính (Ad-hoc task). Các file kế hoạch của lệnh này được lưu riêng tại `.planning/quick/` để tránh làm bẩn Roadmap chính.
* **Cách dùng:** `/gsd-quick "Thêm cột ghi chú vào bảng cơ sở dữ liệu"`.

#### 3. `/gsd-fast [mô_tả]`
* **Chức năng:** Giải quyết các việc cực nhỏ, hiển nhiên (Sửa lỗi chính tả, đổi config, commit file bị sót...) một cách trực tiếp ngay tại luồng chat hiện tại mà không tạo file kế hoạch `PLAN.md` hay `SUMMARY.md`, tự động tạo commit nguyên tử và log vào `STATE.md`.
* **Cách dùng:** `/gsd-fast "Đổi tên biến màu từ red sang primaryRed trong file config"`.

---

### PHẦN 5: KIỂM THỬ & ĐẢM BẢO CHẤT LƯỢNG (QUALITY & VERIFICATION)
*Đảm bảo code chạy đúng, sạch, bảo mật và đáp ứng đầy đủ yêu cầu trước khi đóng phase.*

#### 1. `/gsd-verify-work [phase]` (UAT)
* **Chức năng:** Chạy quy trình nghiệm thu người dùng (User Acceptance Testing) thông qua hội thoại tương tác.
* **Cơ chế hoạt động:** GSD trích xuất các tính năng cần kiểm thử từ `SUMMARY.md`, đưa ra từng bài kiểm tra để bạn xác nhận. Nếu phát hiện lỗi, GSD tự động phân tích nguyên nhân gốc rễ và chuẩn bị kế hoạch sửa lỗi.

#### 2. `/gsd-code-review <phase> [--depth=quick|standard|deep] [--fix]`
* **Chức năng:** Đánh giá chất lượng toàn bộ các file code đã thay đổi trong phase nhằm phát hiện bug, lỗ hổng bảo mật và đề xuất sửa đổi tối ưu.

#### 3. `/gsd-ui-review [phase]`
* **Chức năng:** Thực hiện kiểm tra trực quan giao diện theo 6 trụ cột cốt lõi của Frontend để đảm bảo thẩm mỹ tối cao.

#### 4. `/gsd-secure-phase [phase]`
* **Chức năng:** Rà soát và xác minh xem các biện pháp giảm thiểu mối đe dọa bảo mật đã được áp dụng đúng chuẩn chưa.

#### 5. `/gsd-validate-phase [phase]`
* **Chức năng:** Kiểm tra và lấp đầy các lỗ hổng xác thực dữ liệu kỹ thuật toán học (Nyquist validation) trong hệ thống code.

#### 6. `/gsd-eval-review [phase]`
* **Chức năng:** Đánh giá chất lượng và độ bao phủ của các bộ kiểm thử đánh giá AI, tạo tài liệu khắc phục `EVAL-REVIEW.md`.

#### 7. `/gsd-add-tests <phase> [hướng_dẫn_thêm]`
* **Chức năng:** Tự động tạo thêm các bộ kiểm thử tự động (Unit Test, Integration Test) dựa trên tiêu chí nghiệm thu UAT của phase.

---

### PHẦN 6: PHÁT HÀNH & ĐÓNG GÓI MILESTONE
*Đóng gói sản phẩm của một Phase hoặc toàn bộ Milestone để phát hành thực tế.*

#### 1. `/gsd-pr-branch [target]`
* **Chức năng:** Tạo một nhánh Git cực sạch để tạo Pull Request bằng cách tự động lọc bỏ toàn bộ các commit liên quan đến file `.planning/` (Reviewer chỉ thấy file code thuần túy, không bị rối mắt bởi file kế hoạch của AI).

#### 2. `/gsd-ship [phase] [--draft]`
* **Chức năng:** Đẩy nhánh code lên Server và tự động tạo Pull Request trên GitHub với phần mô tả PR được tổng hợp hoàn chỉnh từ `SUMMARY.md`, `VERIFICATION.md`, và `REQUIREMENTS.md`.

#### 3. `/gsd-audit-milestone [phiên_bản]`
* **Chức năng:** Kiểm tra toàn diện sự hoàn thành của Milestone, đối chiếu độ bao phủ yêu cầu và tạo tài liệu đánh giá nợ kỹ thuật `MILESTONE-AUDIT.md`.

#### 4. `/gsd-complete-milestone <phiên_bản>`
* **Chức năng:** Đóng Milestone hiện tại, lưu trữ lịch sử sang thư mục lưu trữ `milestones/`, tạo Git tag phiên bản mới và dọn dẹp workspace chuẩn bị cho Milestone tiếp theo.

#### 5. `/gsd-milestone-summary [phiên_bản]`
* **Chức năng:** Tạo một tài liệu tóm tắt kỹ thuật cực kỳ chi tiết của Milestone phục vụ việc bàn giao hoặc onboarding thành viên mới.

---

## 🛠️ CÁC CÂU LỆNH BỔ TRỢ & QUẢN LÝ THƯỜNG TRỰC (CHẠY BẤT CỨ LÚC NÀO)

---

### NHÓM A: THEO DÕI TIẾN ĐỘ & NGỮ CẢNH (PROGRESS & CONTEXT)

#### 1. `/gsd-progress [--next | --forensic | --do "<mô_tả>"]`
* **Chức năng:** Trọng tâm theo dõi tiến độ toàn cục của GSD.
  * **Không tham số:** Hiện thanh tiến trình `%`, tổng hợp các việc đã làm gần đây, đưa ra gợi ý bước tiếp theo.
  * `--next`: Tự động nhảy sang bước tiếp theo trong quy trình phát triển.
  * `--forensic`: Chạy một bài kiểm tra tính toàn vẹn 6 điểm của toàn bộ cấu trúc thư mục kế hoạch để phát hiện sai sót.
  * `--do "<mô_tả>"`: Định tuyến thông minh, tự động chuyển đổi yêu cầu tự nhiên thành lệnh GSD tương ứng.

#### 2. `/gsd-resume-work`
* **Chức năng:** Khôi phục context khi bạn quay trở lại làm việc sau một khoảng thời gian nghỉ, đọc `STATE.md` và đề xuất hành động kế tiếp.

#### 3. `/gsd-pause-work`
* **Chức năng:** Đóng băng trạng thái hiện tại trước khi nghỉ, tạo file `.continue-here` lưu giữ các việc đang dở dang để phiên làm việc sau khôi phục chính xác.

#### 4. `/gsd-stats`
* **Chức năng:** Hiển thị thống kê trực quan về dự án (số lượng file, số commit, hiệu suất phát triển, biểu đồ phân bổ thời gian).

#### 5. `/gsd-thread [list | close <slug> | status <slug>]`
* **Chức năng:** Quản lý các luồng context lâu dài nhằm chia sẻ thông tin kỹ thuật qua lại giữa các phiên làm việc độc lập.

---

### NHÓM B: THU THẬP Ý TƯỞNG, SKETCH & PHÂN TÍCH LỖI

#### 1. `/gsd-capture [description]`
* **Chức năng:** Lưu nhanh một todo cần làm. Có thể dùng `/gsd-capture --list` để quản lý và chọn việc để xử lý.

#### 2. `/gsd-capture --seed "<ý_tưởng>"`
* **Chức năng:** "Gieo hạt" một ý tưởng dài hạn kèm theo **điều kiện kích hoạt**. Ý tưởng này sẽ ngủ yên và chỉ tự động xuất hiện lại khi dự án đi tới Phase thỏa mãn điều kiện kích hoạt.

#### 3. `/gsd-sketch [ý_tưởng] [--quick]`
* **Chức năng:** Phác thảo nhanh giao diện (UI/UX) bằng cách sinh ra 2-3 biến thể trang web HTML tĩnh trong thư mục `.planning/sketches/` để bạn so sánh và chọn ra mẫu thiết kế tối ưu nhất. Khi hoàn thành gõ `/gsd-sketch --wrap-up` để đóng gói thành Skill của tác nhân.

#### 4. `/gsd-spike [ý_tưởng] [--quick]`
* **Chức năng:** Thực hiện một cuộc thử nghiệm kỹ thuật cô lập (Spike) để kiểm tra tính khả thi của một thư viện hoặc giải pháp mới tại `.planning/spikes/`. Khi kết thúc gõ `/gsd-spike --wrap-up` để đóng gói kết luận kỹ thuật thành Skill lâu dài cho tác nhân.

#### 5. `/gsd-debug [mô_tả_lỗi] [--diagnose]`
* **Chức năng:** Khởi động phiên sửa lỗi có cấu trúc khoa học (đưa ra giả thuyết → kiểm chứng → ghi nhận kết quả). Các phiên debug dở dang sẽ tồn tại qua lệnh `/clear` và chỉ đóng lại khi lỗi thực sự được giải quyết.

#### 6. `/gsd-forensics [vấn_đề]`
* **Chức năng:** Khảo sát khám nghiệm "tử thi" khi quy trình GSD bị đổ vỡ hoặc gặp lỗi nghiêm trọng để phân tích nguyên nhân hệ thống.

#### 7. `/gsd-undo --last N | --phase NN | --plan NN-MM`
* **Chức năng:** Hoàn tác (Revert Git) một cách an toàn và có cấu trúc các commit của phase hoặc kế hoạch mà không phá hỏng cấu trúc các phần việc phụ thuộc.

#### 8. `/gsd-audit-uat`
* **Chức năng:** Quét toàn bộ hệ thống để tìm ra các bài kiểm tra UAT đang bị bỏ lửng, bị skip hoặc bị block để tạo ra danh sách nợ kiểm thử cần xử lý trước khi đóng dự án.

#### 9. `/gsd-audit-fix --source <audit-uat>`
* **Chức năng:** Quy trình tự động sửa lỗi hàng loạt dựa trên danh sách lỗi quét được từ đợt kiểm thử UAT.

---

### NHÓM C: BẢO TRÌ & CẤU HÌNH HỆ THỐNG

#### 1. `/gsd-settings`
* **Chức năng:** Bật/Tắt trực quan các tác nhân phụ trợ (Researcher, Plan Checker, Verifier) và chọn hồ sơ sử dụng mô hình.

#### 2. `/gsd-config [--profile <tên>] [--advanced] [--integrations]`
* **Chức năng:** Cấu hình nâng cao cho GSD.
  * `--profile`: Đặt cấu hình mô hình (`quality` - ưu tiên Opus tối đa, `balanced` - kết hợp Opus/Sonnet, `budget` - tiết kiệm tối đa).
  * `--advanced`: Cấu hình sâu về số lần bounce kế hoạch, timeout, định dạng branch.
  * `--integrations`: Cấu hình API Key của bên thứ ba, cài đặt bộ phân tích code review.

#### 3. `/gsd-health [--repair]`
* **Chức năng:** Kiểm tra sức khỏe hệ thống thư mục `.planning/`, phát hiện file bị mất hoặc sai cú pháp cấu trúc và tự động sửa chữa (`--repair`).

#### 4. `/gsd-cleanup`
* **Chức năng:** Tự động phát hiện các phase đã hoàn thành và dọn dẹp, lưu trữ chúng sang thư mục Milestone để làm sạch không gian làm việc của dự án.

#### 5. `/gsd-update [--sync] [--reapply]`
* **Chức năng:** Cập nhật công cụ GSD lên phiên bản mới nhất, hiển thị chi tiết lịch sử thay đổi (changelog) và đồng bộ hóa lại các patch tùy biến của bạn.

#### 6. `/gsd-workspace [--new | --list | --remove]`
* **Chức năng:** Quản lý các môi trường làm việc bị cô lập của GSD.

#### 7. `/gsd-workstreams`
* **Chức năng:** Quản lý các luồng làm việc song song trong cùng một dự án.

#### 8. `/gsd-inbox`
* **Chức năng:** Triển khai quét và tương tác trực tiếp với các GitHub Issues và PRs của repo để tích hợp thẳng vào luồng kế hoạch của GSD.

---

## 💡 MẸO SỬ DỤNG GSD HIỆU QUẢ CAO

1. **Luôn kiểm tra tiến độ bằng `/gsd-progress`:** Đây là chiếc la bàn giúp bạn không bao giờ bị lạc lối trong dự án. Nó sẽ luôn cho bạn biết bạn đang ở đâu và cần gõ lệnh gì tiếp theo.
2. **Sử dụng Smart Router khi phân vân:** Nếu bạn muốn làm gì đó mà lười nhớ lệnh cụ thể, hãy dùng `/gsd-progress --do "việc bạn muốn làm"`, AI sẽ tự động kích hoạt lệnh tối ưu nhất cho bạn.
3. **Phát triển tính năng nhỏ bằng `/gsd-quick`:** Giúp bạn thỏa sức sáng tạo các tính năng râu ria hoặc sửa đổi nhanh mà không làm xáo trộn các số thứ tự Phase đã được bóc tách kỹ càng trên Roadmap chính.
4. **Sử dụng `/gsd-fast` cho các sửa đổi tức thời:** Khi phát hiện lỗi chính tả hoặc cần đổi một vài dòng cấu hình, đừng tạo kế hoạch phức tạp, hãy dùng `/gsd-fast` để hệ thống tự viết mã, commit và log cực kỳ tinh gọn.
