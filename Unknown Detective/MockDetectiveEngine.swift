//
//  MockDetectiveEngine.swift
//  Unknown Detective
//
//  Created by GitHub Copilot on 17.10.2025.
//

import Foundation

struct MockDetectiveEngine: DetectiveEngine {
    struct ScriptBeat {
        let response: String
        let newClues: [Clue]
        let suspectUpdates: [SuspectProfile]
        let status: CaseStatus?
    }

    struct Script {
        let title: String
        let synopsis: String
        let suspects: [SuspectProfile]
        let beats: [ScriptBeat]
    }

    private var scripts: [CaseType: Script] = {
        var scripts = [CaseType: Script]()

        let homicideSuspects = [
            SuspectProfile(
                id: UUID(),
                name: "Ali Demir",
                occupation: "Eski Savcı",
                motive: "Makduru tehdit eden davayı kaybetti",
                alibi: "Saat 21:00'de evde yalnızdı",
                trust: .skeptical
            ),
            SuspectProfile(
                id: UUID(),
                name: "Zeynep Korkmaz",
                occupation: "Gazeteci",
                motive: "Cinayet serisini haberleştirmek istiyordu",
                alibi: "Canlı yayında olduğu iddiası",
                trust: .cooperative
            )
        ]

        scripts[.homicide] = Script(
            title: "Otel Odasındaki Kan",
            synopsis: "Lüks bir otel odasında işlenen cinayet, siyasi bir komploya mı işaret ediyor?",
            suspects: homicideSuspects,
            beats: [
                ScriptBeat(
                    response: "Cinayet mahallinde bir not buldunuz. Üzerinde: 'Beni yalnız bırakma' yazıyor. Oda dağınık, pencere aralık ve yerde cam kırıkları var.",
                    newClues: [
                        Clue(
                            id: UUID(),
                            title: "El Yazısıyla Not",
                            detail: "Notta 'Beni yalnız bırakma' yazıyor. Mürekkep taze.",
                            category: .document
                        )
                    ],
                    suspectUpdates: homicideSuspects,
                    status: .investigation
                ),
                ScriptBeat(
                    response: "Parmak izi yok, ancak yazı tarzı Ali Demir'in eski mektubuyla eşleşiyor. Otel kamerası gece 22:13'te karartılmış.",
                    newClues: [
                        Clue(
                            id: UUID(),
                            title: "Kamera Kayıt Boşluğu",
                            detail: "22:13-22:27 arasında görüntü yok.",
                            category: .document
                        )
                    ],
                    suspectUpdates: homicideSuspects,
                    status: nil
                ),
                ScriptBeat(
                    response: "Ali Demir, 22:15'te otelde olduğunu kabul etti ancak makduru sağ bulduğunu söylüyor. Zeynep kırık camların Ali'nin kırdığı bardaktan geldiğini belirtiyor.",
                    newClues: [
                        Clue(
                            id: UUID(),
                            title: "Kırık Kristal Bardak",
                            detail: "Ali Demir'in koleksiyonundan bir bardak.",
                            category: .physicalEvidence
                        )
                    ],
                    suspectUpdates: homicideSuspects.map { suspect in
                        var copy = suspect
                        if copy.name == "Ali Demir" {
                            copy.trust = .hostile
                            copy.alibi = "22:15'te oteldeydi ama kısa sürede ayrıldı."
                        }
                        return copy
                    },
                    status: nil
                ),
                ScriptBeat(
                    response: "Kamera kayıtlarını kurtardınız. Ali'nin odadan çıktıktan sonra bilinmeyen biri içeri giriyor. Zeynep, bu kişinin bir otel çalışanı olduğunu iddia ediyor.",
                    newClues: [
                        Clue(
                            id: UUID(),
                            title: "Gizemli Siluet",
                            detail: "Kamera, yüzü görünmeyen biri odadan çıkarken yakaladı.",
                            category: .physicalEvidence
                        )
                    ],
                    suspectUpdates: homicideSuspects,
                    status: nil
                ),
                ScriptBeat(
                    response: "Siluetin otel güvenlik şefi olduğunu kanıtladınız. Şef, yerel bir politikacı adına delil sakladığını itiraf etti. Vaka çözüldü; arkasında siyasi bir şantaj zinciri var.",
                    newClues: [],
                    suspectUpdates: homicideSuspects,
                    status: .solved
                )
            ]
        )

        let missingSuspects = [
            SuspectProfile(
                id: UUID(),
                name: "Melis Akın",
                occupation: "Moda Tasarımcısı",
                motive: "Kaybolan gazeteciyle gizli ilişki",
                alibi: "Lansman gecesinde sahnede olduğu söyleniyor",
                trust: .skeptical
            )
        ]

        scripts[.missingPerson] = Script(
            title: "Kayıp Haber",
            synopsis: "Genç bir muhabir büyük haber peşindeyken kayboldu.",
            suspects: missingSuspects,
            beats: [
                ScriptBeat(
                    response: "Muhaabir Ayşe'nin masasında kilitli bir USB bellek ve bir seyahat bileti buldunuz. Bilette gece yarısı Ankara'ya gidiş görünüyor.",
                    newClues: [
                        Clue(
                            id: UUID(),
                            title: "USB Bellek",
                            detail: "Şifreli dosya içeriyor, 'Operasyon-F' etiketi var.",
                            category: .document
                        )
                    ],
                    suspectUpdates: missingSuspects,
                    status: .investigation
                ),
                ScriptBeat(
                    response: "USB'yi çözünce belediyedeki rüşvet ağına dair belgeler açığa çıktı. Ayşe'nin son mesajı 'Beni gerekirse terminalde bul' diyor.",
                    newClues: [
                        Clue(
                            id: UUID(),
                            title: "Son Mesaj",
                            detail: "Terminalde buluşma talebi.",
                            category: .document
                        )
                    ],
                    suspectUpdates: missingSuspects,
                    status: nil
                ),
                ScriptBeat(
                    response: "Terminalde Melis Akın'ı yakaladınız. Ayşe ile buluşacağını ama gelmediğini söylüyor. Kameralarda Ayşe'nin bir minibüse bindirildiği görülüyor.",
                    newClues: [
                        Clue(
                            id: UUID(),
                            title: "Terminal Kamerası",
                            detail: "Ayşe zorla minibüse bindiriliyor.",
                            category: .physicalEvidence
                        )
                    ],
                    suspectUpdates: missingSuspects,
                    status: nil
                ),
                ScriptBeat(
                    response: "Minibüsün belediye garajına ait olduğu ortaya çıktı. İçeride Ayşe'yi ve belgeleri güvenli şekilde buldunuz. Rüşvet ağı ifşa edildi.",
                    newClues: [],
                    suspectUpdates: missingSuspects,
                    status: .solved
                )
            ]
        )

        let heistSuspects = [
            SuspectProfile(
                id: UUID(),
                name: "Baran Güneş",
                occupation: "Eski kasa tasarımcısı",
                motive: "İflas eden şirketinden intikam",
                alibi: "O gece yurtdışında olduğu iddiası",
                trust: .skeptical
            )
        ]

        scripts[.heist] = Script(
            title: "Gölge Kasası",
            synopsis: "Üç katmanlı güvenlik sistemi kırıldı. İçeriden destek mi var?",
            suspects: heistSuspects,
            beats: [
                ScriptBeat(
                    response: "Kasada hiçbir zorlama izi yok. Alarm devre dışı, sadece açılış kodu kullanılmış. Duvara spreylenmiş 'Gölgeler borcunu ödetir' yazısı var.",
                    newClues: [
                        Clue(
                            id: UUID(),
                            title: "Grafiti Mesajı",
                            detail: "Gölgeler borcunu ödetir yazısı",
                            category: .document
                        )
                    ],
                    suspectUpdates: heistSuspects,
                    status: .investigation
                ),
                ScriptBeat(
                    response: "Baran'ın eski öğrencilerinden biri, kasanın açılış protokolünü forumda sızdırmış. Güvenlik görevlisi Nurten, Baran'ın akşam kasayla ilgilendiğini söylüyor.",
                    newClues: [],
                    suspectUpdates: heistSuspects,
                    status: nil
                ),
                ScriptBeat(
                    response: "Nurten, Baran'a ait ikinci bir anahtar gördüğünü itiraf ediyor. Güvenlik yedeğini değiştirmemişler. Müdür yardımcısı kodları maille gönderiyormuş.",
                    newClues: [
                        Clue(
                            id: UUID(),
                            title: "Mail Zinciri",
                            detail: "Kodlar düz metin maille gönderilmiş.",
                            category: .document
                        )
                    ],
                    suspectUpdates: heistSuspects,
                    status: nil
                ),
                ScriptBeat(
                    response: "Baran, çalıntı mücevherleri multi-sig kasaya aktarmış. Ortakları güvenlik müdürü ve finans direktörü. Üçünü de tutukladınız.",
                    newClues: [],
                    suspectUpdates: heistSuspects,
                    status: .solved
                )
            ]
        )

        return scripts
    }()

    private actor StateStore {
        private var beatIndexByCase: [UUID: Int] = [:]

        func beatIndex(for caseId: UUID) -> Int {
            beatIndexByCase[caseId, default: 0]
        }

        func advance(caseId: UUID) {
            let index = beatIndexByCase[caseId, default: 0]
            beatIndexByCase[caseId] = index + 1
        }
    }

    private let latency: UInt64
    private let state = StateStore()

    init(latency: UInt64 = 400_000_000) {
        self.latency = latency
    }

    func startCase(of type: CaseType) async throws -> CaseSnapshot {
        guard let script = scripts[type] else {
            throw NSError(domain: "MockDetectiveEngine", code: 404, userInfo: [NSLocalizedDescriptionKey: "No script found"])
        }

        try await Task.sleep(nanoseconds: latency)

        let caseId = UUID()
        let firstBeat = script.beats.first
        let initialTurn = CaseTurn(
            id: UUID(),
            speaker: .engine,
            text: firstBeat?.response ?? "",
            timestamp: Date(),
            newClues: firstBeat?.newClues ?? []
        )

    await state.advance(caseId: caseId)

        return CaseSnapshot(
            id: caseId,
            type: type,
            title: script.title,
            synopsis: script.synopsis,
            status: firstBeat?.status ?? .briefing,
            turns: [initialTurn],
            clues: firstBeat?.newClues ?? [],
            suspects: script.suspects
        )
    }

    func answer(question: String, in snapshot: CaseSnapshot) async throws -> CaseSnapshot {
        guard let script = scripts[snapshot.type] else {
            throw NSError(domain: "MockDetectiveEngine", code: 404, userInfo: [NSLocalizedDescriptionKey: "No script found"])
        }

        try await Task.sleep(nanoseconds: latency)

        let questionTurn = CaseTurn(
            id: UUID(),
            speaker: .detective,
            text: question,
            timestamp: Date(),
            newClues: []
        )

        var nextSnapshot = snapshot.appending(turn: questionTurn)

        let currentBeatIndex = await state.beatIndex(for: snapshot.id)
        if currentBeatIndex >= script.beats.count {
            let wrapTurn = CaseTurn(
                id: UUID(),
                speaker: .engine,
                text: "Vaka zaten sonuçlandı. Yeni vaka açmayı deneyin.",
                timestamp: Date(),
                newClues: []
            )
            return nextSnapshot.appending(turn: wrapTurn)
        }

        let beat = script.beats[currentBeatIndex]

        let responseTurn = CaseTurn(
            id: UUID(),
            speaker: .engine,
            text: beat.response,
            timestamp: Date(),
            newClues: beat.newClues
        )

    await state.advance(caseId: snapshot.id)

        var updatedSuspects = nextSnapshot.suspects
        if !beat.suspectUpdates.isEmpty {
            updatedSuspects = beat.suspectUpdates
        }

        let appendedClues = beat.newClues.filter { !nextSnapshot.clues.contains($0) }

        return nextSnapshot.appending(
            turn: responseTurn,
            status: beat.status ?? nextSnapshot.status,
            updatedSuspects: updatedSuspects,
            appendedClues: appendedClues
        )
    }
}
