//
//  CaseHistoryStore.swift
//  Unknown Detective
//
//  Simple persistence for case history via UserDefaults.
//

import Foundation
import SwiftUI
import Combine

struct CaseLog: Identifiable, Codable, Equatable {
    let id: UUID
    let caseId: UUID
    let type: CaseType
    let title: String
    let status: String
    let date: Date
    let turns: Int
}

@MainActor
final class CaseHistoryStore: ObservableObject {
    @Published private(set) var logs: [CaseLog] = []

    private let key = "caseHistory.logs"

    init() { load() }

    func add(from snapshot: CaseSnapshot) {
        // Only log when case is closed
        let statusText: String
        switch snapshot.status {
        case .solved: statusText = "Çözüldü"
        case .failed(let reason): statusText = reason.isEmpty ? "Çözülemedi" : "Çözülemedi: \(reason)"
        default: return
        }
        // Avoid duplicates for same caseId
        guard !logs.contains(where: { $0.caseId == snapshot.id }) else { return }
        let log = CaseLog(
            id: UUID(),
            caseId: snapshot.id,
            type: snapshot.type,
            title: snapshot.title,
            status: statusText,
            date: Date(),
            turns: snapshot.turns.count
        )
        logs.insert(log, at: 0)
        persist()
    }

    func remove(at offsets: IndexSet) {
        logs.remove(atOffsets: offsets)
        persist()
    }

    func removeAll() {
        logs.removeAll()
        persist()
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(logs)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            // ignore
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key) else { return }
        if let decoded = try? JSONDecoder().decode([CaseLog].self, from: data) {
            logs = decoded
        }
    }
}
