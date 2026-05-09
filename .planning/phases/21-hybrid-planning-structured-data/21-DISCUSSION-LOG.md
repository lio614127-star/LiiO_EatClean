# Phase 21 Discussion Log: Hybrid Planning & Structured Data Layer

**Date:** 2026-05-09
**Participants:** Antigravity (AI), User (Visionary)

## Discussion Points

### Area 1: Candidate Selection & Diversity Engine
- **Proposed:** 15-20 candidates/meal.
- **Decision:** Optimized counts per slot (Breakfast: 12-15, Lunch/Dinner: 18-25, Snack: 8-12).
- **Decision:** Implemented **Diversity Engine** rules: Max 2 repetition for main ingredient, cooking style, and carb base.
- **Decision:** Multi-score ranking: VietnamesePriority, Availability, PrepTime.

### Area 2: Structured Meal & MealComponent
- **Proposed:** Separate entity for ingredients.
- **Decision:** `MealComponent` entity implemented with full metadata (`substituteGroup`, `cookingMethod`).
- **Decision:** Lean architecture allowing instant swaps (e.g., swapping fish types) locally without AI.

### Area 3: Smart Units & FoodPortionProfile
- **Proposed:** Gram conversion in food profile.
- **Decision:** **Pair-Unit Display**: "Primary Unit (~Secondary Unit in grams)" e.g., "1 chén (~200g)".
- **Decision:** **Portion Confidence**: Acknowledging clinical ranges (±5% to ±15%) instead of rigid precision.
- **Decision:** Auto-suggested units based on food category.

### Area 4: 3-Level Swap & Memory
- **Proposed:** Limit swaps to candidate pool for speed.
- **Decision:** **3-Level Hierarchy**:
    1. Instant Local Swap (<0.3s)
    2. Smart Refresh (AI - 2-5s)
    3. Full AI Rebuild (10s+)
- **Decision:** **Recency Penalty Score**: Track usage frequency to enforce variety and penalize recent items (blacklist logic).

## Deferred Ideas
- Grocery List integration (Phase 22+)
- Social sharing for structured recipes.
- CloudKit sync for custom profiles.

## Commit Metadata
- **Milestone:** v1.3
- **Phase:** 21
- **Focus:** Performance & Data Depth
