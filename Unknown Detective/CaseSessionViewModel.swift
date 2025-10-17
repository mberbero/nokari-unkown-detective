//
//  CaseSessionViewModel.swift
//  Unknown Detective
//
//  Created by GitHub Copilot on 17.10.2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class CaseSessionViewModel: ObservableObject {
    @Published var snapshot: CaseSnapshot?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var inputText = ""
    @Published private(set) var hints: [CaseHint] = []

    let caseType: CaseType

    private let engine: any DetectiveEngine

    init(caseType: CaseType, engine: (any DetectiveEngine)? = nil, resumeSnapshot: CaseSnapshot? = nil, initialHints: [CaseHint] = [], initialInputText: String = "") {
        self.caseType = caseType
        self.engine = engine ?? MockDetectiveEngine()
        self.snapshot = resumeSnapshot
        self.hints = initialHints
        self.inputText = initialInputText

        // If we are resuming an existing session, align the engine's internal progress with the snapshot.
        if let resumeSnapshot {
            Task {
                await resyncEngineProgress(with: resumeSnapshot)
            }
        }
    }

    func start() {
        guard snapshot == nil else { return }
        isLoading = true
        Task {
            do {
                let snapshot = try await engine.startCase(of: caseType)
                withAnimation {
                    self.snapshot = snapshot
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func sendQuestion() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let snapshot else { return }
        inputText = ""
        isLoading = true
        Task {
            do {
                let next = try await engine.answer(question: trimmed, in: snapshot)
                withAnimation {
                    self.snapshot = next
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func unlockHint(for snapshot: CaseSnapshot, method: HintUnlockMethod) {
        let hintText = HintProvider.makeHint(from: snapshot, existingHints: hints)
        let hint = CaseHint(id: UUID(), text: hintText, createdAt: Date(), method: method)
        withAnimation {
            hints.append(hint)
        }
    }

    // MARK: - Resume support
    private func resyncEngineProgress(with snapshot: CaseSnapshot) async {
        // Do not resync closed cases
        switch snapshot.status {
        case .solved, .failed:
            return
        default:
            break
        }
        // Count engine turns already present in the snapshot.
        let engineTurns = snapshot.turns.filter { $0.speaker == .engine }.count
        guard engineTurns > 0 else { return }

        // Advance underlying engine state by issuing discarded answers so next real question picks the correct beat.
        for _ in 0..<engineTurns {
            _ = try? await engine.answer(question: "[sync]", in: snapshot)
        }
    }
}
