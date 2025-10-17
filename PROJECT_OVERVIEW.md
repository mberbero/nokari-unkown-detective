# Unknown Detective Project Overview

## Vision
- Narrative-driven detective simulator powered by an LLM that reacts to the players questions, choices, and accusations.
- Infinite replay value through procedural case blueprints, hidden truths, and adaptive dialogue.
- Mobile-first design with SwiftUI, honoring Apple platform guidelines while remaining portable across iOS, macOS, and visionOS.

## Core Gameplay Loop
1. Player spends energy to open a case file (homicide, missing person, heist).
2. CaseSessionView orchestrates a Q&A loop where the player interrogates LLM-generated suspects, reviews clues, and requests hints.
3. MockDetectiveEngine currently supplies scripted beats; this will be swapped for a live LLM back end that maintains hidden case canon and returns structured payloads.
4. Player declares the culprit; success resolves the case, failure branches to fail-forward pathways that still unlock new information.

## Architecture Highlights
- `CaseSnapshot`, `CaseTurn`, `Clue`, `SuspectProfile`, and `CaseHint` capture canonical state so the UI can replay or audit any conversation.
- `DetectiveEngine` protocol abstracts the story engine; `MockDetectiveEngine` mimics latency, beat progression, and clue/suspect updates for UI testing.
- `CaseSessionViewModel` (MainActor) handles async LLM calls, input throttling, and hint unlock bookkeeping.
- SwiftUI screens are modular: `CaseSelectionView`, `CaseSessionView`, `EnergyStoreView`, plus section components for clues, suspects, conversation, and hints.

## Economy & Monetization Systems
- `GameState` (ObservableObject) persists energy, max capacity, hint credits, and Detective Plus subscription status via `UserDefaults`.
- Daily allowances auto-refill based on calendar day; premium purchases can raise max energy or add hint credits beyond the daily quota.
- Energy store sheet simulates StoreKit receipts, rewarded ads for both energy and hints, and Detective Plus activation.
- Toolbar and list callouts surface current energy, offer quick store access, and label case costs.

## Hint & Progression Flow
- Hint banner encourages progression, showing remaining hint count and gating unlocks when the case is closed.
- `HintProvider` produces deterministic placeholder hints using recent clues, suspect trust levels, or last narrative beat.
- Hint paywall supports four unlock paths: daily allowance, hint credit, energy exchange, rewarded ad, or Detective Plus auto-unlock.

## Planned Extensions
- Replace `MockDetectiveEngine` with real-time LLM service (OpenAI/Anthropic) using structured JSON (narrative, new clues, suspicion shifts).
- Add moderation filters for both player prompts and model outputs.
- Integrate StoreKit 2 for consumables, non-consumables, and auto-renewable subscription; synchronize entitlements with a lightweight backend.
- Wire up rewarded ad mediation (AdMob, AppLovin) with server-side frequency caps and analytics.
- Expand case taxonomy, add fail-forward story branches, and expose analytics for hint usage and accusation accuracy.

## File Map (Key Additions)
- `Unknown Detective/DetectiveModels.swift`: domain models and `DetectiveEngine` protocol.
- `Unknown Detective/MockDetectiveEngine.swift`: scripted engine for prototyping.
- `Unknown Detective/CaseSessionViewModel.swift`: async state machine for case sessions.
- `Unknown Detective/CaseSessionView.swift`: primary investigator UI, including hint paywall.
- `Unknown Detective/GameState.swift`: persistent economy model.
- `Unknown Detective/EnergyStoreView.swift`: in-app economy UI stub.
- `Unknown Detective/HintProvider.swift`: deterministic hint generator.

## Reference Links
- Apple: StoreKit 2, SwiftData/Core Data for syncing case logs, BackgroundTasks for daily allowance refresh.
- LLM: guardrails (moderation, rate limiting), hidden-state blueprint prompts, caching conversation summaries.
- Ads: Rewarded ad best practices (serve on-demand, provide skip, reward within 24h coherence).

This document tracks the high-level intent and the scaffolding already coded, enabling future work on live LLM integration, monetization, and content scaling.
