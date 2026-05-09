# Phase 21: Hybrid Planning & Structured Data Layer - Research

**Researched:** 2026-05-09
**Domain:** Nutrition Engine Architecture & Structured Data
**Confidence:** HIGH

## Summary

Phase 21 tập trung vào việc tối ưu hóa hiệu năng lập kế hoạch (Hybrid Planning) và nâng cấp độ sâu của dữ liệu thực phẩm (Structured Meal). Qua nghiên cứu, chúng ta sẽ áp dụng mô hình **Single-pass Matchmaker** cho AI để giảm latency xuống <10s và sử dụng **CoreData Lightweight Migration** kết hợp với **NSEntityMigrationPolicy** để nâng cấp lớp dữ liệu mà không làm gián đoạn trải nghiệm người dùng.

**Primary recommendation:** Sử dụng Foundation `Measurement` API cho lớp chuyển đổi đơn vị và triển khai Diversity Engine dựa trên trọng số (Weighted Multi-Criteria Optimization) tại Local trước khi gửi Candidate Pool cho AI.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **Slot-based Pool Sizes:** Bữa sáng (12-15), Trưa/Tối (18-25), Snack (8-12).
- **Diversity Engine Rules:** Chặn trùng lặp nguyên liệu/style/carb (Max 2 món/nhóm).
- **Scoring System:** Triển khai bộ 3 trọng số: `VietnamesePriority`, `Availability`, `PrepTime`.
- **Entity mới `MealComponent`:** Phân rã `FoodItem` thành các thành phần cụ thể.
- **Substitute Groups:** Cho phép swap nguyên liệu cùng nhóm (vd: lean fish) tức thì.
- **Pair-Unit Display:** Hiển thị song song đơn vị dân dã và gram quy đổi: "1 chén (~200g)".
- **Portion Confidence:** Chấp nhận sai số lâm sàng (Phở ±15%, Cơm ±5%).
- **3-Level Swap Hierarchy:** Local Swap (<0.3s) -> Smart Refresh (2-5s) -> Full Rebuild.
- **Recency Penalty Score:** Sử dụng `RecentMealUsage` để chống trùng món.

### the agent's Discretion
- Chi tiết thuật toán Diversity Scoring.
- Cách thức lưu trữ và mapping `FoodPortionProfile`.
- Phương án CoreData Migration cụ thể.

### Deferred Ideas (OUT OF SCOPE)
- Grocery List generation.
- Social sharing của structured recipes.
- Cloud sync cho custom portion profiles.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PLAN-01 | Hybrid Planning logic | Single-pass Matchmaker pattern [VERIFIED] |
| PLAN-02 | Candidate Pool Generation | Local pre-filtering & diversity rules [VERIFIED] |
| MEAL-01 | Structured Meal Schema | CoreData Entity Migration Strategy [VERIFIED] |
| UNIT-01 | Smart Unit Conversion | Foundation Measurement API + Density Map [VERIFIED] |
| SWAP-01 | Instant Local Swap | SubstituteGroup-based replacement [VERIFIED] |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Calorie Split | App (ViewModel) | — | Logic nghiệp vụ đơn giản, không cần AI. |
| Candidate Selection | App (Repository) | AI (Selection) | App lọc theo constraint cứng, AI chọn theo sở thích. |
| Unit Conversion | App (Model) | — | Foundation Measurement API xử lý nhanh tại Local. |
| Diversity Scoring | App (Service) | — | Tính toán trọng số tại Local để giảm tải cho AI. |
| Meal Generation | AI (Model) | — | Chỉ dùng để sinh món mới khi pool cạn kiệt. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Foundation | Native | Unit Conversion (Measurement) | Type-safe, hỗ trợ locale VN tốt. |
| CoreData | Native | Persistence & Migration | Hỗ trợ Lightweight Migration mượt mà. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| OpenAI/Gemini SDK | Latest | Single-pass AI Orchestration | Đã tích hợp sẵn trong AIService. |

## Architecture Patterns

### System Architecture Diagram
1. **Input:** User nhấn "Generate Plan" + Target Calories.
2. **Step 1 (App):** Calculate Meal Split (Sáng 25%, Trưa 35%, ...)
3. **Step 2 (App):** Query Candidate Pool từ `FoodRepository` (Favorites, Recent, Popular).
4. **Step 3 (App):** Áp dụng Diversity Engine (Lọc trùng ingredient/style) + Penalty Score.
5. **Step 4 (AI):** Gửi Candidate Pool (~50 món) + Constraints cho AI.
6. **Step 5 (AI):** AI trả về JSON Selection.
7. **Step 6 (App):** Save to CoreData as Structured Meals.

### Pattern 1: Diversity Scoring (Weighted Multi-Criteria)
**What:** Sử dụng công thức trọng số để xếp hạng các ứng viên trước khi gửi cho AI.
**Formula:** `FinalScore = (VietnameseScore * 0.4) + (AvailabilityScore * 0.3) + (PrepTimeScore * 0.3) - (RecencyPenalty)`
**Recency Penalty:** `Penalty = 1.0 / (daysSinceLastEaten + 1)`.

### Pattern 2: CoreData Migration (Lightweight + Policy)
**What:** Thêm entity `MealComponent` và tạo quan hệ 1-n với `FoodItem`.
**Implementation:**
- Sử dụng **Model Versioning** trong Xcode.
- Nếu cần chuyển dữ liệu `FoodItem` cũ sang `MealComponent` đầu tiên, dùng `NSEntityMigrationPolicy` để map `FoodItem.name` -> `MealComponent.name`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Unit Conversion | Custom multiplier logic | Foundation `Measurement` | Xử lý tốt các đơn vị phức tạp và locale. |
| AI Selection Loop | Master Planner agent | Single AI Pass | Giảm latency, tiết kiệm token, tránh loop vô tận. |

## Common Pitfalls

### Pitfall 1: Token Overflow
**What goes wrong:** Gửi Candidate Pool quá lớn khiến AI bị nhiễu hoặc vượt limit.
**How to avoid:** Giới hạn pool ở mức <25 món/bữa (tổng <60 món/ngày).

### Pitfall 2: CoreData Relationship Deadlock
**What goes wrong:** Migration thất bại do inverse relationship không được set đúng.
**How to avoid:** Luôn định nghĩa `inverse` relationship trong CoreData model.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest |
| Config file | LiiO_EatCleanTests.swift |
| Quick run command | `cmd+U` in Xcode |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command |
|--------|----------|-----------|-------------------|
| PLAN-01 | Latency < 10s | Performance | XCTPerformanceMetric |
| UNIT-01 | Gram conversion | Unit | `testUnitConversion()` |
| MEAL-01 | Migration success | Integration | `testCoreDataMigration()` |

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | yes | `Codable` validation cho AI JSON response. |

### Known Threat Patterns for AI
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Prompt Injection | Tampering | Chặn các từ khóa điều hướng hệ thống trong Candidate Pool. |

## Sources
- Apple Foundation Measurement Documentation [HIGH]
- Core Data Migration Guide [HIGH]
- Meal Planning Algorithm Research [MEDIUM]

## Metadata
- Standard stack: HIGH - Native Swift APIs.
- Architecture: HIGH - Hybrid model reduces AI dependency.
- Pitfalls: MEDIUM - Cần theo dõi token usage thực tế.

**Research date:** 2026-05-09
**Valid until:** 2026-06-08
