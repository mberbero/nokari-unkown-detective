//
//  ContentView.swift
//  Unknown Detective
//
//  Created by Mansur Berbero on 17.10.2025.
//

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var gameState = GameState(initialMaxEnergy: 10, dailyEnergyAllowance: 3, dailyHintAllowance: 2)
    @StateObject private var historyStore = CaseHistoryStore()
    @State private var path: [CaseType] = []
    @State private var showEnergyAlert = false
    @State private var alertMessage = ""
    @State private var showStore = false
    @State private var showSettings = false
    @State private var showHistory = false
    @State private var resumeRequested = false

    var body: some View {
        NavigationStack(path: $path) {
            CaseSelectionView(
                gameState: gameState,
                startCase: { caseType in
                    resumeRequested = false
                    if gameState.consumeEnergy(for: caseType) {
                        Haptics.success()
                        AppPreferences.lastCaseType = caseType
                        path.append(caseType)
                    } else {
                        Haptics.warning()
                        alertMessage = "Bu vaka için yeterli enerjin yok. Enerji yenilenene kadar bekle veya mağazadan takviye al."
                        showEnergyAlert = true
                    }
                },
                openStore: {
                    Haptics.light(); showStore = true
                },
                resumeCase: { caseType in
                    // Do not consume energy on resume
                    resumeRequested = true
                    Haptics.light()
                    path.append(caseType)
                }
            )
            .navigationTitle("Unknown Detective")
            .navigationDestination(for: CaseType.self) { caseType in
                if resumeRequested, let payload = ActiveSessionStore.load(), payload.snapshot.type == caseType {
                    // Use zero-latency engine to instantly resync internal state on resume
                    CaseSessionView(viewModel: CaseSessionViewModel(
                        caseType: caseType,
                        engine: MockDetectiveEngine(latency: 0),
                        resumeSnapshot: payload.snapshot,
                        initialHints: payload.hints,
                        initialInputText: payload.inputText
                    ))
                } else {
                    CaseSessionView(viewModel: CaseSessionViewModel(caseType: caseType))
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        Haptics.light()
                        showSettings = true
                    } label: {
                        Label("Ayarlar", systemImage: "gearshape")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            Haptics.light()
                            showHistory = true
                        } label: {
                            Label("Geçmiş", systemImage: "book.closed")
                        }
                        Button {
                            showStore = true
                        } label: {
                            Label("Mağaza", systemImage: "cart")
                        }
                    }
                }
            }
        }
        .tint(NoirTheme.accent)
        .alert("Enerji Yetersiz", isPresented: $showEnergyAlert) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showStore) {
            EnergyStoreView(gameState: gameState)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(gameState: gameState)
        }
        .sheet(isPresented: $showHistory) {
            CaseHistoryView(onStartCase: { type in
                if gameState.consumeEnergy(for: type) {
                    Haptics.success()
                    AppPreferences.lastCaseType = type
                    resumeRequested = false
                    path.append(type)
                } else {
                    Haptics.warning()
                    alertMessage = "Bu vaka için yeterli enerjin yok. Enerji yenilenene kadar bekle veya mağazadan takviye al."
                    showEnergyAlert = true
                }
            })
            .environmentObject(historyStore)
        }
        .environmentObject(gameState)
        .environmentObject(historyStore)
        .background(
            LinearGradient(
                colors: [NoirTheme.backgroundTop, NoirTheme.backgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .preferredColorScheme(.dark)
    }
}

struct CaseSelectionView: View {
    @ObservedObject var gameState: GameState
    let startCase: (CaseType) -> Void
    let openStore: () -> Void
    let resumeCase: ((CaseType) -> Void)?

    @State private var now = Date()
    @State private var didClaimBonus = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                statusCard
                caseGrid
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { date in
            now = date
        }
    }

    private func icon(for caseType: CaseType) -> String {
        switch caseType {
        case .homicide:
            return "drop.triangle"
        case .missingPerson:
            return "person.fill.questionmark"
        case .heist:
            return "banknote"
        }
    }

    private var hasActiveSession: Bool { ActiveSessionStore.hasActive }
    private var activeSessionTitle: String { ActiveSessionStore.load()?.snapshot.title ?? "" }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Dedektif Durumu")
                    .font(.title3.bold())
                Spacer()
                Button(action: openStore) {
                    Label("Mağaza", systemImage: "cart.fill")
                        .labelStyle(.titleAndIcon)
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(NoirTheme.accent.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            energyBar
            hintBar
            Text("Yenilemeye kalan: \(formattedCountdown)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(NoirTheme.subtleText)

            if gameState.isDailyBonusAvailable(now: now) {
                Button {
                    if gameState.claimDailyBonus(now: now) {
                        didClaimBonus = true
                        Haptics.success()
                        if AppPreferences.notificationsEnabled {
                            NotificationsManager.shared.scheduleDailyReminder(at: gameState.nextRefillDate)
                        }
                    } else {
                        Haptics.warning()
                    }
                } label: {
                    Label("Günlük bonusu al (+1 enerji, +1 ipucu)", systemImage: "gift.fill")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(NoirTheme.accent)
                .clipShape(Capsule())
            } else {
                Text("Günlük bonus için kalan: \(dailyBonusCountdown)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(NoirTheme.subtleText)
            }

            if hasActiveSession, let type = ActiveSessionStore.load()?.snapshot.type {
                Button {
                    resumeCase?(type)
                } label: {
                    Label("Devam et: \(activeSessionTitle)", systemImage: "play.circle")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(NoirTheme.neon)
                .clipShape(Capsule())
            } else if let last = AppPreferences.lastCaseType {
                Button { startCase(last) } label: {
                    Label("Hızlı Başlat: \(last.rawValue)", systemImage: "forward.fill")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .tint(NoirTheme.neon)
                .clipShape(Capsule())
            }
        }
        .padding(20)
        .background(NoirTheme.cardBackground.opacity(0.9))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(NoirTheme.accent.opacity(0.4), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: NoirTheme.accent.opacity(0.15), radius: 12, x: 0, y: 8)
    }

    private var energyBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Enerji", systemImage: "bolt.fill")
                Spacer()
                Text("\(gameState.energy)/\(gameState.maxEnergy)")
                    .font(.headline.monospacedDigit())
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                    Capsule()
                        .fill(LinearGradient(colors: [NoirTheme.accent, NoirTheme.neon], startPoint: .leading, endPoint: .trailing))
                        .frame(width: proxy.size.width * CGFloat(max(0, min(1, Double(gameState.energy) / Double(max(gameState.maxEnergy, 1))))))
                }
            }
            .frame(height: 14)
        }
    }

    private var hintBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("İpucu Kredisi", systemImage: "lightbulb.fill")
                Spacer()
                Text(gameState.hasDetectivePlus ? "Sınırsız" : "\(gameState.hintCredits)")
                    .font(.headline)
                    .foregroundStyle(gameState.hasDetectivePlus ? NoirTheme.neon : Color.white)
            }
            if !gameState.hasDetectivePlus {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                        Capsule()
                            .fill(NoirTheme.caution)
                            .frame(width: proxy.size.width * CGFloat(max(0, min(1, Double(gameState.hintCredits) / Double(max(gameState.dailyHintAllowance, 1))))))
                    }
                }
                .frame(height: 10)
            }
        }
    }

    private var formattedCountdown: String {
        let remaining = Int(gameState.timeUntilNextRefill(now: now))
        let h = remaining / 3600
        let m = (remaining % 3600) / 60
        let s = remaining % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    private var dailyBonusCountdown: String {
        let remaining = Int(gameState.timeUntilDailyBonus(now: now))
        let h = remaining / 3600
        let m = (remaining % 3600) / 60
        let s = remaining % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    private var caseGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Yeni Vaka Seç")
                .font(.headline)
                .foregroundStyle(NoirTheme.subtleText)
            ForEach(CaseType.allCases) { caseType in
                Button {
                    startCase(caseType)
                } label: {
                    HStack(alignment: .top, spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(NoirTheme.accent.opacity(0.25))
                                .frame(width: 52, height: 52)
                            Image(systemName: icon(for: caseType))
                                .font(.title2)
                                .foregroundStyle(NoirTheme.accent)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(caseType.rawValue)
                                    .font(.headline)
                                Spacer()
                                Label("\(caseType.energyCost)", systemImage: "bolt.fill")
                                    .font(.caption.bold())
                                    .labelStyle(.titleAndIcon)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.08))
                                    .clipShape(Capsule())
                            }
                            Text(caseType.tagline)
                                .font(.subheadline)
                                .foregroundStyle(NoirTheme.subtleText)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(NoirTheme.cardBackground.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(gameState.energy < caseType.energyCost ? NoirTheme.caution.opacity(0.6) : NoirTheme.accent.opacity(0.3), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: NoirTheme.accent.opacity(0.12), radius: 10, x: 0, y: 6)
                    .overlay(alignment: .bottomTrailing) {
                        if gameState.energy < caseType.energyCost {
                            Text("Enerji yetersiz")
                                .font(.caption2)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(NoirTheme.caution.opacity(0.8))
                                .clipShape(Capsule())
                                .padding(12)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
