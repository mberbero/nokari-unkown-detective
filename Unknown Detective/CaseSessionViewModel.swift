//
//  CaseSessionViewModel.swift
//  Unknown Detective
//
//  Created by GitHub Copilot on 17.10.2025.
//

import Foundation
import SwiftUI

@MainActor
final class CaseSessionViewModel: ObservableObject {
    @Published var snapshot: CaseSnapshot?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var inputText = ""

    let caseType: CaseType

    private let engine: DetectiveEngine

    init(caseType: CaseType, engine: DetectiveEngine = MockDetectiveEngine()) {
        self.caseType = caseType
        self.engine = engine
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
}
