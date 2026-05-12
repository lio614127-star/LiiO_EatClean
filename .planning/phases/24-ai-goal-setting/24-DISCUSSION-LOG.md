# Phase 24 Discussion Log: AI Goal Setting

## Participants
- USER (Product Architect)
- AI (Implementation Specialist)

## Key Discussion Points

### Topic: Autonomy vs. Control
- **User:** AI shouldn't auto-modify profile. It feels toxic and reduces trust.
- **AI:** Agreed. We will implement Level 1 (Collaborative) first. AI proposes, user applies.
- **Decision:** Use a "Coaching Card" for suggestions. AI explains reasoning.

### Topic: Metabolism vs. Math
- **User:** AI is bad at math. Math must be deterministic.
- **AI:** Correct. AI will only be the communication layer. The "Brain Stem" (Engines) will be hardcoded Swift logic.
- **Decision:** TDEE calculations, Plateau detection, and Adherence scores are deterministic. AI translates the result `{adjustment: -100, reason: "plateau"}` into human coach language.

### Topic: Data Noise (The "Plateau" Problem)
- **User:** Weight is noisy (water, sodium, cycles).
- **AI:** We need a Data Reliability Layer to filter out the noise.
- **Decision:** Use Rolling Averages (7d/14d) and Reliability scores. Don't react to single-day weight spikes.

### Topic: Historical Accuracy
- **User:** Charts need accurate target lines.
- **AI:** We need a Snapshot Timeline (GoalHistory) that stores context at the time of the change.
- **Decision:** GoalHistory will be a versioned snapshot. Implement a Projection Cache Layer for chart performance.

### Topic: Non-toxic Coaching
- **User:** Avoid "punishing" calories after cheat days.
- **AI:** Use "Weekly Flex Budget" and soft coaching language instead of hard calorie subtractions.
- **Decision:** Focus on recovery and long-term adherence rather than short-term restriction.
