//
//  EnergyStoreView.swift
//  Unknown Detective
//
//  Created by GitHub Copilot on 17.10.2025.
//

import SwiftUI

struct EnergyStoreView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.dismiss) private var dismiss

    @State private var isRewarding = false
    @State private var showReceiptAlert = false
    @State private var alertMessage = ""

    private let packs = EnergyPack.samplePacks

    var body: some View {
        NavigationStack {
            List {
                statusSection
                rewardedSection
                packsSection
                subscriptionSection
            }
            .navigationTitle("Enerji Mağazası")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
            .alert(isPresented: $showReceiptAlert) {
                Alert(title: Text("Bilgi"), message: Text(alertMessage), dismissButton: .default(Text("Tamam")))
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var statusSection: some View {
        Section("Durum") {
            HStack {
                Label("Mevcut Enerji", systemImage: "bolt.fill")
                Spacer()
                Text("\(gameState.energy)/\(gameState.maxEnergy)")
                    .font(.headline.monospacedDigit())
            }
            .foregroundStyle(Color.accentColor)
            HStack {
                Label("İpucu Kredisi", systemImage: "lightbulb.fill")
                Spacer()
                Text(gameState.hasDetectivePlus ? "Sınırsız" : "\(gameState.hintCredits)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(gameState.hasDetectivePlus ? Color.green : Color.accentColor)
            }
            if gameState.energy >= gameState.maxEnergy {
                Text("Enerjin zaten maksimum.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var rewardedSection: some View {
        Section("Ödüllü Reklam") {
            Button {
                triggerRewardedEnergy()
            } label: {
                HStack {
                    Image(systemName: "play.rectangle.fill")
                        .foregroundStyle(.yellow)
                    Text("Reklam izle ve +1 enerji kazan")
                    Spacer()
                    if isRewarding {
                        ProgressView()
                    }
                }
            }
            .disabled(isRewarding)
            Button {
                triggerRewardedHint()
            } label: {
                HStack {
                    Image(systemName: "lightbulb")
                        .foregroundStyle(.orange)
                    Text("Reklam izle ve +1 ipucu kredisi kazan")
                    Spacer()
                    if isRewarding {
                        ProgressView()
                    }
                }
            }
            .disabled(isRewarding || gameState.hasDetectivePlus)
            Text("Reklamlar 24 saatte en fazla 3 kez izlenebilir. Simülasyon amaçlı süre 3 saniye.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var packsSection: some View {
        Section("Enerji Paketleri") {
            ForEach(packs) { pack in
                Button {
                    purchase(pack: pack)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(pack.title)
                                .font(.subheadline.weight(.semibold))
                            Text(pack.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(pack.price)
                                .font(.subheadline.weight(.bold))
                            HStack(spacing: 4) {
                                Image(systemName: "bolt")
                                Text("+\(pack.energy)")
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .disabled(gameState.energy >= gameState.maxEnergy)
            }
            Text("Satın alımlar StoreKit 2 ile doğrulanacak. Bu makette sadece yerel enerji artırımı yapılır.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var subscriptionSection: some View {
        Section("Detective Plus") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Sınırsız vaka, sınırsız enerji")
                    .font(.subheadline.weight(.semibold))
                Text("49₺/ay veya 499₺/yıl. Premium vakalara erişim ve sınırsız ipucu." )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button {
                    alertMessage = "Detective Plus için abonelik akışı henüz bağlı değil. StoreKit 2 entegrasyonu sonrası etkinleşecek."
                    showReceiptAlert = true
                } label: {
                    Label("Aboneliği başlat", systemImage: "infinity")
                        .font(.body.weight(.semibold))
                }
            }
            .padding(.vertical, 6)
        }
    }

    private func triggerRewardedEnergy() {
        guard !isRewarding else { return }
        isRewarding = true
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            await MainActor.run {
                gameState.addEnergy(1)
                alertMessage = "Reklam ödülü eklendi: +1 enerji."
                showReceiptAlert = true
                isRewarding = false
            }
        }
    }

    private func triggerRewardedHint() {
        guard !isRewarding else { return }
        isRewarding = true
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            await MainActor.run {
                gameState.addHintCredits(1)
                alertMessage = "Reklam ödülü eklendi: +1 ipucu kredisi."
                showReceiptAlert = true
                isRewarding = false
            }
        }
    }

    private func purchase(pack: EnergyPack) {
        guard gameState.energy < gameState.maxEnergy else {
            alertMessage = "Enerji maksimum, satın alma gerekmiyor."
            showReceiptAlert = true
            return
        }
        gameState.addEnergy(pack.energy, allowOverflow: true)
        alertMessage = "\(pack.title) satın alındı: +\(pack.energy) enerji."
        showReceiptAlert = true
    }
}

private struct EnergyPack: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let price: String
    let energy: Int

    static let samplePacks: [EnergyPack] = [
        EnergyPack(id: "pack.small", title: "Günlük Takviye", subtitle: "3 ek vaka hakkı", price: "₺19", energy: 3),
        EnergyPack(id: "pack.medium", title: "Araştırmacı Paketi", subtitle: "5 ek vaka hakkı", price: "₺39", energy: 5),
        EnergyPack(id: "pack.large", title: "Operasyon Paketi", subtitle: "10 ek vaka hakkı", price: "₺89", energy: 10)
    ]
}

#Preview {
    EnergyStoreView(gameState: GameState(initialMaxEnergy: 12, dailyEnergyAllowance: 3, dailyHintAllowance: 2, defaults: UserDefaults(suiteName: "preview") ?? .standard))
}
