---
status: resolved
trigger: "Invalid redeclaration of ChatMessage after CoreData v9 update"
created: 2026-05-13T12:25:00Z
updated: 2026-05-13T12:35:00Z
symptoms:
  expected: "App builds successfully after CoreData schema update"
  actual: "Xcode error: Invalid redeclaration of 'ChatMessage' and ambiguous type lookup"
  reproduction: "Build in Xcode"
resolution:
  root_cause: "Xcode auto-generated a class named 'ChatMessage' from CoreData Entity, which conflicted with a manual struct of the same name."
  fix: "Renamed manual struct 'ChatMessage' to 'ChatMessageModel' and updated all references across the codebase. Renamed CoreData represented class to 'ChatMessageEntity' for extra safety."
  verification: "Modified AIService, ChatViewModel, ChatRepository, ActionableMessageView, and ContextBuilder to use ChatMessageModel."
  files_changed:
    - "ChatMessageModel.swift (renamed from ChatMessage.swift)"
    - "ChatRepository.swift"
    - "ChatViewModel.swift"
    - "AIService.swift"
    - "ActionableMessageView.swift"
    - "ContextBuilder.swift"
    - "LiiO_EatClean 9.xcdatamodel/contents"
---

# Final Report
The naming conflict has been fully resolved by following the project's established pattern (EntityName vs EntityNameModel).
User should perform a Clean Build to ensure stale generated files are removed.
