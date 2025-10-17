//
//  DetectiveModels.swift
//  Unknown Detective
//
//  Created by GitHub Copilot on 17.10.2025.
//

import Foundation

enum CaseType: String, CaseIterable, Identifiable, Codable {
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

    var energyCost: Int {
        switch self {
        case .homicide:
            return 2
        case .missingPerson:
            return 1
        case .heist:
            return 3
        }
    }
}

enum CaseStatus: Equatable, Codable {
    case briefing
    case investigation
    case solved
    case failed(reason: String)

    private enum CodingKeys: String, CodingKey { case name, reason }
    private enum Name: String, Codable { case briefing, investigation, solved, failed }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(Name.self, forKey: .name)
        switch name {
        case .briefing:
            self = .briefing
        case .investigation:
            self = .investigation
        case .solved:
            self = .solved
        case .failed:
            let reason = try container.decodeIfPresent(String.self, forKey: .reason) ?? ""
            self = .failed(reason: reason)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .briefing:
            try container.encode(Name.briefing, forKey: .name)
        case .investigation:
            try container.encode(Name.investigation, forKey: .name)
        case .solved:
            try container.encode(Name.solved, forKey: .name)
        case .failed(let reason):
            try container.encode(Name.failed, forKey: .name)
            try container.encode(reason, forKey: .reason)
        }
    }
}

enum HintUnlockMethod: String, Equatable, Codable {
    case dailyAllowance
    case hintCredit
    case energy
    case rewarded
    case subscription
}

struct Clue: Identifiable, Equatable, Codable {
    enum Category: String, Codable {
        case physicalEvidence = "Physical Evidence"
        case testimony = "Testimony"
        case document = "Document"
    }

    let id: UUID
    let title: String
    let detail: String
    let category: Category
}

struct SuspectProfile: Identifiable, Equatable, Codable {
    enum TrustLevel: String, Codable {
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

struct CaseTurn: Identifiable, Equatable, Codable {
    enum Speaker: String, Codable {
        case detective
        case engine
    }

    let id: UUID
    let speaker: Speaker
    let text: String
    let timestamp: Date
    let newClues: [Clue]
}

struct CaseSnapshot: Equatable, Codable {
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

struct CaseHint: Identifiable, Equatable, Codable {
    let id: UUID
    let text: String
    let createdAt: Date
    let method: HintUnlockMethod
}

protocol DetectiveEngine {
    func startCase(of type: CaseType) async throws -> CaseSnapshot
    func answer(question: String, in snapshot: CaseSnapshot) async throws -> CaseSnapshot
}
