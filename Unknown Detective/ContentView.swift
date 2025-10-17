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
        .alert("Enerji Yetersiz", isPresented: $showEnergyAlert) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showStore) {
            EnergyStoreView(gameState: gameState)
        }
        .environmentObject(gameState)
    }
}

struct CaseSelectionView: View {
    @ObservedObject var gameState: GameState
    let startCase: (CaseType) -> Void
    let openStore: () -> Void

    var body: some View {
        List {
            Section("Durum") {
                HStack {
                    Label("Enerji", systemImage: "bolt.fill")
                    Spacer()
                    Text("\(gameState.energy)/\(gameState.maxEnergy)")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(Color.accentColor)
                }
                Button {
                    openStore()
                } label: {
                    Label("Enerji mağazasını aç", systemImage: "cart.badge.plus")
                }
            }
            Section("Yeni Vaka") {
                ForEach(CaseType.allCases) { caseType in
                    Button {
                        startCase(caseType)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: icon(for: caseType))
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(caseType.rawValue)
                                    .font(.headline)
                                Text(caseType.tagline)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: "bolt")
                                    Text("\(caseType.energyCost)")
                                }
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                if gameState.energy < caseType.energyCost {
                                    Text("Enerji yetersiz")
                                        .font(.caption2)
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
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
}

#Preview {
    ContentView()
}
