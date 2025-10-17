//
//  ActiveSessionStore.swift
//  Unknown Detective
//
//  Persists the active (unfinished) case session so the user can resume later.
//

import Foundation

struct ActiveSessionPayload: Codable {
    let snapshot: CaseSnapshot
    let hints: [CaseHint]
    let inputText: String
    // Reserved for future engine state bridging
    let engineStateVersion: Int? = nil
    let engineStateData: Data? = nil
}

enum ActiveSessionStore {
    private static let key = "ActiveSession.payload"

    static func save(snapshot: CaseSnapshot, hints: [CaseHint], inputText: String) {
        let payload = ActiveSessionPayload(snapshot: snapshot, hints: hints, inputText: inputText)
        if let data = try? JSONEncoder().encode(payload) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func load() -> ActiveSessionPayload? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(ActiveSessionPayload.self, from: data)
    }

    static func clear() { UserDefaults.standard.removeObject(forKey: key) }

    static var hasActive: Bool { UserDefaults.standard.data(forKey: key) != nil }
}
