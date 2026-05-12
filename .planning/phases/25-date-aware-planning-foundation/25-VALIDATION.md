---
phase: 25
slug: date-aware-planning-foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-12
---

# Phase 25 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | xcodebuild / XCTest |
| **Config file** | none — using standard iOS test targets |
| **Quick run command** | `xcodebuild test -project LiiO_EatClean.xcodeproj -scheme LiiO_EatClean -destination 'platform=iOS Simulator,name=iPhone 15 Pro'` |
| **Full suite command** | `xcodebuild test -project LiiO_EatClean.xcodeproj -scheme LiiO_EatClean -destination 'platform=iOS Simulator,name=iPhone 15 Pro'` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run build check `xcodebuild build ...`
- **After every plan wave:** Run `xcodebuild test ...`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 45 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 25-01-01 | 01 | 1 | PLAN-04 | — | N/A | manual | xcodebuild | ✅ | ⬜ pending |
| 25-01-02 | 01 | 1 | PLAN-05 | — | N/A | manual | xcodebuild | ✅ | ⬜ pending |
| 25-01-03 | 01 | 2 | PLAN-06 | — | N/A | manual | xcodebuild | ✅ | ⬜ pending |
| 25-01-04 | 01 | 2 | PLAN-07 | — | N/A | manual | xcodebuild | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Create new DailyPlan for selected date | PLAN-05 | CoreData integration requires simulator runtime | Launch app, select tomorrow's date, ensure a new empty plan is created, confirm in DB. |
| Retrieve old DailyPlan | PLAN-07 | Requires historic data entry | Log plan for yesterday, restart app, select yesterday, ensure plan is loaded. |
| Save Drafts correctly | PLAN-04/05 | Lifecycle handling | Request AI generation, close app before saving, reopen, ensure draft is offered. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 45s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
