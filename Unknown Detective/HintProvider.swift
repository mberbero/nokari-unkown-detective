//
//  HintProvider.swift
//  Unknown Detective
//
//  Created by GitHub Copilot on 17.10.2025.
//

import Foundation

enum HintProvider {
    static func makeHint(from snapshot: CaseSnapshot, existingHints: [CaseHint]) -> String {
        let stage = existingHints.count

        if stage == 0, let latestClue = snapshot.clues.last {
            return "Yeni bulunan \(latestClue.title) üstünde dur. Açıklaması: \(latestClue.detail)."
        }

        if stage == 1, let inconsistentSuspect = snapshot.suspects.first(where: { $0.trust == .skeptical || $0.trust == .hostile }) {
            return "\(inconsistentSuspect.name) ifadesindeki çelişkiyi sorgula. Alibisi: \(inconsistentSuspect.alibi)."
        }

        if stage == 2, let lastEngineTurn = snapshot.turns.last(where: { $0.speaker == .engine }) {
            return "Son raporu yeniden oku: \(lastEngineTurn.text). Buradaki bir ayrıntı ilerlemeni sağlayacak."
        }

        if stage == 3, let firstClue = snapshot.clues.first {
            return "Başlangıçtaki kanıta geri dön: \(firstClue.title). Bu bilgi olay örgüsünü birleştiriyor."
        }

        return "Tutarsız anlatımları yan yana koy. Aynı anda doğru olmayan iki ifade var; hangisi seni suçluya götürüyor?"
    }
}
