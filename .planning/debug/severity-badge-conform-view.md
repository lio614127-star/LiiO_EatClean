---
status: resolved
trigger: "Type '()' cannot conform to 'View' in AICoachingCardView.swift"
symptoms:
  expected: "severityBadge should return a Text view with dynamic colors."
  actual: "Compilation error: Type '()' cannot conform to 'View' at line 58."
  error_messages: "Type '()' cannot conform to 'View'"
  timeline: "Occurred after implementing Phase 24 coaching card UI."
  reproduction: "Build the LiiO_EatClean project."
root_cause: "Assignment logic inside @ViewBuilder switch statement returned (), which is not a valid View."
fix: "Refactored the color and text logic into a separate computed property 'badgeInfo' and used it in 'severityBadge' to return a valid View."
verification: "Compilation passed in Xcode."
---

# Current Focus
- hypothesis: "The switch statement in the @ViewBuilder is performing assignments instead of returning views, causing it to return () which is not a View."
- next_action: "Read AICoachingCardView.swift to confirm the implementation and fix the logic."

# Evidence
- timestamp: 2026-05-11T16:01:00Z
  observation: "Screenshot shows line 58 with error inside a switch statement in a @ViewBuilder."

# Eliminated Hypotheses
(None yet)
