status: resolved
trigger: "AI using PAID key for daily plan and showing too many Activity boards (4 instead of batched)."
root_cause: "AIOrchestrator sorting logic preferred PAID keys always, and AIActivityOverlay was showing all activities including those handled by specific sheets."
fix: "Updated AIOrchestrator to prefer FREE keys for daily tasks and cap parallel tasks at 2. Updated AIActivityOverlay to filter out internal planning activities."
verification: "Daily plans use FREE keys first, only 2 activity boards shown inside the sheet, and no redundant overlay on the Meals tab."
files_changed:
  - "/Users/liio/TooL_LiiO/LiiO_EatClean/LiiO_EatClean/Features/AI/AIOrchestrator.swift"
  - "/Users/liio/TooL_LiiO/LiiO_EatClean/LiiO_EatClean/Features/AI/Components/AIActivityOverlay.swift"

# Current Focus
- hypothesis: "RESOLVED"
- next_action: "COMPLETED"
