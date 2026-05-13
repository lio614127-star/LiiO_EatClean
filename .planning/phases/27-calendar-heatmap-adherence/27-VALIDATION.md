---
phase: 27
slug: calendar-heatmap-adherence
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-13
---

# Phase 27 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest |
| **Config file** | none — using LiiO_EatCleanTests target |
| **Quick run command** | `xcodebuild test -scheme LiiO_EatClean -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:LiiO_EatCleanTests/DailyAdherenceSnapshotServiceTests` |
| **Full suite command** | `xcodebuild test -scheme LiiO_EatClean -destination 'platform=iOS Simulator,name=iPhone 15'` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run `xcodebuild test ...` for affected service.
- **After every plan wave:** Run full test suite.
- **Before `/gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** 120 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 27-01-01 | 01 | 1 | HEAT-01 | — | N/A | unit | `xcodebuild test ...` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `LiiO_EatCleanTests/DailyAdherenceSnapshotServiceTests.swift` — unit tests for snapshot logic.
- [ ] `LiiO_EatCleanTests/Mocks/MockMealRepository.swift` — mock for testing service.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Heatmap Color Rendering | HEAT-01 | Visual validation | Open Progress -> Adherence tab. Verify colors match score levels. |
| Deep-link Navigation | HEAT-03 | Interaction flow | Tap a day in Heatmap -> Tap "Xem Journal". Verify it navigates to Meals tab with correct date. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
