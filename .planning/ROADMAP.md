# Roadmap: LiiO EatClean

**Version:** v1.0
**Phases:** 10
**Requirements:** 45

## Milestone 1: v1.0 — MVP Calorie Tracker

### Phase 1: Project Foundation & Data Layer
**Goal:** Xcode project chạy được với CoreData schema + Repository pattern + tab navigation skeleton
**Requirements:** FOUND-01, FOUND-02, FOUND-03, FOUND-04
**UI hint:** yes
**Depends on:** None

**Success criteria:**
1. App build và chạy trên Simulator không crash
2. CoreData schema có đủ 7 entities (User, Meal, FoodItem, MealFood, DailyLog, WeightEntry, APIKey)
3. Repository protocols defined + CoreData implementations
4. TabView 4 tabs hiển thị placeholder views
5. SwiftUI Previews hoạt động với in-memory CoreData store

---

### Phase 2: Splash + Onboarding + Goal Setup
**Goal:** User mở app → thấy splash → onboarding slides → setup mục tiêu → nhận calories/ngày
**Requirements:** ONBD-01, ONBD-02, ONBD-03, ONBD-04, ONBD-05
**UI hint:** yes
**Depends on:** Phase 1

**Success criteria:**
1. Splash screen hiển thị logo 1-2s rồi tự chuyển
2. 3 onboarding slides swipe được, có Continue + Skip buttons
3. Setup Goal 3-4 bước với progress bar, nhập weight/height/age/goal
4. Calories/ngày được tính đúng bằng Mifflin-St Jeor (bounds: min 1200)
5. User data lưu vào CoreData qua UserRepository

---

### Phase 3: Home Dashboard
**Goal:** Dashboard trung tâm app với calories ring, meals summary, nút Add Meal
**Requirements:** DASH-01, DASH-02, DASH-03, DASH-04, DASH-05
**UI hint:** yes
**Depends on:** Phase 2

**Success criteria:**
1. Header hiển thị "Hello, LiiO" + calories consumed/target
2. Animated progress ring hiển thị đúng tỷ lệ calories
3. Breakfast/Lunch/Dinner cards hiển thị calories từng bữa (hoặc empty state)
4. Nút Add Meal nổi bật, tap → navigate đến Add Meal screen
5. Dashboard refresh khi quay lại từ Add Meal

---

### Phase 4: Food Database (Hybrid Search)
**Goal:** User search được món ăn với kết quả instant từ local + API fallback
**Requirements:** FOOD-01, FOOD-02, FOOD-03, FOOD-04
**UI hint:** yes
**Depends on:** Phase 1

**Success criteria:**
1. vietnamese_foods.json có ít nhất 50 món Việt với calories chính xác
2. CalorieNinjas API integration hoạt động (search → parse → display)
3. Search flow: local first (< 100ms) → API fallback → cache results
4. Search UI có debounce 300ms, loading indicator, empty/error states
5. Recent/frequent foods hiển thị ở top search

---

### Phase 5: Meal Logging (Core Loop)
**Goal:** User log được bữa ăn đầy đủ: search → chọn food → save → dashboard update
**Requirements:** MEAL-01, MEAL-02, MEAL-03, MEAL-04, MEAL-05, MEAL-06
**UI hint:** yes
**Depends on:** Phase 3, Phase 4

**Success criteria:**
1. Add Meal: chọn meal type + search food + set quantity → Save
2. Save meal → DailyLog totalCalories cập nhật đúng
3. Dashboard progress ring update ngay sau save
4. Meals list hiển thị tất cả bữa ăn hôm nay theo cards
5. Tap card → meal detail view
6. Edit/delete meal hoạt động, dashboard refresh sau thay đổi

---

### Phase 6: Progress & Weight Tracking
**Goal:** User xem được tiến trình giảm cân qua biểu đồ đẹp
**Requirements:** PROG-01, PROG-02, PROG-03, PROG-04
**UI hint:** yes
**Depends on:** Phase 1

**Success criteria:**
1. Weight logging form: nhập kg, lưu theo ngày
2. Weight chart (Swift Charts): LineMark + PointMark + goal RuleMark
3. Weekly/Monthly toggle thay đổi chart range
4. Calorie history hiển thị trend theo ngày

---

### Phase 7: Profile + AI Meal Suggestions
**Goal:** Profile management + AI gợi ý bữa ăn thông minh ưu tiên món Việt
**Requirements:** PROF-01, PROF-02, PROF-03, PROF-04, AI-01, AI-02, AI-03, AI-04
**UI hint:** yes
**Depends on:** Phase 5

**Success criteria:**
1. Profile hiển thị đúng thông tin cá nhân, edit được
2. Goal editing → recalculate daily calories
3. API key management: add/remove keys, lưu vào CoreData
4. AI suggest: input remaining calories → output 2 meals (JSON parsed)
5. Multi-key rotation: key fail → auto swap → retry
6. Fallback UI khi tất cả keys fail hoặc no keys configured

---

### Phase 8: Water Tracking + Smart Reminders + Polish
**Goal:** Hoàn thiện app với water tracking, notifications, UI polish
**Requirements:** WATR-01, WATR-02, RMND-01, RMND-02
**UI hint:** yes
**Depends on:** Phase 3

**Success criteria:**
1. Water intake logging (ml) theo ngày, visual progress
2. Water display trên Dashboard hoặc dedicated section
3. Local notification reminders cho meal logging
4. Configurable reminder timing trong Settings
5. UI polish: animations, transitions, dark mode support

---

### Phase 9: AI Nutritionist Chatbox
**Goal:** Chatbox AI chuyên gia dinh dưỡng: hiểu sâu về app, phân tích thói quen người dùng và tư vấn lộ trình ăn uống cá nhân hóa.
**Requirements:** CHAT-01, CHAT-02, CHAT-03, CHAT-04, CHAT-05
**UI hint:** yes
**Depends on:** Phase 7, Phase 8

**Success criteria:**
1. Giao diện Chatbot mượt mà, hỗ trợ định dạng markdown (bold, list) để tư vấn rõ ràng.
2. AI đóng vai trò chuyên gia, trả lời đúng trọng tâm về dinh dưỡng và lộ trình ăn uống.
3. AI có khả năng giải thích các tính năng app (VD: "Làm sao để log bữa sáng?", "Mục tiêu calories của tôi là bao nhiêu?").
4. AI tự động truy vấn dữ liệu thói quen (lịch sử ăn uống, cân nặng) để đưa ra lời khuyên cá nhân hóa.
5. Gợi ý món ăn thông minh dựa trên sở thích và calories còn lại trong ngày.

---

### Phase 10: AI-Powered Meals Tab — Smart Suggestions, Memory & Actionable AI
**Goal:** Xây dựng Meals tab thông minh với AI trợ lý dinh dưỡng: gợi ý bữa ăn cá nhân hóa dựa trên calo/sở thích/bệnh lý, persistent memory system, context injection, structured output với khả năng log meal trực tiếp, và learning system tự trích xuất thông tin từ hành vi người dùng.
**Requirements:** AIMEAL-01, AIMEAL-02, AIMEAL-03, AIMEAL-04, AIMEAL-05, AIMEAL-06, AIMEAL-07
**UI hint:** yes
**Depends on:** Phase 5, Phase 7, Phase 9

**Success criteria:**
1. Memory System: Lưu trữ persistent user memory (sở thích, bệnh lý, kiêng cữ, ghi chú) tách biệt khỏi chat history, tồn tại khi reset chat.
2. Context Builder: Inject đúng dữ liệu cần thiết theo ngữ cảnh câu hỏi (calo + sở thích cho gợi ý, bệnh lý cho tư vấn sức khỏe), không gửi toàn bộ data mỗi lần.
3. AI gợi ý bữa ăn thông minh dựa trên: calo còn lại, sở thích, kiêng cữ, bệnh lý — trả về structured output (JSON) để render UI cards.
4. Actionable AI: Mỗi gợi ý có nút "Log Meal" để lưu trực tiếp vào meal log mà không cần rời Meals tab.
5. Learning System: AI tự phân tích chat để trích xuất bệnh mới, sở thích, kiêng cữ → xác nhận với user → lưu vào memory.
6. AI không đưa chẩn đoán y khoa, luôn ưu tiên món user thích, không gợi ý món kiêng.
7. Tối ưu token usage: memory + context injection giảm thiểu dữ liệu gửi đi, tránh lag.

---
*Roadmap created: 2026-04-29*
*Last updated: 2026-05-04 after Phase 10 addition*
