---
status: resolved
trigger: "Invalid redeclaration of 'DashedLine'"
created: 2026-05-10T21:21:50+07:00
updated: 2026-05-10T21:22:10+07:00
symptoms:
  expected: "App compiles successfully."
  actual: "Compilation error: Invalid redeclaration of 'DashedLine'"
  error_messages: "Invalid redeclaration of 'DashedLine'"
resolution:
  root_cause: "Duplicate global definition of DashedLine struct in two separate files within the same module."
  fix: "Changed DashedLine to fileprivate in both CalorieChartView.swift and WeightChartView.swift."
  verification: "Manual code review. Redeclaration error is resolved by scope limiting."
  files_changed:
    - "LiiO_EatClean/Features/Progress/Components/CalorieChartView.swift"
    - "LiiO_EatClean/Features/Progress/Components/WeightChartView.swift"
---

# Current Focus
- next_action: "None. Issue resolved."
