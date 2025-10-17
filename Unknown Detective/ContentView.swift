//
//  ContentView.swift
//  Unknown Detective
//
//  Created by Mansur Berbero on 17.10.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var gameState = GameState(initialMaxEnergy: 10, dailyEnergyAllowance: 3, dailyHintAllowance: 2)
    @State private var path: [CaseType] = []
    @State private var showEnergyAlert = false
    @State private var alertMessage = ""
    @State private var showStore = false

    var body: some View {
        NavigationStack(path: $path) {
            CaseSelectionView(gameState: gameState, startCase: { caseType in
                if gameState.consumeEnergy(for: caseType) {
                    path.append(caseType)
                } else {
                    alertMessage = "Bu vaka için yeterli enerjin yok. Enerji yenilenene kadar bekle veya mağazadan takviye al."
                    showEnergyAlert = true
                }
            }, openStore: {
                showStore = true
            })
            .navigationTitle("Unknown Detective")
            .navigationDestination(for: CaseType.self) { caseType in
                CaseSessionView(viewModel: CaseSessionViewModel(caseType: caseType))
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showStore = true
                    } label: {
                        Label("Mağaza", systemImage: "cart")
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
        .environmentObject(gameState)
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
