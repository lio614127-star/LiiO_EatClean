---
phase: 30
plan: 2
subsystem: Voice Engine
tags: [manager, state-machine, audio-gate]
requires: [30-PLAN-1]
provides: [GlobalVoiceAssistantManager]
affects: [LiiO_EatCleanApp, SpeechRecognitionService]
tech-stack:
  added: [AVAudioEngine Input Tap]
  patterns: [Singleton, Observer Pattern, Audio Level Gating]
key-files:
  created:
    - LiiO_EatClean/Services/GlobalVoiceAssistantManager.swift
  modified:
    - LiiO_EatClean/Services/SpeechRecognitionService.swift
    - LiiO_EatClean/App/LiiO_EatCleanApp.swift
key-decisions:
  - "Sử dụng AVAudioEngine Input Tap để monitor audio level liên tục mà không cần chạy SFSpeech, giúp tiết kiệm pin."
  - "Áp dụng ngưỡng 0.02 RMS trong 300ms liên tục để lọc tiếng ồn trắng trước khi kích hoạt nhận diện từ khóa."
  - "Tích hợp cơ chế Anti-Self-Listen bằng cách dừng monitor khi AI đang nói và thêm cooldown 1.0s sau khi dứt câu."
  - "Quản lý vòng đời audio tập trung tại GlobalVoiceAssistantManager để tránh xung đột tài nguyên giữa các tab."
requirements-completed: [VOICE-01, VOICE-02, VOICE-04]
duration: 45 min
completed: 2026-05-13T14:52:00Z
---

# Phase 30 Plan 2: GlobalVoiceAssistantManager — State Machine & Audio Gate Summary

## Goal
Triển khai bộ não điều khiển Voice Assistant: Global Manager quản lý trạng thái, audio level gate để tối ưu pin, và cơ chế chuyển đổi thông minh giữa các chế độ lắng nghe.

## Completed Tasks
- [x] Tạo `GlobalVoiceAssistantManager` xử lý toàn bộ logic state machine và audio processing.
- [x] Mở rộng `SpeechRecognitionService` hỗ trợ `startShortSession` cho việc kiểm tra wake phrase nhanh (2-3s).
- [x] Cấu hình `LiiO_EatCleanApp` để inject `GlobalVoiceAssistantManager` và quản lý trạng thái dựa trên vòng đời ứng dụng (background/foreground).
- [x] Triển khai logic Anti-Self-Listen để AI không tự nhận diện giọng đọc của chính mình.

## Verification Results
- `GlobalVoiceAssistantManager` đã được khởi tạo và chạy thành công ở cấp ứng dụng.
- Cơ chế `onChange(of: scenePhase)` đảm bảo mic được giải phóng khi app vào background.
- `startShortSession` hoạt động ổn định, tự động dừng sau timeout để tiết kiệm tài nguyên.

## Self-Check: PASSED

Next: Ready for 30-PLAN-3 (Floating Voice Overlay UI)
