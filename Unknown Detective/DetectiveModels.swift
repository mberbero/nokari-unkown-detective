//
//  DetectiveModels.swift
//  Unknown Detective
//
//  Created by GitHub Copilot on 17.10.2025.
//

import Foundation

enum CaseType: String, CaseIterable, Identifiable {
    case homicide = "Homicide"
    case missingPerson = "Missing Person"
    case heist = "High-Profile Heist"

    var id: String { rawValue }

    var tagline: String {
        switch self {
        case .homicide:
            return "Bir otel odasında işlenen cinayet."
        case .missingPerson:
            return "Ortadan kaybolan genç gazeteci."
        case .heist:
            return "Şehrin en güvenli kasasından çalınan mücevher."
        }
    }
}

enum CaseStatus: Equatable {
    case briefing
    case investigation
    case solved
    case failed(reason: String)
}

struct Clue: Identifiable, Equatable {
    enum Category: String {
        case physicalEvidence = "Physical Evidence"
        case testimony = "Testimony"
        case document = "Document"
    }

    let id: UUID
    let title: String
    let detail: String
    let category: Category
}

struct SuspectProfile: Identifiable, Equatable {
    enum TrustLevel: String {
        case unknown = "Unknown"
        case skeptical = "Skeptical"
        case cooperative = "Cooperative"
        case hostile = "Hostile"
    }

    let id: UUID
    var name: String
    var occupation: String
    var motive: String
    var alibi: String
    var trust: TrustLevel
}

struct CaseTurn: Identifiable, Equatable {
    enum Speaker {
        case detective
        case engine
    }

    let id: UUID
    let speaker: Speaker
    let text: String
    let timestamp: Date
    let newClues: [Clue]
}

struct CaseSnapshot: Equatable {
    let id: UUID
    let type: CaseType
    var title: String
    var synopsis: String
    var status: CaseStatus
    var turns: [CaseTurn]
    var clues: [Clue]
    var suspects: [SuspectProfile]

    func appending(turn: CaseTurn, status: CaseStatus? = nil, updatedSuspects: [SuspectProfile]? = nil, appendedClues: [Clue] = []) -> CaseSnapshot {
        var next = self
        next.turns.append(turn)
        if !appendedClues.isEmpty {
            next.clues.append(contentsOf: appendedClues)
        }
        if let status {
            next.status = status
        }
        if let updatedSuspects {
            next.suspects = updatedSuspects
        }
        return next
    }
}

protocol DetectiveEngine {
    func startCase(of type: CaseType) async throws -> CaseSnapshot
    func answer(question: String, in snapshot: CaseSnapshot) async throws -> CaseSnapshot
}
