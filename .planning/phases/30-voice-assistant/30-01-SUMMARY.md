---
phase: 30
plan: 1
subsystem: Voice Foundation
tags: [foundation, models, services]
requires: []
provides: [VoiceAssistantState, AssistantVoiceSettings, WakePhraseDetector, TextToSpeechService]
affects: [Settings, AI Pipeline]
tech-stack:
  added: [AVSpeechSynthesizer]
  patterns: [State Machine, AppStorage Persistence, Diacritic Insensitive Folding]
key-files:
  created:
    - LiiO_EatClean/Data/Models/VoiceAssistantState.swift
    - LiiO_EatClean/Data/Models/AssistantVoiceSettings.swift
    - LiiO_EatClean/Services/WakePhraseDetector.swift
    - LiiO_EatClean/Services/TextToSpeechService.swift
key-decisions:
  - "Sử dụng 9 trạng thái cho Voice Assistant State Machine để bao phủ toàn bộ vòng đời từ nhận diện tiếng động đến phản hồi."
  - "Tích hợp AppStorage trực tiếp vào AssistantVoiceSettings để đảm bảo persistence nhẹ nhàng mà không cần CoreData."
  - "WakePhraseDetector sử dụng diacriticInsensitive folding để nhận diện tên tiếng Việt không dấu (ví dụ: LiiO ơi -> lio oi)."
  - "TextToSpeechService sử dụng giọng vi-VN với tốc độ 0.52 để đạt độ tự nhiên cao nhất."
requirements-completed: [VOICE-01, VOICE-02, VOICE-03]
duration: 25 min
completed: 2026-05-13T14:50:00Z
---

# Phase 30 Plan 1: Voice Foundation — Data Models & Core Services Summary

## Goal
Thiết lập nền tảng dữ liệu và các dịch vụ cơ bản cho Voice Assistant, chuẩn bị cho việc tích hợp Global Manager và UI Overlay.

## Completed Tasks
- [x] Tạo `VoiceAssistantState` enum với 9 trạng thái điều khiển.
- [x] Triển khai `AssistantVoiceSettings` với hỗ trợ persistence qua `@AppStorage` và logic lựa chọn phản hồi.
- [x] Xây dựng `WakePhraseDetector` hỗ trợ chuẩn hóa tiếng Việt không dấu và fuzzy matching cho tên trợ lý.
- [x] Phát triển `TextToSpeechService` tích hợp `AVSpeechSynthesizer` giọng tiếng Việt.

## Verification Results
- Toàn bộ 4 file source code đã được tạo thành công trong các thư mục tương ứng.
- Logic chuẩn hóa chuỗi của `WakePhraseDetector` đã được kiểm tra (LiiO ơi -> lio oi).
- Cấu trúc `VoiceAssistantState` khớp hoàn toàn với thiết kế State Machine trong CONTEXT.md.

## Self-Check: PASSED

Next: Ready for 30-PLAN-2 (GlobalVoiceAssistantManager — State Machine & Audio Gate)
