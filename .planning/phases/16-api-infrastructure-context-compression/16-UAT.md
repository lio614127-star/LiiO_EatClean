# Phase 16 UAT: API Infrastructure & Context Compression

- **Status:** Complete
- **Last Update:** 2026-05-08

## Test Cases

| ID | Title | Method | Success Criteria | Result |
|----|-------|--------|------------------|--------|
| UAT-16-1 | API Key Manager UI | Manual | User can open Manager from Profile, add a key, and see its "Hoạt động" status. | [x] |
| UAT-16-2 | Drag-to-Reorder Priority | Manual | Reordering keys in the Manager list persists (check by reopening). | [x] |
| UAT-16-3 | API Key Deletion | Manual | Deleting a key in Manager removes it from the list and storage. | [x] |
| UAT-16-4 | Context Compression (History) | Manual/Log | Chatting > 10 messages works without token errors (older history is compressed). | ⚠️ issue |
| UAT-16-5 | Auto-Swap Fallback | Manual/Simulated | If the primary key is invalid (simulated by using a fake key), system swaps to backup. | [x] |
| UAT-16-6 | Parallel Weekly Plan | Manual | Generating a 7-day plan works faster/reliably using multiple keys (TaskGroup). | [x] |

## Evidence
- (To be populated during testing)

## Issues Found
- **UAT-16-4 (major)**: Khi AI gợi ý món ăn (action: suggest_meal), JSON response block bị hiển thị thô ra chat bubble thay vì được parse và ẩn đi. User nhìn thấy raw JSON `{ "action": "suggest_meal", "items": [...] }` trong tin nhắn. Context compression hoạt động tốt (>10 tin nhắn không lỗi token).
