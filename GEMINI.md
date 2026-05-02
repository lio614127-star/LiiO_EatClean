# LiiO EatClean — Project Guide

## Project Overview
iOS calorie tracking app built with Swift + SwiftUI. Helps users track meals, monitor calories, and get AI-powered meal suggestions with Vietnamese food focus.

## GSD Workflow
This project uses GSD (Get Shit Done) for planning and execution.

### Planning Files
- `.planning/PROJECT.md` — Project context and decisions
- `.planning/REQUIREMENTS.md` — v1 requirements with REQ-IDs
- `.planning/ROADMAP.md` — Phase structure and success criteria
- `.planning/STATE.md` — Current progress and memory
- `.planning/config.json` — Workflow configuration
- `.planning/research/` — Domain research findings

### Current Phase
Check `.planning/STATE.md` for current phase and progress.

### Commands
- `/gsd-progress` — Check project status
- `/gsd-discuss-phase N` — Gather context before planning
- `/gsd-plan-phase N` — Create detailed phase plan
- `/gsd-execute-phase N` — Execute phase plans

## Architecture
- **Pattern:** MVVM + Repository
- **UI:** SwiftUI (iOS 17+)
- **Data:** CoreData local-first
- **Food API:** CalorieNinjas + local Vietnamese JSON
- **AI:** OpenAI/Gemini with multi-key rotation

## Key Rules
1. Always use Repository protocols — never access CoreData directly from ViewModels
2. Use @Observable macro (not ObservableObject)
3. Map NSManagedObject to structs in Repository layer
4. Local-first food search, API as fallback
5. All dates stored in UTC, displayed via Calendar.current
6. Minimum calorie target: 1200 kcal
